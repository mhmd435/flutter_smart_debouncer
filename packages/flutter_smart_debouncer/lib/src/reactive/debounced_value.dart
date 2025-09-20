import 'dart:async';

import '../core/smart_debouncer.dart';

/// Stores a value and emits updates after a debounce delay.
class DebouncedValue<T> {
  DebouncedValue(T initial, {required Duration delay})
      : _value = initial,
        _controller = StreamController<T>.broadcast(sync: true),
        _debouncer = SmartDebouncer<void>(delay: delay);

  final SmartDebouncer<void> _debouncer;
  final StreamController<T> _controller;
  T _value;
  bool _isClosed = false;

  /// The current value.
  T get value => _value;

  /// A broadcast stream that emits debounced updates.
  Stream<T> get stream => _controller.stream;

  /// Sets the next value and schedules a debounced emission.
  void set(T next) {
    if (_isClosed) {
      throw StateError('DebouncedValue is closed');
    }
    _value = next;
    _debouncer(() {
      if (!_controller.isClosed) {
        _controller.add(_value);
      }
    });
  }

  /// Closes the debouncer and the underlying stream controller.
  Future<void> close() async {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    _debouncer.dispose();
    await _controller.close();
  }
}
