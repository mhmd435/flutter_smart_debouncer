# flutter_smart_debouncer

[![pub package](https://img.shields.io/pub/v/flutter_smart_debouncer.svg)](https://pub.dev/packages/flutter_smart_debouncer)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`flutter_smart_debouncer` is a unified toolkit for taming noisy inputs. It
combines production-ready debouncing utilities with polished Flutter widgets so
you can guard API calls, smooth out text entry, and prevent accidental double
submits using a single dependency.

> **Debouncing** coalesces a burst of events into a single callback once the
> user pauses. It keeps search boxes snappy, throttles autosave traffic, and
> prevents repeated taps on important buttons.

## Quick start

Add the package to your app:

```yaml
dependencies:
  flutter_smart_debouncer: ^1.0.1
```

### Debounce anything in Dart code

```dart
final searchDebouncer = Debouncer<void>(
  delay: const Duration(milliseconds: 300),
);

Future<void> onQueryChanged(String value) {
  return searchDebouncer(() async {
    await searchApi(value);
  });
}
```

### SmartDebouncerTextField

```dart
SmartDebouncerTextField(
  delay: const Duration(milliseconds: 250),
  decoration: const InputDecoration(labelText: 'Search'),
  onChangedDebounced: (value) {
    debugPrint('Searching for $value');
  },
);
```

### SmartDebouncerButton

```dart
SmartDebouncerButton(
  delay: const Duration(milliseconds: 600),
  child: const Text('Submit'),
  onPressed: () {
    debugPrint('Submitted once');
  },
);
```

## What's inside?

- ✅ Battle-tested debouncer with leading/trailing edges, `maxWait`, cancel, and flush APIs
- ✅ Widget wrappers for text fields and buttons built on top of the same debouncer
- ✅ Stream helpers, throttle utilities, and reactive `DebouncedValue`
- ✅ Thorough tests, lints, and an example Flutter app demonstrating both styles

## Example app

See [`example/lib/main.dart`](example/lib/main.dart) for a Flutter demo that
simulates an API call using the core `Debouncer` and shows the smart widgets in
a material UI.

Run it with:

```bash
flutter run
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release notes.

## License

Distributed under the [MIT License](LICENSE).
