# Wellness App

SwiftUI iOS app for intermittent fasting tracking and macro logging via food photos.

## Project Overview

- **Platform**: iOS 17+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Persistence**: SwiftData
- **Architecture**: MVVM
- **Bundle ID**: com.sbailey.Wellness

## Architecture

### MVVM Structure

```
Wellness/
├── Models/          # SwiftData @Model classes (plain data, no UI imports)
├── ViewModels/      # @Observable classes — business logic, SwiftData queries
├── Views/           # SwiftUI views — layout and user interaction only
│   ├── Fasting/     # Fasting timer screens
│   ├── Macros/      # Macro logging and food photo screens
│   └── Components/  # Reusable UI components
├── Services/        # Camera, photo analysis, nutrition API clients
└── Utilities/       # Extensions, formatters, constants
```

### Key Rules

- Views hold no business logic — delegate to ViewModels via `@State` or `@Bindable`
- ViewModels are `@Observable` (not `ObservableObject`) — use the Swift 5.9+ `@Observable` macro
- Models are pure `@Model` SwiftData classes — no `@Published`, no UI code
- Pass `ModelContext` into ViewModels via initializer; never access it from Views directly
- One `ModelContainer` configured at the app entry point in `WellnessApp.swift`

## SwiftData

- Define all `@Model` types in `Models/`
- Use `@Query` in Views only for simple, static fetches; use `ModelContext.fetch()` in ViewModels for dynamic queries
- Migrations go in a versioned `SchemaMigrationPlan` — never delete/rename `@Model` properties without a migration
- Relationships: use `@Relationship(deleteRule: .cascade)` where child objects should not outlive parents

## Features

### Intermittent Fasting
- Start/stop fasting timer with persistent state (survives app restart)
- Track fasting window (e.g. 16:8) and display elapsed/remaining time
- Log completed fasts with start/end timestamps

### Macro Logging via Food Photos
- Camera capture and photo library picker
- On-device or API-based food recognition to estimate macros
- Manual macro entry/override
- Daily macro totals (calories, protein, carbs, fat)

## Code Conventions

- **Naming**: `FooView`, `FooViewModel`, `FooModel` — explicit suffixes on every type
- **SwiftUI previews**: every View has a `#Preview` using in-memory `ModelContainer`
- **Error handling**: propagate errors to ViewModel, surface to user via `.alert`
- **Async**: use `async/await`; mark ViewModel methods `@MainActor` where they update UI state
- **No third-party dependencies** unless absolutely necessary — prefer system frameworks (Vision, PhotosUI, AVFoundation)

## Building & Running

Open `Wellness.xcodeproj` in Xcode 15+. No package dependencies to resolve currently.

Target a physical device or simulator running iOS 17+. Camera features require a physical device.

## Testing

- Unit test ViewModels with an in-memory `ModelContainer` (pass `isStoredInMemoryOnly: true`)
- Do not mock SwiftData — use a real in-memory store
- UI tests cover critical happy paths: start fast, log food, view daily summary
