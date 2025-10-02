import '../src/core/smart_debouncer.dart';

export '../src/core/debounce_pool.dart';
export '../src/core/smart_debouncer.dart' show SmartDebouncer;

/// A convenient alias for [SmartDebouncer] that exposes the same API with a
/// shorter, expressive name for application code.
typedef Debouncer<T> = SmartDebouncer<T>;
