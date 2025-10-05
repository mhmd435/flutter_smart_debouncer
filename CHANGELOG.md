# Changelog

All notable changes to the `flutter_smart_debouncer` package will be documented in this file.

## [1.0.1] - 2024

### Fixed
- Fixed README.md formatting and improved documentation clarity
- Corrected package description and usage examples

### Documentation
- Enhanced README with better code examples
- Added more detailed usage instructions

---

## [1.0.0] - 2024

### 🎉 Initial Release

This is the first stable release of `flutter_smart_debouncer`, a unified package that combines production-ready debouncing and throttling utilities with polished Flutter widgets.

### ✨ Core Features

#### SmartDebouncer / Debouncer
- **Flexible execution modes**: Leading edge, trailing edge, or both
- **maxWait support**: Ensures execution happens at regular intervals even during continuous input
- **Pause/Resume**: Freeze and resume debounce timers while preserving remaining time
- **Cancel**: Cancel pending executions
- **Flush**: Execute pending actions immediately
- **Error handling**: Built-in error callback support
- **Type-safe**: Full generic type support for return values
- **Async-aware**: Properly handles async callbacks and prevents race conditions
- **Status checking**: `isActive` and `isPaused` properties for state inspection

#### SmartThrottle
- **Rate limiting**: Ensures callbacks execute at most once per interval
- **Leading/Trailing modes**: Execute on first call, last call, or both
- **Cancel and Flush**: Same control methods as SmartDebouncer
- **Error handling**: Built-in error callback support
- **Perfect for**: Scroll events, resize handlers, analytics tracking

#### DebouncePool
- **Key-based management**: Maintain multiple debouncers grouped by string keys
- **Lazy creation**: Debouncers are created on-demand
- **Custom configuration**: Override defaults per key
- **TTL support**: Automatically dispose inactive debouncers after a period
- **Bulk operations**: Cancel, flush, or dispose multiple debouncers
- **Perfect for**: Form auto-save, list item updates, dynamic UI elements

#### DebouncedValue
- **Reactive container**: Store values and emit updates through a stream
- **Stream-based**: Integrates seamlessly with StreamBuilder
- **Immediate access**: Get current value synchronously while updates are debounced
- **Perfect for**: Search queries, form validation, real-time filters

#### Stream Extensions
- **debounceTime**: Debounce any Dart stream
- **throttleTime**: Throttle any Dart stream with leading/trailing support
- **Composable**: Chain with other stream operators
- **Perfect for**: Text input streams, sensor data, WebSocket messages

### 🎨 Flutter Widgets

#### SmartDebouncerTextField
- **Drop-in replacement** for standard TextField
- **Dual callbacks**: `onChanged` (immediate) and `onChangedDebounced` (debounced)
- **All TextField features**: Supports all standard TextField parameters
- **Configurable**: Leading, trailing, maxWait support
- **Auto-managed**: Debouncer lifecycle handled automatically
- **Perfect for**: Search fields, form inputs, live validation

#### SmartDebouncerButton
- **Prevents double-taps**: Protects against accidental repeated presses
- **ElevatedButton wrapper**: Maintains all standard button features
- **Configurable delay**: Set custom debounce duration
- **Leading edge default**: Executes immediately on first press
- **Perfect for**: Form submissions, API calls, critical actions

### 📦 Package Structure

```
lib/
├── core/
│   └── debouncer.dart          # Main exports and Debouncer alias
├── src/
│   ├── core/
│   │   ├── smart_debouncer.dart    # Core debouncer implementation
│   │   ├── smart_throttle.dart     # Throttle implementation
│   │   └── debounce_pool.dart      # Pool management
│   ├── reactive/
│   │   └── debounced_value.dart    # Reactive value container
│   └── streams/
│       └── extensions.dart         # Stream extensions
├── widgets/
│   ├── smart_debouncer_text_field.dart
│   └── smart_debouncer_button.dart
└── flutter_smart_debouncer.dart    # Main entry point
```

### 🧪 Testing
- Comprehensive test coverage for all core features
- Uses `fake_async` for deterministic timer testing
- Tests for edge cases, error handling, and disposal
- Widget tests for Flutter components

### 📚 Documentation
- Detailed README with extensive examples
- API documentation for all public classes and methods
- Real-world usage examples
- Example Flutter app demonstrating all features

### 🔧 Technical Details
- **Minimum Dart SDK**: 3.0.0
- **Minimum Flutter SDK**: 3.0.0
- **Dependencies**: 
  - `flutter`: SDK
  - `meta`: ^1.10.0 (for annotations)
- **Dev Dependencies**:
  - `flutter_test`: SDK
  - `test`: ^1.24.0
  - `fake_async`: ^1.3.1
  - `flutter_lints`: ^3.0.1

### 🎯 Use Cases

This package is perfect for:
- **Search functionality**: Debounce search queries to reduce API calls
- **Form auto-save**: Save form fields independently with DebouncePool
- **Button protection**: Prevent accidental double-submissions
- **Scroll tracking**: Throttle scroll events for analytics
- **Live validation**: Debounce validation checks during typing
- **API rate limiting**: Control request frequency with throttling
- **Real-time filters**: Debounce filter updates in lists
- **Autosave editors**: Debounce content saves while typing

### 🚀 Getting Started

Add to your `pubspec.yaml`:
```yaml
dependencies:
  flutter_smart_debouncer: ^1.0.0
```

Import and use:
```dart
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';

final debouncer = Debouncer<void>(
  delay: const Duration(milliseconds: 300),
);

debouncer(() async {
  await performAction();
});
```

### 📝 Example App
- Complete demo app included in `example/` directory
- Demonstrates all major features
- Interactive event logging
- Material Design UI

### 🙏 Credits
- Inspired by Lodash's debounce and throttle utilities
- Built with Flutter best practices
- Designed for production use

---

## Future Roadmap

Potential features for future releases:
- Additional widget wrappers (Slider, Switch, etc.)
- Debounce/throttle decorators for methods
- Integration with state management solutions
- Performance monitoring and analytics
- More stream operators
