# flutter_smart_debouncer

[![pub package](https://img.shields.io/pub/v/flutter_smart_debouncer.svg)](https://pub.dev/packages/flutter_smart_debouncer)
[![Build status](https://github.com/example/flutter_smart_debouncer/actions/workflows/dart.yml/badge.svg)](https://github.com/example/flutter_smart_debouncer/actions/workflows/dart.yml)

```
  _____ _       _   _            _                 _      _                         
 / ____| |     | | (_)          | |               | |    | |                        
| (___ | |_ ___| |_ _  ___ ___  | |__   ___   ___ | | ___| |_ _ __ ___   ___  _ __  
 \___ \| __/ _ \ __| |/ __/ __| | '_ \ / _ \ / _ \| |/ _ \ __| '_ ` _ \ / _ \| '_ \ 
 ____) | ||  __/ |_| | (__\__ \ | | | | (_) | (_) | |  __/ |_| | | | | | (_) | | | |
|_____/ \__\___|\__|_|\___|___/ |_| |_|\___/ \___/|_|\___|\__|_| |_| |_|\___/|_| |_|
```

Smart debouncing and throttling for modern Dart & Flutter apps. Keep noisy signals under control with predictable execution semantics, async safety, and polished developer experience.

## Why debounce *and* throttle?

Debounce waits for silence before firing, while throttle limits how often events fire. `flutter_smart_debouncer` gives you both, tuned for UI, networking, and background workloads.

## Features

- ✅ Async-aware debouncer with leading/trailing edges and `maxWait`
- ✅ Per-key debounce pools for form validation and batch processing
- ✅ Smart throttle with leading/trailing options
- ✅ Stream extensions to debounce/throttle streams without extra deps
- ✅ `DebouncedValue` reactive helper for state management
- ✅ Optional Flutter bindings with `DebouncedTextField`
- ✅ Deterministic tests with `fake_async`
- ✅ Null-safe and web ready

## Timing diagrams

### Debounce (leading + trailing)

```
Calls:   |x|x|x|   |x|
Leading: X            
Trailing:      -----X      -----X
```

### Debounce with maxWait

```
Time -->
Call:  x x x x x x x x
Run:   X       X       X
        <maxWait>
```

### Throttle (leading + trailing)

```
Calls:   |x|x|x|x|   |x|
Leading: X       X
Trailing:     X       X
Interval: <----->
```

## Quick start

### Simple search box debounce

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

### Scroll throttle

```dart
final scrollThrottle = SmartThrottle<void>(interval: const Duration(milliseconds: 100));

void onScroll() {
  scrollThrottle(() => updateScrollPosition());
}
```

## Stream helpers

```dart
stream.debounceTime(const Duration(milliseconds: 300));
stream.throttleTime(
  const Duration(milliseconds: 100),
  leading: true,
  trailing: true,
);
```

## DebouncedValue

```dart
final value = DebouncedValue<int>(0, delay: const Duration(milliseconds: 200));
value.stream.listen(print);
value.set(1);
value.set(2);
```

## FAQ

**Why didn’t my action run?**

Ensure `trailing` is true or call `flush()` to force the last action. When `leading` is true and `trailing` is false, only the first call in a burst runs.

**Why did it run twice?**

Using `leading` and `trailing` together means the first call fires immediately and the last call in the window fires after the delay. Disable one edge if you only need a single run.

**How does `maxWait` interact with `leading`?**

`maxWait` guarantees execution at most every `maxWait` duration. If `leading` is true, the first run happens immediately and `maxWait` is counted from that run.

**How do I test with `fake_async`?**

Wrap your test body in `fakeAsync((async) { ... })` and advance time using `async.elapse(...)`. All timers inside `SmartDebouncer` use the zone’s clock, so tests stay deterministic.

**What about background tabs on the web?**

Timers may be throttled by the browser; `maxWait` helps ensure periodic execution once the tab becomes active again.

## Performance

`SmartDebouncer` uses a single active timer per instance with O(1) updates. It avoids chained microtasks to prevent drift and works equally well on the VM and the web.

## Contributing

We welcome contributions! Please file an issue first, run the provided tests, and follow the included analysis options. Pull requests should include tests and updated documentation when relevant.

## License

[MIT](LICENSE)
