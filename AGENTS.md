# AGENTS.md — KanbanApp project notes

Native macOS Kanban app for managing university coursework. SwiftUI + SwiftData, min macOS 14. Full architecture spec is in `KanbanApp_Architecture.md` — read that for the "why" behind the data model.

---

## Build workflow

The Xcode project is **generated from `project.yml`** via [xcodegen](https://github.com/yonaskolb/XcodeGen). `KanbanApp.xcodeproj/` is gitignored — `project.yml` is the source of truth.

```bash
# After adding, removing, or renaming any .swift file:
xcodegen generate

# Build:
xcodebuild -project KanbanApp.xcodeproj -scheme KanbanApp \
  -configuration Debug -destination 'platform=macOS' build

# Quick smoke test the built binary (won't show UI, just confirms no startup crash):
APP=$(find ~/Library/Developer/Xcode/DerivedData -name "KanbanApp.app" -path "*/Debug/*" -not -path "*Index.noindex*" -print -quit)
"$APP/Contents/MacOS/KanbanApp" & sleep 3 && kill %1
```

xcodegen globs over `KanbanApp/`, so any new `.swift` file under that tree is auto-picked-up on the next `generate`.

---

## Project-specific decisions (don't re-litigate)

- **Model is `KanbanTask`, not `Task`.** The architecture spec says `Task` but that collides with Swift Concurrency's `Task`. The rename is intentional.
- **Drag-and-drop AND the "Move to" context menu both ship.** Cards are `.draggable(TaskDragPayload(id: PersistentIdentifier))`; columns are `.dropDestination(for: TaskDragPayload.self)` and show a 2pt accent border while targeted (`KanbanColumnView.isTargeted`). The context-menu "Move to" submenu is still there for keyboard / no-mouse flow — keep both. `BoardColumns.handleDrop` resolves payloads to tasks via `persistentModelID` and only fires `onMove` when the status actually changes.
- **`KanbanTask.deadlineHasTime: Bool` separates date from time.** When false, `TaskCardView.deadlineColor` treats the deadline as expiring at 23:59:59 of that day, so a task due "today" doesn't go red at midnight. `TaskFormView` uses the "Set time…" / "Remove" pattern — same as `Module.examDate`. The model default is `true` (so any task constructed outside the form keeps hour-and-minute semantics); the form's `@State hasTime` defaults to `false` (most academic deadlines are date-only). Don't "fix" that asymmetry.
- **No `Settings { }` scene.** Semester/module CRUD lives in its own **"Modules" tab** (`ManageView`), not behind ⌘,. The architecture spec used a Settings scene; we moved it because there was nothing else to put there and a tab is more discoverable. Don't reintroduce a Settings scene without a reason.
- **`BoardSelection` enum drives the board.** The Kanban sidebar selects either `.semester(Semester)` (combined board for all that semester's modules) or `.module(Module)` (single-module board). Each semester section in the sidebar starts with an "All Modules" row. The board's "Add Task" button is disabled when `selected?.defaultModule == nil` — that single check covers both unselected and empty-semester cases.
- **Optional exam date uses an explicit "Set date…" / "Remove" pattern**, not a "Has exam" toggle. `Module.examDate: Date?` was already optional; the original toggle UI hid this and forced users to commit to a default time. See `ModuleFormView.examDateField`.
- **`Module.nextColor` fallback was fixed.** The spec (lines 67–72) has `usedColors.filter { $0 == $0 }` which is a tautology — the implementation uses per-color counting via `palette.min(by:)`. Don't restore the spec version.
- **Cascade deletes** are configured via `@Relationship(deleteRule: .cascade, inverse: \...)` on `Semester.modules` and `Module.tasks`. Set the relationship on **one side only** when creating; SwiftData maintains the inverse. Don't double-append (e.g. `semester.modules.append(m)` after `Module(... semester: s)` would duplicate).
- **Editing a Done task does not reset its `completedAt`.** `TaskFormView.save()` only calls `updateStatus` when the status actually changed. Don't restructure that into an unconditional call — it would restart the 14-day cleanup window on every edit.

---

## SwiftData / `#Predicate` gotchas

- Inside `#Predicate`, **member access without explicit base fails**. Use `Date.distantFuture`, not `.distantFuture`. See `KanbanTask.deleteExpired` for the working pattern (predicate captures a `let sentinel = Date.distantFuture`).
- `@Model` classes are `Equatable` **by persistent identity**, not field equality. `.onChange(of: someQueryArray)` only fires when the *set of identities* changes — not when properties on existing instances change. For "did the selected module/semester get deleted?" use separate `@Query`s and compare on identity (see `SemesterSidebarView.cleanupSelection`).
- **`Array.reversed()` returns `ReversedCollection`**, not `[Element]`. If a function declares `-> [Module]`, wrap with `Array(...)`. See `ExamsTab.partition`.

---

## File layout

```
KanbanApp/
├── Models/         Semester, Module, KanbanTask
├── Extensions/     Color+Hex
├── Views/
│   ├── ModuleSwatch.swift     shared color circle (5 call sites)
│   ├── Board/                 KanbanBoardView (incl. BoardSelection enum), KanbanColumnView, TaskCardView, TaskDragPayload
│   ├── Sidebar/               SemesterSidebarView (used by Board tab)
│   ├── Calendar/              CalendarTab
│   ├── Exams/                 ExamsTab
│   ├── Task/                  TaskFormView (sheet, create + edit)
│   └── Manage/                ManageView, SemesterFormView, ModuleFormView (the "Modules" tab)
├── AppIcon.icon/              Liquid Glass icon bundle (Assets/AppIcon.png + icon.json)
├── KanbanApp.swift            @main, ModelContainer
└── ContentView.swift          4-tab TabView (Board / Modules / Calendar / Exams), .task launch hook
```

---

## Workflow when adding code

1. Write or edit `.swift` files under `KanbanApp/`
2. Run `xcodegen generate` if files were added or removed
3. Run `xcodebuild ... build` to verify it compiles
4. **For UI changes:** launch the built `.app` and click through — a clean build does not mean the UI works

---

## App icon

- Icon ships as **`KanbanApp/AppIcon.icon`** — Apple's Liquid Glass bundle format (Xcode 26+). Internally it's a folder containing `icon.json` and `Assets/AppIcon.png` (1024×1024, no alpha). The legacy `Assets.xcassets/AppIcon.appiconset` was deleted: on macOS Tahoe (26+), legacy appiconsets get force-tiled inside a beige squircle ("icon jail"); the `.icon` format opts out and lets the artwork fill the squircle edge-to-edge. xcodegen recognizes `.icon` as `wrapper.icon` (single resource) — no project.yml change needed.
- `icon.json` uses a single full-bleed layer with `glass: false` and `supported-platforms.squares: ["macOS"]`. To swap the master image: replace `Assets/AppIcon.png` (must be 1024×1024 RGB, no alpha — flatten with Pillow if the source has transparency) and rebuild. Refresh the Dock with `killall Dock` if the cached icon lingers.

---

## Outstanding

- No tests yet. xcodegen project has testing disabled — re-enable in `project.yml` if/when tests are added.
