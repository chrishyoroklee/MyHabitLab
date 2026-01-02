# MyHabitLab Plan

This is a living implementation plan for **MyHabitLab**, a habit tracker iOS app.

## 1) Product goals

### Primary goal

Build a fast, offline-first habit tracker focused on daily execution:

- Create habits quickly
- See what is due today
- Mark completion with minimal friction
- Review progress over time (grid and calendar views)
- Support home screen widgets for at-a-glance status and quick interaction

### Non-goals

- Copying proprietary code, assets, or exact UI screens from other apps
- Building a server backend for v1
- Social feeds, messaging, or community features in v1

### Success criteria (v1)

- A new user can create a habit and mark today as complete in under 30 seconds.
- A user can correct past days safely (add or remove completion).
- Data is stored locally and survives app restarts.
- Widgets show today’s state and allow a fast action (if supported by the OS version).

## 2) Inspiration feature map (for parity planning)

This is a pragmatic list of patterns commonly found in habit trackers that we can implement with original UI.

### Reference apps (feature highlights)

These are feature highlights gathered from public descriptions to guide parity planning. Implementations and visuals should be original.

- HabitKit highlights
  - Tile-based grid charts with per-day squares
  - Calendar editing for past days
  - Archiving inactive habits
  - Import and export
  - Privacy-first posture (no sign-in required; local storage)

- Habit Tracker highlights
  - Habit tracking with optional unit-based goals (not just checkmarks)
  - Smart reminders (time and location) and multiple reminders per habit
  - Widgets for home screen and lock screen
  - Optional Apple Health syncing for certain habits
  - Optional device lock (Face ID or Touch ID)

### Dashboard and history patterns

- Habit dashboard with per-habit progress
- Grid / heatmap view per habit (tile-based historical completions)
- Calendar view for editing past completions
- Archive inactive habits

### Power-user patterns (later milestones)

- Import and export
- Reminders
- Optional iCloud sync
- App shortcuts and automation hooks
- Health data integrations (only if clearly in-scope)

## 3) Scope and milestones

### Milestone 0: Project baseline

- [ ] App launches and shows a placeholder dashboard
- [ ] Decide persistence approach (SwiftData recommended)
- [ ] Add a minimal navigation shell (TabView)

### Milestone 1: Core data model and persistence

- [ ] SwiftData models: Habit, Completion
- [ ] Day-key strategy for “daily” completion (time zone safe)
- [ ] CRUD for habits
- [ ] Basic seed data for previews

### Milestone 2: Daily tracking MVP

- [ ] Dashboard list of habits
- [ ] Toggle completion for today
- [ ] Habit creation and editing UI
- [ ] Habit detail page

### Milestone 3: History visualization

- [ ] Tile grid / heatmap for a single habit
- [ ] Calendar editor to add/remove past completions
- [ ] Streak calculations

### Milestone 4: Widgets

- [ ] Widget extension target
- [ ] Small and medium widget showing today’s habits
- [ ] (If interactive widgets are enabled) tap to toggle today’s completion

### Milestone 5: Export and import

- [ ] JSON export
- [ ] JSON import with validation
- [ ] Optional: CSV export

### Milestone 6: Polish

- [ ] Accessibility pass (dynamic type, voiceover labels)
- [ ] Haptics and animation polish
- [ ] Empty states and onboarding
- [ ] App icon and basic branding

## 4) Technical architecture

### Recommended stack

- UI: SwiftUI
- Persistence: SwiftData
- Widgets: WidgetKit
- Interactivity: AppIntents (for interactive widgets and shortcuts)
- Notifications: UserNotifications for reminders

### Navigation structure (recommended)

- TabView
  - Dashboard
  - Stats
  - Settings

### Data model (proposed)

#### Habit

- id: UUID
- name: String
- detail: String? (optional)
- icon: String (SF Symbol name, or an emoji)
- color: stored as a serializable representation
- createdAt: Date
- isArchived: Bool
- schedule: schedule definition (start with “daily”, expand later)
- target: optional numeric target (start with boolean completion, expand later)

#### Completion

- id: UUID
- habitId relationship
- dayKey: Int or String (stable daily key derived from user calendar)
- value: Int (use 1 for “done” in v1, leave room for counts later)
- createdAt: Date

#### Day key strategy

Store a stable key for “day” instead of raw timestamps. One option:

- `YYYYMMDD` in the user’s current calendar and time zone at the time of entry

Centralize in a utility:

- `DayKey.from(date, calendar, timeZone)`

This reduces DST and cross-time-zone bugs.

