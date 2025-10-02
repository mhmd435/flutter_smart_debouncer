# flutter_smart_debouncer

[![pub package](https://img.shields.io/pub/v/flutter_smart_debouncer.svg)](https://pub.dev/packages/flutter_smart_debouncer)
[![Build status](https://github.com/example/flutter_smart_debouncer/actions/workflows/dart.yml/badge.svg)](https://github.com/example/flutter_smart_debouncer/actions/workflows/dart.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Smart debouncing and throttling for modern Dart & Flutter apps. Keep noisy signals under control with predictable execution semantics, async safety, and a polished developer experience.

`flutter_smart_debouncer` bundles production-ready utilities for debouncing, throttling, pooling, and reactive values with full null-safety. Use it to smooth text inputs, rate-limit network calls, or coordinate work across isolates and widgets.

> Looking for a ready-made widget? Check out the optional [`flutter_smart_debouncer_widgets`](../flutter_smart_debouncer_widgets) package.

## Features

- ✅ Async-aware debouncer with leading/trailing edges and `maxWait`
- ✅ Pool debouncers by key for form validation and batching workflows
- ✅ Smart throttle with separate leading/trailing control
- ✅ Stream extensions to debounce/throttle without extra dependencies
- ✅ `DebouncedValue` reactive helper for simple state management
- ✅ Deterministic tests with `fake_async`
- ✅ Thorough documentation and example app

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_smart_debouncer: ^1.0.0
```

Then run `dart pub get` (or `flutter pub get`).

## Usage

### Debounce a search box

```dart
final debouncer = SmartDebouncer<void>(delay: const Duration(milliseconds: 300));

Future<void> onQueryChanged(String value) async {
  await debouncer(() => search(value));
}
```

### Auto-save with leading + trailing + maxWait

```dart
final autoSave = SmartDebouncer<void>(
  delay: const Duration(seconds: 2),
  leading: true,
  trailing: true,
  maxWait: const Duration(seconds: 8),
);

void onDocumentChanged(String snapshot) {
  autoSave(() async {
    await saveToServer(snapshot);
  });
}
```

### Per-key validation pool

```dart
final validators = DebouncePool<void>(defaultDelay: const Duration(milliseconds: 400));

Future<void> validateField(String field, String value) {
  return validators.call(field, () => validate(field, value));
}
```

### Throttle scroll callbacks

```dart
final scrollThrottle = SmartThrottle<void>(interval: const Duration(milliseconds: 100));

void onScroll() {
  scrollThrottle(() => updateScrollPosition());
}
```

### Stream helpers

```dart
stream.debounceTime(const Duration(milliseconds: 300));
stream.throttleTime(
  const Duration(milliseconds: 100),
  leading: true,
  trailing: true,
);
```

### DebouncedValue for reactive state

```dart
final value = DebouncedValue<int>(0, delay: const Duration(milliseconds: 200));
value.stream.listen(print);
value.set(1);
value.set(2);
```

## Examples

Clone the repository and run the [example application](example/lib/main.dart) to see the utilities in action:

```bash
cd example
dart run
```

The example prints debounced, throttled, and pooled output directly to the console and demonstrates `DebouncedValue` usage.

## API reference

Read the full API reference on [pub.dev](https://pub.dev/documentation/flutter_smart_debouncer/latest/).

## Contributing

Contributions are welcome! Please:

1. File an issue describing the change or bug fix.
2. Run the analyzer and tests (`dart analyze`, `dart test`).
3. Update documentation and add tests for new features.

For monorepo-specific workflows, refer to the repository README.

## License

Distributed under the [MIT License](LICENSE).
