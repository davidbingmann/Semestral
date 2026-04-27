# UniKanban — Architecture Document

## Overview

A native macOS Kanban board app built with **SwiftUI** for university module management.
Persists all data locally using **SwiftData** (SQLite on disk, no cloud, no account required).

---

## Tech Stack

| Concern | Choice | Reason |
|---|---|---|
| UI Framework | SwiftUI | Native macOS look and feel |
| Persistence | SwiftData | Modern, annotation-based, replaces CoreData |
| Architecture | MVVM-lite | `@Query` removes the need for manual ViewModels |
| Storage format | SQLite (via SwiftData) | Automatic, local, zero config |
| Min. macOS version | macOS 14 Sonoma | Required for SwiftData + `.tabViewStyle(.sidebarAdaptable)` |

---

## Data Models

### `Semester`

```swift
@Model class Semester {
    var name: String           // e.g. "WiSe 2025/26"
    var startDate: Date
    var endDate: Date
    @Relationship var modules: [Module] = []
}
```

### `Module`

```swift
@Model class Module {
    var name: String           // e.g. "Programmierung I"
    var colorHex: String       // auto-assigned from palette, user-overridable
    var examDate: Date?        // includes time, set in SettingsView
    var semester: Semester?
    @Relationship var tasks: [Task] = []

    static let palette: [String] = [
        "#4F86C6", // blue
        "#5BAD72", // green
        "#D4736A", // coral
        "#A67DC5", // purple
        "#E09B3D", // amber
        "#5BBCB8", // teal
        "#D46A9B", // pink
        "#8D9EAD"  // slate
    ]
}
```

**Auto color logic** — picks the first unused palette color within the semester.
Falls back to the least-used color if all 8 are taken.

```swift
extension Module {
    static func nextColor(for semester: Semester, in context: ModelContext) -> String {
        let usedColors = semester.modules.map(\.colorHex)
        if let fresh = palette.first(where: { !usedColors.contains($0) }) {
            return fresh
        }
        return palette.min(by: {
            usedColors.filter { $0 == $0 }.count <
            usedColors.filter { $1 == $1 }.count
        }) ?? palette[0]
    }
}
```

### `Task`

```swift
enum KanbanStatus: String, Codable {
    case todo, inProgress, done
}

@Model class Task {
    var title: String
    var notes: String
    var deadline: Date?        // includes time
    var module: Module?

    var status: KanbanStatus {
        didSet {
            completedAt = (status == .done) ? .now : nil
        }
    }
    var completedAt: Date?     // stamped automatically when moved to Done
}
```

**Auto-delete logic** — called on every app launch, removes tasks done for 14+ days.

```swift
extension Task {
    static func deleteExpired(in context: ModelContext) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: .now)!
        let predicate = #Predicate<Task> { task in
            task.completedAt != nil && task.completedAt! < cutoff
        }
        try? context.delete(model: Task.self, where: predicate)
        try? context.save()
    }
}
```

---

## Navigation Structure

Top-level `TabView` with three tabs. The sidebar lives inside the Board tab only.

```
TabView
├── Board tab          (NavigationSplitView)
│   ├── SemesterSidebarView   — semester + module selection
│   └── KanbanBoardView       — 3-column board filtered by selected module
│       ├── KanbanColumnView  — To Do / In Progress / Done
│       │   └── TaskCardView  — title, module badge, relative deadline
│       └── TaskFormView      — .sheet() for create + edit
├── Calendar tab
│   └── CalendarTab           — month grid, deadline dots coloured by module
└── Exams tab
    └── ExamsTab              — sorted list of module exam dates
```

---

## View Responsibilities

### `KanbanApp.swift`
- `@main` entry point
- Creates and injects the `ModelContainer` for `Semester`, `Module`, `Task`
- Calls `Task.deleteExpired()` once on launch via `.task {}`

### `ContentView`
- Hosts the `TabView`
- Fires the expired task cleanup on appear