## 5) Risk register

### Interactive widgets

Risk: implementation complexity and OS constraints.

Mitigation:

- Implement read-only widgets first
- Add interactivity behind a small abstraction so the app still works without it

### SwiftData schema changes

Risk: migrations can be painful if the model churns.

Mitigation:

- Keep v1 model minimal
- Avoid frequent renames of properties
- Add lightweight migrations only when required

### Date correctness

Risk: streaks and “today” computations are error-prone.

Mitigation:

- Centralize all date logic
- Add unit tests covering DST boundaries and time-zone changes

## 6) Definition of done

For any milestone item to be considered complete:

- App builds and runs
- No obvious regressions in the main flow
- New logic has tests (when applicable)
- UI has basic accessibility labels

## 7) Cursor prompt library

Use the prompts below in Cursor. Each is designed to keep changes scoped and buildable.

### Prompt 0: Repo audit and baseline build

```
You are a senior iOS engineer. Audit this repository and summarize:
1) Current targets and deployment settings
2) Current UI entry points
3) Gaps vs a habit tracker MVP

Then propose a minimal next change that keeps the app compiling.

Constraints:
- Do not add external dependencies.
- Do not change project settings unless necessary.
- Provide a file-by-file plan.
```

### Prompt 1: Introduce SwiftData persistence

```
Implement SwiftData persistence for MyHabitLab.

Requirements:
- Add SwiftData container setup in the App entry point.
- Create SwiftData @Model types: Habit and Completion.
- Add a DayKey utility that converts Date -> YYYYMMDD Int.
- Keep the app compiling and update previews.

Acceptance criteria:
- App launches and can read/write sample Habit objects.

Files allowed to change:
- MyHabitLab/MyHabitLabApp.swift
- MyHabitLab/ (new files under Models/, Persistence/, Utilities/)
```

### Prompt 2: Dashboard list of habits

```
Build the Dashboard view:

- Show a list of habits (non-archived).
- Each row shows icon, name, and a completion indicator for today.
- Tapping the indicator toggles completion for today.

Constraints:
- Use SwiftData queries.
- Keep date logic centralized (DayKey).
- No force unwraps.

Acceptance criteria:
- Create 2 seed habits in previews and show them.
- Toggling updates the UI immediately.
```

### Prompt 3: Add Habit flow

```
Add a "New Habit" flow.

Requirements:
- Add a + button on Dashboard.
- Present a sheet with a form to create a habit: name, icon, color, optional note.
- Validate that name is non-empty.
- Save via SwiftData.

Acceptance criteria:
- Creating a habit adds it to the Dashboard on dismiss.

Files allowed to change:
- MyHabitLab/ContentView.swift (or rename and reorganize into Features/Dashboard)
- New files under MyHabitLab/Features/
```

### Prompt 4: Edit Habit and archive

```
Implement habit editing.

Requirements:
- Habit detail view with edit button.
- Ability to archive and restore habits.
- Archived habits should not appear on Dashboard.

Acceptance criteria:
- A habit can be archived and disappears from Dashboard.
- A Settings screen can list archived habits for restore.
```

### Prompt 5: Tile grid / heatmap view

```
Implement a tile grid history visualization for a single habit.

Requirements:
- Show the last N days as a grid of squares.
- Filled squares represent completed days.
- Use DayKey values and a generated date range.

Constraints:
- Keep rendering efficient.
- Write unit tests for the mapping from date range -> day keys.

Acceptance criteria:
- Grid matches completion data for previews.
```

### Prompt 6: Calendar editor

```
Add a calendar-based editor for habit completions.

Requirements:
- Calendar UI that allows tapping a day to toggle completion.
- Support editing at least the last 90 days.
- Ensure DayKey is used, not raw timestamps.

Acceptance criteria:
- User can add/remove past completions.
```

### Prompt 7: Streak calculations

```
Implement streak calculations.

Requirements:
- Current streak (consecutive days ending today if completed today).
- Longest streak.
- Completion rate over last 30 days.

Constraints:
- Pure functions for streak calculations.
- Add unit tests covering edge cases.

Acceptance criteria:
- Stats are correct for provided test fixtures.
```

### Prompt 8: Widget (read-only first)

```
Add a WidgetKit extension target for MyHabitLab.

Requirements:
- Small widget showing up to 3 habits with today's completion state.
- Medium widget showing more habits.

Constraints:
- Data sharing via App Group and a small shared store layer.
- Keep the main app working without the widget.

Acceptance criteria:
- Widget renders sample data and updates when the app data changes.
```

