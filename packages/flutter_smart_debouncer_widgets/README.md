# flutter_smart_debouncer_widgets

Flutter bindings for [`flutter_smart_debouncer`](../flutter_smart_debouncer). This package provides
a drop-in `DebouncedTextField` widget for text entry scenarios where you want to delay expensive
work until the user pauses typing.

## DebouncedTextField

```dart
DebouncedTextField(
  delay: const Duration(milliseconds: 400),
  decoration: const InputDecoration(labelText: 'Search'),
  onChangedDebounced: (value) => fetchResults(value),
)
```

- Emits the latest value after the specified [delay].
- Supports leading invocations via `leading: true` to fire immediately and still emit trailing values.
- Bubbles the underlying `TextField` callbacks and configuration.

See the example app for an end-to-end demonstration featuring a search bar, auto-save indicator, and
scroll position throttle.
