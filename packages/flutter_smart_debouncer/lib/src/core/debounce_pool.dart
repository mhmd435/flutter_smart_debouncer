import 'dart:async';

import 'smart_debouncer.dart';

/// Maintains lazily created [SmartDebouncer] instances grouped by string keys.
///
/// Debouncers are reused per key and can be automatically evicted after a
/// period of inactivity by setting [ttl].
class DebouncePool<T> {
  DebouncePool({
    Duration? defaultDelay,
    bool defaultLeading = false,
    bool defaultTrailing = true,
    Duration? defaultMaxWait,
    Duration? ttl,
  })  : _defaultDelay = defaultDelay ?? const Duration(milliseconds: 300),
        _defaultLeading = defaultLeading,
        _defaultTrailing = defaultTrailing,
        _defaultMaxWait = defaultMaxWait,
        _ttl = ttl;

  final Duration _defaultDelay;
  final bool _defaultLeading;
  final bool _defaultTrailing;
  final Duration? _defaultMaxWait;
  final Duration? _ttl;

  final Map<String, _PoolEntry<T>> _entries = <String, _PoolEntry<T>>{};

  /// Obtains the debouncer associated with [key], creating one if necessary.
  SmartDebouncer<T> obtain(
    String key, {
    Duration? delay,
    bool? leading,
    bool? trailing,
    Duration? maxWait,
  }) {
    final requestedDelay = delay ?? _defaultDelay;
    final requestedLeading = leading ?? _defaultLeading;
    final requestedTrailing = trailing ?? _defaultTrailing;
    final requestedMaxWait = maxWait ?? _defaultMaxWait;

    final entry = _entries[key];
    if (entry != null &&
        entry.delay == requestedDelay &&
        entry.leading == requestedLeading &&
        entry.trailing == requestedTrailing &&
        entry.maxWait == requestedMaxWait) {
      entry.touch(_ttl);
      return entry.debouncer;
    }

    entry?.dispose();
    final debouncer = SmartDebouncer<T>(
      delay: requestedDelay,
      leading: requestedLeading,
      trailing: requestedTrailing,
      maxWait: requestedMaxWait,
    );
    final newEntry = _PoolEntry<T>(debouncer, requestedDelay, requestedLeading, requestedTrailing, requestedMaxWait);
    _entries[key] = newEntry;
    newEntry.touch(_ttl, onExpire: () => disposeKey(key));
    return debouncer;
  }

  /// Invokes the debouncer associated with [key].
  Future<T?> call(String key, DebounceCallback<T> action) {
    final debouncer = obtain(key);
    final entry = _entries[key];
    entry?.touch(_ttl, onExpire: () => disposeKey(key));
    return debouncer(action);
  }

  /// Cancels pending work for [key] without disposing the debouncer.
  void cancel(String key) {
    final entry = _entries[key];
    entry?.debouncer.cancel();
    entry?.touch(_ttl, onExpire: () => disposeKey(key));
  }

  /// Flushes pending work for [key], executing it immediately.
  Future<T?> flush(String key) {
    final entry = _entries[key];
    if (entry == null) {
      return Future<T?>.value(null);
    }
    entry.touch(_ttl, onExpire: () => disposeKey(key));
    return entry.debouncer.flush();
  }

  /// Disposes the debouncer associated with [key].
  void disposeKey(String key) {
    final entry = _entries.remove(key);
    entry?.dispose();
  }

  /// Disposes all debouncers and clears the pool.
  void disposeAll() {
    final keys = List<String>.of(_entries.keys);
    for (final key in keys) {
      disposeKey(key);
    }
  }
}

class _PoolEntry<T> {
  _PoolEntry(this.debouncer, this.delay, this.leading, this.trailing, this.maxWait);

  final SmartDebouncer<T> debouncer;
  final Duration delay;
  final bool leading;
  final bool trailing;
  final Duration? maxWait;
  Timer? _ttlTimer;

  void touch(Duration? ttl, {VoidCallback? onExpire}) {
    _ttlTimer?.cancel();
    if (ttl == null) {
      return;
    }
    _ttlTimer = Timer(ttl, () {
      onExpire?.call();
    });
  }

  void dispose() {
    _ttlTimer?.cancel();
    debouncer.dispose();
  }
}

typedef VoidCallback = void Function();
