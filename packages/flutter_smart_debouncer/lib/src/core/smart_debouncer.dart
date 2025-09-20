import 'dart:async';

import 'package:meta/meta.dart';

typedef DebounceCallback<T> = FutureOr<T> Function();

@visibleForTesting
DateTime Function() debugNow = DateTime.now;

/// A smart debouncer that coalesces bursts of calls into deterministic actions.
///
/// The debouncer supports leading/trailing execution, optional [maxWait],
/// pausing, flushing, and async-aware error handling.
class SmartDebouncer<T> {
  SmartDebouncer({
    required Duration delay,
    bool leading = false,
    bool trailing = true,
    Duration? maxWait,
    void Function(Object error, StackTrace st)? onError,
    void Function()? onLeadingInvoke,
  })  : assert(!delay.isNegative, 'delay must be >= 0'),
        assert(leading || trailing, 'Either leading or trailing must be enabled'),
        _delay = delay,
        _leading = leading,
        _trailing = trailing,
        _maxWait = maxWait,
        _onError = onError,
        _onLeadingInvoke = onLeadingInvoke;

  final Duration _delay;
  final bool _leading;
  final bool _trailing;
  final Duration? _maxWait;
  final void Function(Object error, StackTrace st)? _onError;
  final void Function()? _onLeadingInvoke;

  final List<Completer<T?>> _waiters = <Completer<T?>>[];

  Timer? _timer;
  Timer? _maxTimer;
  DebounceCallback<T>? _pendingAction;
  bool _isRunning = false;
  bool _isDisposed = false;
  bool _isPaused = false;
  Duration? _remainingDelay;
  Duration? _remainingMaxWait;
  DateTime? _delayStart;
  DateTime? _maxStart;
  Future<void>? _runningFuture;
  T? _lastResult;

  /// Schedules [action] according to debounce semantics.
  Future<T?> call(DebounceCallback<T> action) {
    _assertNotDisposed();

    final completer = Completer<T?>.sync();
    final bool shouldInvokeLeading =
        _leading && !_isPaused && !_isRunning && _timer == null && _pendingAction == null;

    if (shouldInvokeLeading) {
      _waiters.add(completer);
      _onLeadingInvoke?.call();
      final future = _invoke(action);
      _scheduleDelay();
      _startMaxTimerIfNeeded();
      return future;
    }

    if (_trailing) {
      _waiters.add(completer);
      _pendingAction = action;
      if (!_isPaused) {
        _scheduleDelay();
      } else {
        _remainingDelay = _delay;
      }
      _startMaxTimerIfNeeded();
    } else {
      if (!completer.isCompleted) {
        completer.complete(_lastResult);
      }
    }

    return completer.future;
  }

  /// Cancels any pending trailing invocation and completes waiting futures.
  void cancel() {
    if (_isDisposed) {
      return;
    }
    _pendingAction = null;
    _cancelDelayTimer();
    _cancelMaxTimer();
    _completeWaitersWith(null);
  }

  /// Flushes the pending trailing action, if any, executing it immediately.
  Future<T?> flush() async {
    _assertNotDisposed();

    if (_isRunning) {
      await _runningFuture;
    }

    final action = _pendingAction;
    if (action == null) {
      _cancelDelayTimer();
      return _lastResult;
    }

    _pendingAction = null;
    _cancelDelayTimer();
    return _invoke(action);
  }

  /// Pauses the timers, freezing the countdown.
  void pause() {
    if (_isPaused || _isDisposed) {
      return;
    }
    _isPaused = true;
    if (_timer != null && _delayStart != null) {
      final elapsed = debugNow().difference(_delayStart!);
      _remainingDelay = _delay - elapsed;
      if (_remainingDelay! <= Duration.zero) {
        _remainingDelay = Duration.zero;
      }
    }
    _cancelDelayTimer();

    if (_maxTimer != null && _maxStart != null && _maxWait != null) {
      final elapsed = debugNow().difference(_maxStart!);
      final remaining = _maxWait! - elapsed;
      _remainingMaxWait = remaining <= Duration.zero ? Duration.zero : remaining;
    }
    _cancelMaxTimer();
  }

