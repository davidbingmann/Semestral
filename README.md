# KanbanApp

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

## Build

The Xcode project is generated from `project.yml`. `KanbanApp.xcodeproj/` is gitignored.

```bash
xcodegen generate
xcodebuild -project KanbanApp.xcodeproj -scheme KanbanApp \
  -configuration Debug -destination 'platform=macOS' build
```

After adding, removing, or renaming any `.swift` file, re-run `xcodegen generate`.

## Project layout

```
KanbanApp/
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
├── KanbanApp.swift    @main, ModelContainer
└── ContentView.swift  4-tab TabView
```
