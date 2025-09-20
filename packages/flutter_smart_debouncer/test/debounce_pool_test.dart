import 'package:fake_async/fake_async.dart';
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() {
    debugNow = DateTime.now;
  });

  test('per-key isolation', () async {
    Future<int?>? aFuture;
    Future<int?>? bFuture;
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final pool = DebouncePool<int>(defaultDelay: const Duration(milliseconds: 100));

      var aCount = 0;
      var bCount = 0;
      aFuture = pool.call('a', () => ++aCount);
      bFuture = pool.call('b', () => ++bCount);

      async.elapse(const Duration(milliseconds: 120));
      expect(aCount, 1);
      expect(bCount, 1);
    });

    expect(await aFuture!, 1);
    expect(await bFuture!, 1);
  });

  test('ttl eviction disposes idle debouncers', () {
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final pool = DebouncePool<void>(
        defaultDelay: const Duration(milliseconds: 10),
        ttl: const Duration(milliseconds: 50),
      );

      final first = pool.obtain('key');
      async.elapse(const Duration(milliseconds: 60));
      final second = pool.obtain('key');
      expect(identical(first, second), isFalse);
    });
  });

  test('cancel and flush operate per key', () async {
    Future<int?>? future;
    Future<int?>? flushed;
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final pool = DebouncePool<int>(defaultDelay: const Duration(milliseconds: 100));

      var value = 0;
      future = pool.call('foo', () => ++value);
      pool.cancel('foo');
      async.elapse(const Duration(milliseconds: 150));
      expect(value, 0);

      future = pool.call('foo', () => ++value);
      async.elapse(const Duration(milliseconds: 10));
      flushed = pool.flush('foo');
      async.elapse(const Duration(milliseconds: 1));
      expect(value, 1);
    });

    expect(await future!, 1);
    expect(await flushed!, 1);
  });
}