  /// Resumes timers that were previously paused.
  void resume() {
    if (!_isPaused || _isDisposed) {
      return;
    }
    _isPaused = false;
    if (_remainingDelay != null) {
      _scheduleDelay(overrideDelay: _remainingDelay);
      _remainingDelay = null;
    }
    if (_remainingMaxWait != null) {
      _startMaxTimerIfNeeded(overrideDelay: _remainingMaxWait);
      _remainingMaxWait = null;
    }
  }

  /// Whether there is a pending invocation or one currently running.
  bool get isActive =>
      _isRunning || _timer != null || _pendingAction != null || _maxTimer != null;

  /// Whether timers are paused.
  bool get isPaused => _isPaused;

  /// Disposes the debouncer, cancelling timers and rejecting further calls.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    cancel();
    _isDisposed = true;
    _completeWaitersWithError(StateError('SmartDebouncer is disposed'));
  }

  void _assertNotDisposed() {
    if (_isDisposed) {
      throw StateError('SmartDebouncer is disposed');
    }
  }

  Future<T?> _invoke(DebounceCallback<T> action) {
    _pendingAction = null;
    _cancelDelayTimer();

    final localWaiters = List<Completer<T?>>.of(_waiters);
    _waiters.clear();

    _isRunning = true;
    final execution = Future<T?>.sync(() => action());

    _runningFuture = execution.then<void>((_) {}, onError: (_) {});
    _runningFuture = _runningFuture!.whenComplete(() {
      _isRunning = false;
      _runningFuture = null;
      if (_pendingAction == null) {
        _cancelMaxTimer();
      } else if (!_isPaused && _timer == null) {
        _scheduleDelay();
      }
    });

    return execution.then((value) {
      _lastResult = value;
      for (final waiter in localWaiters) {
        if (!waiter.isCompleted) {
          waiter.complete(value);
        }
      }
      return value;
    }, onError: (Object error, StackTrace stackTrace) {
      _onError?.call(error, stackTrace);
      for (final waiter in localWaiters) {
        if (!waiter.isCompleted) {
          waiter.completeError(error, stackTrace);
        }
      }
      throw error;
    });
  }

  void _scheduleDelay({Duration? overrideDelay}) {
    _cancelDelayTimer();
    final duration = overrideDelay ?? _delay;
    _delayStart = debugNow();
    _timer = Timer(duration < Duration.zero ? Duration.zero : duration, _handleDelayTimer);
  }

  void _handleDelayTimer() {
    _timer = null;
    if (_isPaused) {
      return;
    }
    final action = _pendingAction;
    if (!_trailing || action == null) {
      return;
    }
    _pendingAction = null;
    _invoke(action);
  }

  void _startMaxTimerIfNeeded({Duration? overrideDelay}) {
    if (_maxWait == null) {
      return;
    }
    if (_maxTimer != null) {
      return;
    }
    final duration = overrideDelay ?? _maxWait!;
    if (_isPaused) {
      _remainingMaxWait = duration;
      return;
    }
    _maxStart = debugNow();
    _maxTimer = Timer(duration < Duration.zero ? Duration.zero : duration, _handleMaxTimer);
  }

  void _handleMaxTimer() {
    _maxTimer = null;
    if (_isPaused) {
      _remainingMaxWait = Duration.zero;
      return;
    }
    final action = _pendingAction;
    if (action != null) {
      _pendingAction = null;
      _invoke(action);
    }
  }

  void _cancelDelayTimer() {
    _timer?.cancel();
    _timer = null;
    _delayStart = null;
  }

  void _cancelMaxTimer() {
    _maxTimer?.cancel();
    _maxTimer = null;
    _maxStart = null;
  }

  void _completeWaitersWith(T? value) {
    final localWaiters = List<Completer<T?>>.of(_waiters);
    _waiters.clear();
    for (final waiter in localWaiters) {
      if (!waiter.isCompleted) {
        waiter.complete(value);
      }
    }
  }

  void _completeWaitersWithError(Object error) {
    final localWaiters = List<Completer<T?>>.of(_waiters);
    _waiters.clear();
    for (final waiter in localWaiters) {
      if (!waiter.isCompleted) {
        waiter.completeError(error);
      }
    }
  }
}
