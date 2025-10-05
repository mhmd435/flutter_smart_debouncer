# flutter_smart_debouncer

[![pub package](https://img.shields.io/pub/v/flutter_smart_debouncer.svg)](https://pub.dev/packages/flutter_smart_debouncer)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

`flutter_smart_debouncer` is a unified toolkit for taming noisy inputs. It combines production-ready debouncing and throttling utilities with polished Flutter widgets so you can guard API calls, smooth out text entry, and prevent accidental double submits using a single dependency.

> **Debouncing** coalesces a burst of events into a single callback once the user pauses. It keeps search boxes snappy, throttles autosave traffic, and prevents repeated taps on important buttons.

## Table of Contents

- [Quick Start](#quick-start)
- [Core Features](#core-features)
  - [SmartDebouncer / Debouncer](#smartdebouncer--debouncer)
  - [SmartThrottle](#smartthrottle)
  - [DebouncePool](#debouncepool)
  - [DebouncedValue](#debouncedvalue)
  - [Stream Extensions](#stream-extensions)
- [Flutter Widgets](#flutter-widgets)
  - [SmartDebouncerTextField](#smartdebouncertextfield)
  - [SmartDebouncerButton](#smartdebouncerbutton)
- [Advanced Usage](#advanced-usage)
- [Example App](#example-app)
- [API Reference](#api-reference)

## Quick Start

Add the package to your app:

```yaml
dependencies:
  flutter_smart_debouncer: ^1.0.1
```

Import the package:

```dart
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';
```

## Core Features

### SmartDebouncer / Debouncer

The `SmartDebouncer` (aliased as `Debouncer`) is the heart of this package. It coalesces rapid-fire calls into a single execution after the specified delay.

#### Basic Usage

```dart
final searchDebouncer = Debouncer<void>(
  delay: const Duration(milliseconds: 300),
);

void onSearchChanged(String query) {
  searchDebouncer(() async {
    final results = await searchApi(query);
    updateUI(results);
  });
}
```

#### Leading Edge Execution

Execute immediately on the first call, then ignore subsequent calls during the delay period:

```dart
final debouncer = Debouncer<void>(
  delay: const Duration(milliseconds: 500),
  leading: true,
  trailing: false,
);

// First call executes immediately
// Subsequent calls within 500ms are ignored
debouncer(() => print('Executed!'));
```

#### Trailing Edge Execution (Default)

Execute after the delay period when calls stop:

```dart
final debouncer = Debouncer<void>(
  delay: const Duration(milliseconds: 300),
  trailing: true, // default
);

// Executes 300ms after the last call
debouncer(() => print('Executed after pause'));
```

#### Both Leading and Trailing

Execute immediately on the first call AND after the delay when calls stop:

```dart
final debouncer = Debouncer<void>(
  delay: const Duration(milliseconds: 300),
  leading: true,
  trailing: true,
);
```

#### Max Wait

Ensure execution happens at least every `maxWait` duration, even if calls keep coming:

```dart
final debouncer = Debouncer<void>(
  delay: const Duration(milliseconds: 300),
  maxWait: const Duration(seconds: 2),
);

// Even if calls keep coming, execution happens at least every 2 seconds
```

#### Pause and Resume

Pause the debouncer timer and resume it later:

```dart
final debouncer = Debouncer<void>(
  delay: const Duration(milliseconds: 500),
);

debouncer(() => print('Action'));

// Pause the timer
debouncer.pause();

// Resume the timer (continues from where it was paused)
debouncer.resume();
```

#### Cancel

Cancel any pending execution:

```dart
final debouncer = Debouncer<void>(
  delay: const Duration(milliseconds: 500),
);

debouncer(() => print('This will be cancelled'));

// Cancel before execution
debouncer.cancel();
```

#### Flush

Execute pending action immediately:

```dart
final debouncer = Debouncer<void>(
  delay: const Duration(milliseconds: 500),
);

debouncer(() => print('Flushed immediately'));

// Execute immediately instead of waiting
await debouncer.flush();
```

#### Error Handling

Handle errors from debounced callbacks:

```dart
final debouncer = Debouncer<void>(
  delay: const Duration(milliseconds: 300),
  onError: (error, stackTrace) {
    print('Error in debounced callback: $error');
    logError(error, stackTrace);
  },
);

debouncer(() async {
  throw Exception('Something went wrong');
});
```

#### Return Values

Get return values from debounced callbacks:

```dart
final debouncer = Debouncer<String>(
  delay: const Duration(milliseconds: 300),
);

final result = await debouncer(() async {
  final data = await fetchData();
  return data;
});

print('Result: $result');
```

#### Check Status

```dart
// Check if there's a pending or running action
if (debouncer.isActive) {
  print('Debouncer is active');
}

// Check if paused
if (debouncer.isPaused) {
  print('Debouncer is paused');
}
```

#### Dispose

Always dispose when done:

```dart
@override
void dispose() {
  debouncer.dispose();
  super.dispose();
}
```

---

### SmartThrottle

`SmartThrottle` limits how frequently a callback can execute. Unlike debouncing, throttling ensures execution happens at regular intervals.

#### Basic Usage

```dart
final scrollThrottle = SmartThrottle<void>(
  interval: const Duration(milliseconds: 200),
);

void onScroll(ScrollNotification notification) {
  scrollThrottle(() {
    updateScrollPosition(notification.metrics.pixels);
  });
}
```

#### Leading Edge (Default)

Execute immediately on the first call, then throttle subsequent calls:

```dart
final throttle = SmartThrottle<void>(
  interval: const Duration(milliseconds: 500),
  leading: true, // default
  trailing: false,
);

// First call executes immediately
// Next call can only execute after 500ms
throttle(() => print('Throttled!'));
```

#### Trailing Edge

Execute after the interval when calls stop:

```dart
final throttle = SmartThrottle<void>(
  interval: const Duration(milliseconds: 500),
  leading: false,
  trailing: true,
);
```

#### Both Leading and Trailing

```dart
final throttle = SmartThrottle<void>(
  interval: const Duration(milliseconds: 500),
  leading: true,
  trailing: true,
);
```

#### Cancel and Flush

```dart
// Cancel pending execution
throttle.cancel();

// Execute pending action immediately
await throttle.flush();
```

#### Error Handling

```dart
final throttle = SmartThrottle<void>(
  interval: const Duration(milliseconds: 300),
  onError: (error, stackTrace) {
    print('Error: $error');
  },
);
```

#### Real-World Example: Scroll Tracking

```dart
class MyScrollableWidget extends StatefulWidget {
  @override
  State<MyScrollableWidget> createState() => _MyScrollableWidgetState();
}

class _MyScrollableWidgetState extends State<MyScrollableWidget> {
  final _scrollThrottle = SmartThrottle<void>(
    interval: const Duration(milliseconds: 100),
  );

  @override
  void dispose() {
    _scrollThrottle.dispose();
    super.dispose();
  }

  void _handleScroll(ScrollNotification notification) {
    _scrollThrottle(() {
      // This executes at most once every 100ms
      analytics.trackScroll(notification.metrics.pixels);
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _handleScroll(notification);
        return false;
      },
      child: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
      ),
    );
  }
}
```

---

### DebouncePool

`DebouncePool` manages multiple debouncer instances grouped by string keys. Perfect for scenarios where you need separate debouncers for different items (e.g., form fields, list items).

#### Basic Usage

```dart
final pool = DebouncePool<void>(
  defaultDelay: const Duration(milliseconds: 300),
);

// Each key gets its own debouncer
pool.call('field1', () => saveField1());
pool.call('field2', () => saveField2());
pool.call('field3', () => saveField3());
```

#### Obtain Specific Debouncer

```dart
final pool = DebouncePool<void>();

// Get or create a debouncer for a specific key
final debouncer = pool.obtain('userId_123');

// Use it multiple times
debouncer(() => updateUser());
```

#### Custom Configuration Per Key

```dart
final pool = DebouncePool<void>(
  defaultDelay: const Duration(milliseconds: 300),
);

// Override defaults for specific keys
final fastDebouncer = pool.obtain(
  'quickField',
  delay: const Duration(milliseconds: 100),
  leading: true,
);

final slowDebouncer = pool.obtain(
  'slowField',
  delay: const Duration(seconds: 1),
  maxWait: const Duration(seconds: 3),
);
```

#### Time-To-Live (TTL)

Automatically dispose inactive debouncers after a period:

```dart
final pool = DebouncePool<void>(
  defaultDelay: const Duration(milliseconds: 300),
  ttl: const Duration(minutes: 5), // Auto-dispose after 5 minutes of inactivity
);
```

#### Cancel, Flush, and Dispose

```dart
// Cancel pending work for a specific key
pool.cancel('field1');

// Flush pending work for a specific key
await pool.flush('field2');

// Dispose a specific debouncer
pool.disposeKey('field3');

// Dispose all debouncers
pool.disposeAll();
```

#### Real-World Example: Form Auto-Save

```dart
class AutoSaveForm extends StatefulWidget {
  @override
  State<AutoSaveForm> createState() => _AutoSaveFormState();
}

class _AutoSaveFormState extends State<AutoSaveForm> {
  final _pool = DebouncePool<void>(
    defaultDelay: const Duration(milliseconds: 500),
    ttl: const Duration(minutes: 10),
  );

  @override
  void dispose() {
    _pool.disposeAll();
    super.dispose();
  }

  void _saveField(String fieldName, String value) {
    _pool.call(fieldName, () async {
      await api.saveField(fieldName, value);
      print('Saved $fieldName: $value');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'Name'),
          onChanged: (value) => _saveField('name', value),
        ),
        TextField(
          decoration: const InputDecoration(labelText: 'Email'),
          onChanged: (value) => _saveField('email', value),
        ),
        TextField(
          decoration: const InputDecoration(labelText: 'Phone'),
          onChanged: (value) => _saveField('phone', value),
        ),
      ],
    );
  }
}
```

---

### DebouncedValue

`DebouncedValue` is a reactive container that stores a value and emits updates through a stream after a debounce delay.

#### Basic Usage

```dart
final searchQuery = DebouncedValue<String>(
  '',
  delay: const Duration(milliseconds: 300),
);

// Listen to debounced updates
searchQuery.stream.listen((value) {
  print('Debounced search: $value');
  performSearch(value);
});

// Set values rapidly
searchQuery.set('a');
searchQuery.set('ab');
searchQuery.set('abc');
// Only 'abc' is emitted after 300ms

// Get current value immediately
print(searchQuery.value); // 'abc'

// Clean up
await searchQuery.close();
```

#### Real-World Example: Search with StreamBuilder

```dart
class SearchWidget extends StatefulWidget {
  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final _searchQuery = DebouncedValue<String>(
    '',
    delay: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _searchQuery.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'Search'),
          onChanged: (value) => _searchQuery.set(value),
        ),
        StreamBuilder<String>(
          stream: _searchQuery.stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('Type to search');
            }
            return FutureBuilder<List<String>>(
              future: searchApi(snapshot.data!),
              builder: (context, results) {
                if (!results.hasData) {
                  return const CircularProgressIndicator();
                }
                return ListView(
                  shrinkWrap: true,
                  children: results.data!
                      .map((item) => ListTile(title: Text(item)))
                      .toList(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
```

---

### Stream Extensions

Debounce and throttle any Dart stream with convenient extensions.

#### debounceTime

```dart
final stream = Stream.periodic(
  const Duration(milliseconds: 100),
  (count) => count,
);

// Only emit after 300ms of silence
stream.debounceTime(const Duration(milliseconds: 300)).listen((value) {
  print('Debounced: $value');
});
```

#### throttleTime

```dart
final stream = Stream.periodic(
  const Duration(milliseconds: 50),
  (count) => count,
);

// Emit at most once every 200ms
stream.throttleTime(
  const Duration(milliseconds: 200),
  leading: true,
  trailing: true,
).listen((value) {
  print('Throttled: $value');
});
```

#### Real-World Example: Text Field Stream

```dart
class StreamSearchWidget extends StatefulWidget {
  @override
  State<StreamSearchWidget> createState() => _StreamSearchWidgetState();
}

class _StreamSearchWidgetState extends State<StreamSearchWidget> {
  final _controller = StreamController<String>();
  late final Stream<String> _debouncedStream;

  @override
  void initState() {
    super.initState();
    _debouncedStream = _controller.stream
        .debounceTime(const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: (value) => _controller.add(value),
          decoration: const InputDecoration(labelText: 'Search'),
        ),
        StreamBuilder<String>(
          stream: _debouncedStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }
            return Text('Searching for: ${snapshot.data}');
          },
        ),
      ],
    );
  }
}
```

---

## Flutter Widgets

### SmartDebouncerTextField

A drop-in replacement for `TextField` with built-in debouncing.

#### Basic Usage

```dart
SmartDebouncerTextField(
  delay: const Duration(milliseconds: 300),
  decoration: const InputDecoration(labelText: 'Search'),
  onChangedDebounced: (value) {
    print('Debounced: $value');
    performSearch(value);
  },
)
```

#### All Parameters

```dart
SmartDebouncerTextField(
  delay: const Duration(milliseconds: 300),
  leading: false,
  trailing: true,
  maxWait: const Duration(seconds: 2),
  
  // Debounced callback
  onChangedDebounced: (value) => print('Debounced: $value'),
  
  // Immediate callback (not debounced)
  onChanged: (value) => print('Immediate: $value'),
  
  // Standard TextField parameters
  controller: myController,
  focusNode: myFocusNode,
  decoration: const InputDecoration(
    labelText: 'Email',
    border: OutlineInputBorder(),
  ),
  keyboardType: TextInputType.emailAddress,
  textInputAction: TextInputAction.search,
  style: const TextStyle(fontSize: 16),
  textAlign: TextAlign.start,
  autofocus: false,
  obscureText: false,
  enabled: true,
  minLines: 1,
  maxLines: 1,
  textCapitalization: TextCapitalization.none,
  onSubmitted: (value) => print('Submitted: $value'),
)
```

#### Real-World Example: Search Field

```dart
class SearchPage extends StatefulWidget {
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<String> _results = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final results = await searchApi(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SmartDebouncerTextField(
              delay: const Duration(milliseconds: 300),
              maxWait: const Duration(seconds: 2),
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChangedDebounced: _performSearch,
            ),
          ),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  return ListTile(title: Text(_results[index]));
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

---

### SmartDebouncerButton

A button that prevents accidental double-taps and rapid repeated presses.

#### Basic Usage

```dart
SmartDebouncerButton(
  delay: const Duration(milliseconds: 500),
  onPressed: () {
    print('Button pressed (debounced)');
    submitForm();
  },
  child: const Text('Submit'),
)
```

#### All Parameters

```dart
SmartDebouncerButton(
  delay: const Duration(milliseconds: 500),
  leading: true,  // Execute immediately on first press
  trailing: false, // Don't execute on trailing edge
  maxWait: const Duration(seconds: 2),
  
  onPressed: () => print('Pressed'),
  
  // Standard button styling
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ),
  
  child: const Text('Submit'),
)
```

#### Real-World Example: Form Submission

```dart
class SubmitFormButton extends StatefulWidget {
  final VoidCallback onSubmit;

  const SubmitFormButton({required this.onSubmit});

  @override
  State<SubmitFormButton> createState() => _SubmitFormButtonState();
}

class _SubmitFormButtonState extends State<SubmitFormButton> {
  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    
    try {
      widget.onSubmit();
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted successfully!')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartDebouncerButton(
      delay: const Duration(milliseconds: 700),
      leading: true,
      trailing: false,
      onPressed: _isSubmitting ? null : _handleSubmit,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      child: _isSubmitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Submit'),
    );
  }
}
```

---

## Advanced Usage

### Combining Multiple Features

```dart
class AdvancedSearchWidget extends StatefulWidget {
  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> {
  final _pool = DebouncePool<void>(
    defaultDelay: const Duration(milliseconds: 300),
  );
  
  final _scrollThrottle = SmartThrottle<void>(
    interval: const Duration(milliseconds: 100),
  );

  @override
  void dispose() {
    _pool.disposeAll();
    _scrollThrottle.dispose();
    super.dispose();
  }

  void _searchCategory(String category, String query) {
    _pool.call('search_$category', () async {
      final results = await searchInCategory(category, query);
      updateResults(category, results);
    });
  }

  void _trackScroll(double position) {
    _scrollThrottle(() {
      analytics.trackScrollPosition(position);
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _trackScroll(notification.metrics.pixels);
        return false;
      },
      child: ListView(
        children: [
          SmartDebouncerTextField(
            delay: const Duration(milliseconds: 300),
            decoration: const InputDecoration(labelText: 'Search Books'),
            onChangedDebounced: (value) => _searchCategory('books', value),
          ),
          SmartDebouncerTextField(
            delay: const Duration(milliseconds: 300),
            decoration: const InputDecoration(labelText: 'Search Movies'),
            onChangedDebounced: (value) => _searchCategory('movies', value),
          ),
          SmartDebouncerButton(
            delay: const Duration(milliseconds: 500),
            onPressed: () => submitAllSearches(),
            child: const Text('Search All'),
          ),
        ],
      ),
    );
  }
}
```

---

## Example App

See [`example/lib/main.dart`](example/lib/main.dart) for a complete Flutter demo that showcases:
- Core `Debouncer` with simulated API calls
- `SmartDebouncerTextField` for search input
- `SmartDebouncerButton` for protected submissions
- Real-time event logging

Run it with:

```bash
cd example
flutter run
```

---

## API Reference

### SmartDebouncer / Debouncer

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `delay` | `Duration` | required | Time to wait before executing |
| `leading` | `bool` | `false` | Execute on the leading edge |
| `trailing` | `bool` | `true` | Execute on the trailing edge |
| `maxWait` | `Duration?` | `null` | Maximum time to wait before forcing execution |
| `onError` | `Function?` | `null` | Error handler for callback exceptions |
| `onLeadingInvoke` | `Function?` | `null` | Called when leading edge executes |

**Methods:**
- `call(action)` - Schedule an action
- `cancel()` - Cancel pending action
- `flush()` - Execute pending action immediately
- `pause()` - Pause timers
- `resume()` - Resume timers
- `dispose()` - Clean up resources

**Properties:**
- `isActive` - Whether there's pending or running work
- `isPaused` - Whether timers are paused

### SmartThrottle

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `interval` | `Duration` | required | Minimum time between executions |
| `leading` | `bool` | `true` | Execute on the leading edge |
| `trailing` | `bool` | `true` | Execute on the trailing edge |
| `onError` | `Function?` | `null` | Error handler for callback exceptions |

**Methods:**
- `call(action)` - Schedule an action
- `cancel()` - Cancel pending action
- `flush()` - Execute pending action immediately
- `dispose()` - Clean up resources

### DebouncePool

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `defaultDelay` | `Duration?` | `300ms` | Default delay for new debouncers |
| `defaultLeading` | `bool` | `false` | Default leading setting |
| `defaultTrailing` | `bool` | `true` | Default trailing setting |
| `defaultMaxWait` | `Duration?` | `null` | Default maxWait setting |
| `ttl` | `Duration?` | `null` | Time-to-live for inactive debouncers |

**Methods:**
- `obtain(key, ...)` - Get or create a debouncer
- `call(key, action)` - Execute action with key's debouncer
- `cancel(key)` - Cancel pending work for key
- `flush(key)` - Flush pending work for key
- `disposeKey(key)` - Dispose specific debouncer
- `disposeAll()` - Dispose all debouncers

### DebouncedValue

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `initial` | `T` | required | Initial value |
| `delay` | `Duration` | required | Debounce delay |

**Methods:**
- `set(value)` - Set new value (debounced)
- `close()` - Close the stream

**Properties:**
- `value` - Current value (immediate)
- `stream` - Stream of debounced updates

### Stream Extensions

**debounceTime(duration)**
- Emits events only after the source has been silent for `duration`

**throttleTime(duration, {leading, trailing})**
- Emits at most one event per `duration`

### SmartDebouncerTextField

All standard `TextField` parameters plus:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `delay` | `Duration` | required | Debounce delay |
| `leading` | `bool` | `false` | Leading edge execution |
| `trailing` | `bool` | `true` | Trailing edge execution |
| `maxWait` | `Duration?` | `null` | Maximum wait time |
| `onChangedDebounced` | `ValueChanged<String>?` | `null` | Debounced change callback |

### SmartDebouncerButton

All standard `ElevatedButton` parameters plus:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `delay` | `Duration` | required | Debounce delay |
| `leading` | `bool` | `true` | Leading edge execution |
| `trailing` | `bool` | `false` | Trailing edge execution |
| `maxWait` | `Duration?` | `null` | Maximum wait time |

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for release notes.

## License

Distributed under the [MIT License](LICENSE).
