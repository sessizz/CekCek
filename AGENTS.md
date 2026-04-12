# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

CekCek is a native iOS/macOS SwiftUI app for RV/Caravan owners to manage maintenance checklists. It uses SwiftData for local persistence with no external dependencies.

**Targets:** iOS 17.0+, macOS 14.0+  
**Bundle ID:** `ssz.CekCek`

## Build Commands

```bash
# Open in Xcode
open CekCek.xcodeproj

# Build from CLI
xcodebuild -project CekCek.xcodeproj -scheme CekCek -configuration Debug

# Run tests (if added)
xcodebuild test -project CekCek.xcodeproj -scheme CekCek -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

The app follows a layered architecture with SwiftUI + SwiftData:

**Data Models** (`Models/`) — SwiftData `@Model` classes:
- `Checklist` — parent entity with `titleKey`/`customTitle` (supports both localized defaults and user-created)
- `ChecklistItem` — child items with `isChecked` state, cascade-deleted with parent
- `CompletionRecord` — history snapshot (date, total/checked counts) per checklist completion

**Views** (`Views/`) — SwiftUI views using `@Query` for reactive SwiftData fetching and `@Bindable` for two-way binding. `ContentView.swift` is the root with `NavigationSplitView` for iPad/Mac layout.

**Business Logic:**
- `Extensions/Checklist+Progress.swift` — progress calculation
- `Services/DefaultDataSeeder.swift` — seeds 6 default RV checklists on first launch
- `Data/DefaultChecklists.swift` — static definitions of default checklists

**App Entry:** `CekCekApp.swift` sets up the `ModelContainer` and injects it into the SwiftUI environment.

## Localization

All user-facing strings must use `LocalizedStringKey` — never hardcode strings. The localization file is `CekCek/Localizable.xcstrings` (Xcode's modern format supporting Turkish `tr` and English `en`).

Key naming convention: `"checklist.preDeparture"`, `"item.checkTirePressure"` — use dot-notation with category prefix.

Default checklist titles and item titles use `titleKey`/`itemKey` fields that map to localization keys. Custom user-created content uses `customTitle` fields instead.

## Platform-Specific Code

Use conditional compilation for platform differences:
```swift
#if os(macOS)
    // macOS-specific UI
#else
    // iOS-specific UI
#endif
```
