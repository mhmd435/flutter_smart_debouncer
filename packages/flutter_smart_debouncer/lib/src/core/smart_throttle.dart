import 'dart:async';

/// Signature for throttle callbacks.
typedef ThrottleCallback<T> = FutureOr<T> Function();

/// A throttler that limits how frequently callbacks may run.
class SmartThrottle<T> {
  SmartThrottle({
    required Duration interval,
    bool leading = true,
    bool trailing = true,
    void Function(Object error, StackTrace st)? onError,
  })  : assert(!interval.isNegative, 'interval must be >= 0'),
        assert(leading || trailing, 'Either leading or trailing must be enabled'),
        _interval = interval,
        _leading = leading,
        _trailing = trailing,
        _onError = onError;

  final Duration _interval;
  final bool _leading;
  final bool _trailing;
  final void Function(Object error, StackTrace st)? _onError;

  final List<Completer<T?>> _waiters = <Completer<T?>>[];
  Timer? _timer;
  ThrottleCallback<T>? _pendingAction;
  Future<void>? _runningFuture;
  bool _isRunning = false;
  bool _isDisposed = false;
  T? _lastResult;

  /// Schedules [action] according to the throttle configuration.
  Future<T?> call(ThrottleCallback<T> action) {
    _assertNotDisposed();

    final completer = Completer<T?>.sync();
    final bool shouldInvokeLeading = _leading && !_isRunning && _timer == null;

    if (shouldInvokeLeading) {
      _waiters.add(completer);
      final future = _invoke(action);
      _startTimer();
      return future;
    }

    if (_trailing) {
      _waiters.add(completer);
      _pendingAction = action;
      _startTimer();
    } else {
      if (!completer.isCompleted) {
        completer.complete(_lastResult);
      }
    }

    return completer.future;
  }

  /// Cancels pending trailing invocation without disposing the throttler.
  void cancel() {
    if (_isDisposed) {
      return;
    }
    _pendingAction = null;
    _timer?.cancel();
    _timer = null;
    _completeWaitersWith(null);
  }

  /// Executes the pending trailing invocation immediately, if any.
  Future<T?> flush() async {
    _assertNotDisposed();

    if (_isRunning) {
      await _runningFuture;
    }

    final action = _pendingAction;
    if (action == null) {
      return _lastResult;
    }
    _pendingAction = null;
    _timer?.cancel();
    _timer = null;
    return _invoke(action);
  }

  /// Disposes the throttler and rejects further calls.
  void dispose() {
    if (_isDisposed) {
      return;
    }
    cancel();
    _isDisposed = true;
    _completeWaitersWithError(StateError('SmartThrottle is disposed'));
  }

  void _startTimer() {
    _timer ??= Timer(_interval, _handleTimer);
  }

  void _handleTimer() {
    _timer = null;
    final action = _pendingAction;
    if (!_trailing || action == null) {
      return;
    }
    _pendingAction = null;
    _invoke(action);
  }

  Future<T?> _invoke(ThrottleCallback<T> action) {
    final localWaiters = List<Completer<T?>>.of(_waiters);
    _waiters.clear();

    _isRunning = true;
    final execution = Future<T?>.sync(() => action());
    _runningFuture = execution.then<void>((_) {}, onError: (_) {});
    _runningFuture = _runningFuture!.whenComplete(() {
      _isRunning = false;
      _runningFuture = null;
      if (_timer == null && _pendingAction != null) {
        _startTimer();
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

  void _assertNotDisposed() {
    if (_isDisposed) {
      throw StateError('SmartThrottle is disposed');
    }
  }
}