### Prompt 9: Widget interaction (optional)

```
If OS supports it, add interactive widget toggling via AppIntents.

Requirements:
- Tapping a habit in the widget toggles today's completion.
- Ensure the action is fast and safe.

Constraints:
- Add guardrails for missing habits and corrupted data.
- Keep read-only widget variant working.

Acceptance criteria:
- Widget tap toggles completion and UI updates.
```

### Prompt 10: Export and import

```
Implement export and import.

Requirements:
- Export all habits and completions to a JSON file.
- Import validates schema and merges by UUID.
- Add Settings UI for export/import.

Constraints:
- Do not block the main thread for large data sets.

Acceptance criteria:
- Export then import into a fresh install recreates the same data.
```

### Prompt 11: Navigation shell and file organization

```
Create a minimal navigation shell and organize code for growth.

Requirements:
- Replace the placeholder ContentView with a TabView containing:
  - Dashboard
  - Stats (placeholder view)
  - Settings (placeholder view)
- Create a simple folder structure under MyHabitLab/:
  - Features/Dashboard
  - Features/Stats
  - Features/Settings
  - UIComponents
  - Models
  - Utilities

Constraints:
- Keep the app compiling.
- Do not change the Xcode project settings unless required.

Acceptance criteria:
- App launches to a TabView.
- Dashboard tab shows existing dashboard content.
```

### Prompt 12: Settings screen (v1)

```
Implement a Settings screen suitable for v1.

Requirements:
- Settings tab with sections:
  - Data: Export, Import
  - Habits: Archived Habits (restore)
  - About: version/build number

Constraints:
- Keep UI simple and stable.
- No external dependencies.

Acceptance criteria:
- User can access Settings and see the sections.
```

### Prompt 13: Reminders (local notifications)

```
Add optional reminders using UserNotifications.

Requirements:
- Per-habit reminder time (single reminder in v1).
- Request notification permission with clear UI.
- Schedule and cancel notifications when habits change.

Constraints:
- Store reminder settings in the Habit model.
- Avoid scheduling excessive notifications.

Acceptance criteria:
- Setting a reminder schedules a local notification.
- Disabling a reminder cancels it.
```

### Prompt 14: Shortcuts and App Intents (toggle completion)

```
Add App Intents to integrate with iOS Shortcuts.

Requirements:
- Intent: ToggleHabitCompletionIntent
  - Parameters: Habit
  - Behavior: toggles today's completion
- Provide a small, safe lookup layer for habits.

Constraints:
- Intent must be fast and not require UI.
- Add error handling for missing habit.

Acceptance criteria:
- Intent appears in Shortcuts.
- Running it toggles today's completion.
```

### Prompt 15: Stats screen (v1)

```
Implement a basic Stats screen.

Requirements:
- Per-habit stats card:
  - Current streak
  - Longest streak
  - Last 30 days completion rate
- Optional aggregate stats (total completions this week).

Constraints:
- Use pure logic functions with unit tests.

Acceptance criteria:
- Stats are stable and match test fixtures.
```

### Prompt 16: Accessibility and localization readiness

```
Improve accessibility and prepare for future localization.

Requirements:
- Add accessibility labels and values for:
  - Completion toggles
  - Grid tiles
  - Buttons and form fields
- Ensure Dynamic Type does not break layout on common screens.
- Move user-facing strings to localized string keys.

Acceptance criteria:
- VoiceOver can describe main actions.
- UI remains usable at larger text sizes.
```

### Prompt 17: Performance pass (large habit lists)

```
Improve performance for users with many habits.

Requirements:
- Ensure dashboard queries are efficient.
- Avoid recomputing DayKey or date ranges repeatedly.
- Add simple profiling notes in docs.

Constraints:
- No premature complexity. Keep code readable.

Acceptance criteria:
- Scrolling remains smooth with 100+ habits in a preview data set.
```

### Prompt 18: Release readiness checklist

```
Create a release readiness checklist for TestFlight.

Requirements:
- Add docs/release-checklist.md with:
  - App icon
  - Privacy policy placeholder
  - Basic App Store metadata checklist
  - Crash-free smoke test steps
  - Settings audit (export/import, reminders)

Constraints:
- Keep it actionable and short.

Acceptance criteria:
- File exists and is usable as a checklist.
```

## 8) Open questions to finalize later

- Habit frequency model: daily only in v1, or also weekly targets?
- Numeric tracking: boolean only in v1, or counts (minutes, reps)?
- iCloud sync: required for v1 or deferred?
- Monetization: free, one-time purchase, or subscription?
