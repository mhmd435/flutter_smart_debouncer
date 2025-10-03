import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';
import 'package:flutter_smart_debouncer/src/core/debounce_pool.dart';
import 'package:flutter_smart_debouncer/src/core/smart_debouncer.dart' as debouncer;

void main() {
  tearDown(() {
    debouncer.debugNow = () => DateTime.now();
  });

  test('per-key isolation', () {
    fakeAsync((async) {
      final clock = async.getClock(DateTime.now());
      debouncer.debugNow = () => clock.now();
      final pool = DebouncePool<int>(defaultDelay: const Duration(milliseconds: 100));

      var aCount = 0;
      var bCount = 0;
      pool.call('a', () => ++aCount);
      pool.call('b', () => ++bCount);

      async.elapse(const Duration(milliseconds: 120));
      expect(aCount, 1);
      expect(bCount, 1);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1));
    });
  });

  test('ttl eviction disposes idle debouncers', () {
    fakeAsync((async) {
      final clock = async.getClock(DateTime.now());
      debouncer.debugNow = () => clock.now();
      final pool = DebouncePool<void>(
        defaultDelay: const Duration(milliseconds: 10),
        ttl: const Duration(milliseconds: 50),
      );

      final first = pool.obtain('key');
      async.elapse(const Duration(milliseconds: 60));
      final second = pool.obtain('key');
      expect(identical(first, second), isFalse);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1));
    });
  });

  test('cancel and flush operate per key', () {
    fakeAsync((async) {
      final clock = async.getClock(DateTime.now());
      debouncer.debugNow = () => clock.now();
      final pool = DebouncePool<int>(defaultDelay: const Duration(milliseconds: 100));

      var value = 0;
      pool.call('foo', () => ++value);
      pool.cancel('foo');
      async.elapse(const Duration(milliseconds: 150));
      expect(value, 0);

      pool.call('foo', () => ++value);
      async.elapse(const Duration(milliseconds: 10));
      pool.flush('foo');
      async.elapse(const Duration(milliseconds: 1));
      expect(value, 1);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1));
    });
  });
}
