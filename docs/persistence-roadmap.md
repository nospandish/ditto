# Local Persistence Roadmap

## Goal

Keep tasks and available-time windows after the app closes. Generated schedules
do not need to be stored because Ditto can regenerate them from the saved data.

## Phase 1: Prepare safely

- [x] Pull the newest `main` branch.
- [x] Create the isolated `codex/local-persistence` branch.
- [x] Add `shared_preferences` for lightweight offline storage.
- [x] Avoid editing `app_shell.dart` until impossible-schedule handling is
  merged.

## Phase 2: Make models serializable

Add JSON conversion to `DittoTask` and `AvailableTimeBlock`.

Store:

- Task name
- Minimum and maximum minutes
- Importance
- Optional due date
- Available-time start and end minutes

Add unit tests confirming each model can convert to JSON and back without
losing information.

## Phase 3: Build the storage service

Create `lib/services/local_storage_service.dart` with these responsibilities:

- Save and load tasks
- Save and load available-time windows
- Clear all saved data
- Keep storage keys in one place
- Return empty lists when no data has been saved
- Handle malformed saved data without crashing
- Remain independent from UI code

Store JSON strings using `shared_preferences`.

## Phase 4: Test the service

Test:

- Saving and loading tasks
- Saving and loading time windows
- Empty storage
- Optional due dates
- Every importance level
- Replacing previously saved data
- Corrupted data handling
- Clearing saved data

Use mocked shared preferences so the tests do not depend on a physical device.

## Phase 5: Merge current work

After impossible-schedule handling reaches `main`:

- Pull the updated `main` branch.
- Merge it into the persistence branch.
- Resolve model conflicts carefully.
- Run the complete test suite.

## Phase 6: Integrate persistence

Connect the storage service to `AppShell`:

- Load saved data during startup.
- Show a small loading state while reading.
- Save after adding, editing, or deleting a task.
- Save after adding, editing, or deleting available time.
- Regenerate or clear the schedule when loaded data changes.
- Handle storage failures without crashing.

## Phase 7: User experience

- Avoid briefly showing empty screens before saved data loads.
- Optionally add a **Clear all data** action later.
- Show an error only when saving genuinely fails.
- Keep the app fully functional without accounts or internet access.

## Definition of done

- Tasks survive restarting the app.
- Available-time windows survive restarting the app.
- Edits and deletions remain saved.
- Empty or corrupted storage does not crash the app.
- All existing and new tests pass.
- The app remains fully offline.

## First checkpoint

Complete model serialization, the storage service, and its tests without
editing `AppShell`. Integrate only after the impossible-schedule branch has
been merged.
