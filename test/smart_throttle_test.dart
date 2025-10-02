import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';

void main() {
  test('leading true trailing false throttles to first call', () async {
    final futures = <Future<int?>>[];
    fakeAsync((async) {
      final throttle = SmartThrottle<int>(
        interval: const Duration(milliseconds: 100),
        leading: true,
        trailing: false,
      );

      var count = 0;
      futures.add(throttle(() => ++count));
      async.elapse(const Duration(milliseconds: 10));
      futures.add(throttle(() => ++count));
      async.elapse(const Duration(milliseconds: 200));
      futures.add(throttle(() => ++count));
    });

    final results = await Future.wait(futures);
    expect(results, [1, 1, 2]);
  });

  test('leading false trailing true throttles to last call', () async {
    final futures = <Future<int?>>[];
    fakeAsync((async) {
      final throttle = SmartThrottle<int>(
        interval: const Duration(milliseconds: 100),
        leading: false,
        trailing: true,
      );

      var count = 0;
      futures.add(throttle(() => ++count));
      async.elapse(const Duration(milliseconds: 40));
      futures.add(throttle(() => ++count));
      async.elapse(const Duration(milliseconds: 120));
    });

    final results = await Future.wait(futures);
    expect(results.first, 2);
    expect(results.last, 2);
  });

  test('leading and trailing emit both edges when busy', () async {
    final futures = <Future<int?>>[];
    fakeAsync((async) {
      final throttle = SmartThrottle<int>(
        interval: const Duration(milliseconds: 100),
      );

      var value = 0;
      futures.add(throttle(() => ++value));
      async.elapse(const Duration(milliseconds: 20));
      futures.add(throttle(() => ++value));
      async.elapse(const Duration(milliseconds: 120));
      futures.add(throttle(() => ++value));
      async.elapse(const Duration(milliseconds: 120));
    });

    final results = await Future.wait(futures);
    expect(results.first, 1);
    expect(results[1], anyOf(1, 2));
    expect(results.last, 3);
  });

  test('cancel prevents trailing execution', () async {
    Future<int?>? future;
    fakeAsync((async) {
      final throttle = SmartThrottle<int>(interval: const Duration(milliseconds: 100));
      var count = 0;
      future = throttle(() => ++count);
      throttle.cancel();
      async.elapse(const Duration(milliseconds: 200));
      expect(count, 1);
    });

    expect(await future!, 1);
  });

  test('flush executes pending trailing action', () async {
    Future<int?>? future;
    fakeAsync((async) {
      final throttle = SmartThrottle<int>(interval: const Duration(milliseconds: 100));
      var value = 0;
      throttle(() => ++value);
      async.elapse(const Duration(milliseconds: 10));
      future = throttle.flush();
      expect(value, 1);
    });

    expect(await future!, 1);
  });
}