### `SemesterSidebarView`
- Lists all semesters with their modules
- Drives a `@State var selectedModule: Module?` that is passed to `KanbanBoardView`

### `KanbanBoardView`
- Renders three `KanbanColumnView` instances in an `HStack`
- Filters tasks by `selectedModule` and by column `status`
- Hosts the "Add Task" toolbar button that opens `TaskFormView`

### `KanbanColumnView`
- Displays a header label and a scrollable list of `TaskCardView`
- Accepts drop targets for drag-and-drop (future enhancement)

### `TaskCardView`
- Shows task title, coloured module badge, and deadline as a relative string (e.g. "in 3 days")
- Tapping opens `TaskFormView` in edit mode

### `TaskFormView` (`.sheet()`)
- `TextField` for title
- `TextEditor` for notes
- `Picker` for module (filtered to current semester)
- `DatePicker` for deadline with `.date` and `.hourAndMinute` components
- Create and edit share the same form; mode is determined by whether a `Task` is passed in

### `CalendarTab`
- Month grid built with `LazyVGrid` (7 columns)
- Each `DayCell` shows the day number and up to 3 coloured dots for tasks with a deadline that day
- Month navigation with chevron buttons
- Today's date highlighted with the accent colour

### `ExamsTab`
- `@Query(sort: \Module.examDate)` fetches all modules with an exam date
- Splits into **Upcoming** and **Past** sections
- Each `ExamRow` shows the module colour swatch, name, full formatted date, and a relative time label ("in 3 days")

### `SettingsView`
- Create, edit, and delete semesters
- Per-semester: create, edit, and delete modules
- Module form includes name field, colour picker (pre-filled via auto-assign), and exam date picker with time

---

## File Structure

```
UniKanban/
├── UniKanbanApp.swift
├── Models/
│   ├── Semester.swift
│   ├── Module.swift           ← includes palette + nextColor()
│   └── Task.swift             ← includes KanbanStatus + deleteExpired()
├── Views/
│   ├── ContentView.swift
│   ├── Board/
│   │   ├── KanbanBoardView.swift
│   │   ├── KanbanColumnView.swift
│   │   └── TaskCardView.swift
│   ├── Task/
│   │   └── TaskFormView.swift
│   ├── Calendar/
│   │   └── CalendarTab.swift
│   ├── Exams/
│   │   └── ExamsTab.swift
│   ├── Sidebar/
│   │   └── SemesterSidebarView.swift
│   └── Settings/
│       └── SettingsView.swift
├── Extensions/
│   └── Color+Hex.swift        ← Color(hex:) initializer
└── Assets.xcassets
    └── AppIcon.appiconset     ← 1024×1024 master, all sizes generated
```

---

## Key Patterns

### Reactive data with `@Query`

Views fetch live data directly — no manual refresh needed.

```swift
@Query(sort: \Task.deadline) private var tasks: [Task]
```

### Writing data with `modelContext`

```swift
@Environment(\.modelContext) private var modelContext

func addTask() {
    let task = Task(title: "", status: .todo)
    modelContext.insert(task)
}
```

### Module colour in views

```swift
Color(hex: task.module?.colorHex ?? "#8D9EAD")
```

Requires a `Color+Hex.swift` extension (a one-time ~10-line utility).

---

## Auto-Behaviours Summary

| Feature | Trigger | Mechanism |
|---|---|---|
| `completedAt` stamped | Task moved to Done | `status.didSet` on `Task` |
| Done tasks deleted | App launch | `Task.deleteExpired()` in `.task {}` |
| Module colour assigned | Module created | `Module.nextColor(for:in:)` |
| Exam time stored | DatePicker in Settings | `Date` includes time component natively |

---

## Icon

Design the master icon at **1024×1024 px** in Pixelmator Pro, export as PNG, then generate all required sizes via [IconKitchen](https://icon.kitchen). Drop the result into `Assets.xcassets → AppIcon`. macOS applies the squircle mask automatically.
