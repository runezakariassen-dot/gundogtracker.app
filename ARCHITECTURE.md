## Hive usage & UI update pattern

This project uses a strict separation between app startup, data access, and UI rebuilds.

### Initialization
- All Hive initialization, path setup, adapter registration, and restore-guarding is handled before the widget tree is built.
- Widgets must assume Hive is ready when they are created.

### Box access
- Widgets must NOT call `Hive.box()` directly.
- All boxes are retrieved in `initState()` via `HiveLifecycleService.getBox<T>(...)`.

### UI rebuilds (recommended standard)
- UI pages use `ValueListenableBuilder` with `box.listenable()` for live updates.
- This requires `package:hive_flutter/hive_flutter.dart` and is allowed in UI code.
- The UI layer may depend on `hive_flutter`; domain and data layers must not.

### Streams & watch()
- `box.watch()` is reserved for services, repositories, and background logic.
- UI widgets should not combine or manage multiple Hive streams unless strictly necessary.

### Forbidden patterns
- Calling `Hive.box()` inside `build()` or callbacks
- Accessing Hive while a restore is in progress
- Mixing `listenable()` and `watch()` patterns inconsistently within the same screen

### Goal
This pattern ensures:
- predictable startup
- no `Box not found` or race-condition errors
- stable live-updating UI with minimal boilerplate

## Architecture at a glance

Jakthund is built around a predictable startup flow, strict Hive lifecycle control, and simple reactive UI updates.

### High-level flow

App start  
→ AppStartupService  
→ HiveLifecycleService.init()  
→ Widget tree builds  
→ Pages read from Hive via lifecycle-safe access  
→ UI updates reactively when data changes

### Layers and responsibilities

**Startup layer**
- `AppStartupService`
- Responsible for:
  - Hive path initialization
  - restore-guard handling
  - adapter registration
  - domain bootstrap
- Guarantees that Hive is fully ready before any widgets are built.

**Lifecycle layer**
- `HiveLifecycleService`
- Single source of truth for Hive box access.
- Owns:
  - box opening/closing
  - restore state
  - lifecycle safety
- Exposes `getBox<T>()` for all runtime access.

**Domain layer**
- Pure business logic.
- No Flutter dependencies.
- No `hive_flutter`.
- May use `box.watch()` for background or derived logic.

**UI layer**
- Pages and widgets (Home, Sessions, Dogs, Statistics, Settings).
- Responsibilities:
  - retrieve boxes once in `initState()`
  - render state from `box.values`
  - rebuild via `ValueListenableBuilder(box.listenable())`
- UI may depend on `hive_flutter`.

### Data flow rules

- Data always flows **from Hive → UI**
- UI never controls Hive lifecycle
- Restore operations block UI access until completed
- Live updates are automatic via listenable boxes

### Mental model

Think of Hive as a local evented datastore:

- Startup prepares the datastore
- Lifecycle service guards access
- UI listens, never polls
- Statistics are always derived, never cached

If the app crashes or shows stale data, the bug is almost always:
- accessing Hive too early
- bypassing the lifecycle service
- mixing update patterns

## Standard page creation (Codex prompt)

When creating a new page or screen in the Jakthund app, always follow this pattern.

### 1. Box access
- Retrieve all required Hive boxes once in `initState()`.
- Always use:
  `HiveLifecycleService.getBox<T>(...)`
- Never call `Hive.box()` directly.

### 2. UI rebuild pattern
- Use `ValueListenableBuilder` with `box.listenable()` for live updates.
- Import `package:hive_flutter/hive_flutter.dart` in UI files if needed.
- Rebuild UI based on `box.values`, not cached lists.

### 3. Widget responsibilities
A page should:
- read data
- derive display values
- render UI

A page should NOT:
- manage Hive lifecycle
- open or close boxes
- coordinate restore or backup state
- perform heavy data processing

### 4. Restore safety
- Assume Hive is unavailable during restore.
- UI must not bypass guards in `HiveLifecycleService`.
- If a page shows empty state during restore, this is acceptable.

### 5. Forbidden patterns
- Accessing Hive in `build()` or callbacks
- Mixing `watch()` and `listenable()` in the same page
- Creating streams manually for UI rebuilds
- Initializing Hive in widgets

### 6. Expected structure (example)

```dart
class ExamplePage extends StatefulWidget {
  const ExamplePage({super.key});

  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  late final Box<MyType> _box;

  @override
  void initState() {
    super.initState();
    _box = HiveLifecycleService.getBox<MyType>(HiveBoxes.myBox);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _box.listenable(),
      builder: (context, Box<MyType> box, _) {
        final items = box.values.toList();
        return _buildUi(items);
      },
    );
  }
}
```

Goal

This prompt ensures:

consistent architecture

predictable rebuilds

no Hive race conditions

minimal boilerplate
