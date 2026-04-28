# Semestral

A native macOS Kanban app for managing university coursework. Built with SwiftUI and SwiftData.

## Features

- **Board** — Drag-and-drop Kanban columns (To Do / In Progress / Done) with deadline-based sorting, urgency-tinted cards, and recurring tasks that roll over on completion.
- **Calendar** — Month view of task deadlines and exam dates, color-coded per module.
- **Exams** — Per-module exam dates, partitioned into upcoming and past, with date-only or date-and-time precision.
- **Grades** — German weighted-average (1.0–5.0, ECTS-weighted) with Bachelor/Master toggle and per-semester breakdowns.
- **Semesters & Modules** — Inline creation from the toolbar dropdown and module pickers; sidebar context menu for edit/delete.
- Persistent active semester, recurring task hide-windows, and automatic cleanup of expired exams and old completed tasks.

## Requirements

- macOS 14+
- Xcode 15+ (Liquid Glass app icon needs Xcode 26+)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`

## Install

Build the app from source and drop it into `/Applications`. This builds an unsigned, ad-hoc-signed binary — no Apple Developer account required.

```bash
# 1. Clone
git clone https://github.com/davidbingmann/Semestral.git
cd Semestral

# 2. Install xcodegen if you don't have it
brew install xcodegen

# 3. Generate the Xcode project (from project.yml)
xcodegen generate

# 4. Build a Release binary
xcodebuild -project Semestral.xcodeproj -scheme Semestral \
  -configuration Release -destination 'platform=macOS' build

# 5. Copy the built .app into /Applications
APP=$(find ~/Library/Developer/Xcode/DerivedData -name "Semestral.app" \
  -path "*/Release/*" -not -path "*Index.noindex*" -print -quit)
cp -R "$APP" /Applications/Semestral.app

# 6. Launch
open /Applications/Semestral.app
```

The first launch may take a moment while macOS registers the app. If Gatekeeper blocks it because the binary is ad-hoc signed, right-click the app in Finder and choose **Open** once — macOS will remember the choice.

To uninstall, delete `/Applications/Semestral.app`. Your data lives at `~/Library/Application Support/Semestral` (and `~/Library/Containers/com.davidbingmann.KanbanApp` on sandboxed builds) — remove that folder too if you want a clean slate.

## Development

The Xcode project is generated from `project.yml`. `Semestral.xcodeproj/` is gitignored.

```bash
xcodegen generate
xcodebuild -project Semestral.xcodeproj -scheme Semestral \
  -configuration Debug -destination 'platform=macOS' build
```

After adding, removing, or renaming any `.swift` file, re-run `xcodegen generate`.

## Project layout

```
Semestral/
├── Models/         Semester (+ DegreeType), Module, KanbanTask, Grade
├── Extensions/     Color+Hex
├── Views/
│   ├── Board/         KanbanBoardView, KanbanColumnView, TaskCardView, AddItemFAB
│   ├── Sidebar/       SemesterSidebarView
│   ├── Calendar/      CalendarTab
│   ├── Exams/         ExamsTab, ExamFormView
│   ├── Grades/        GradesTab, GradeFormView
│   ├── Task/          TaskFormView
│   └── Manage/        SemesterFormView, ModuleFormView
├── AppIcon.icon/      Liquid Glass icon bundle
├── Semestral.swift    @main, ModelContainer
└── ContentView.swift  4-tab TabView
```
