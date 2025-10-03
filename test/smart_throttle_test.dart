import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';

void main() {
  test('leading true trailing false throttles to first call', () {
    fakeAsync((async) {
      final throttle = SmartThrottle<int>(
        interval: const Duration(milliseconds: 100),
        leading: true,
        trailing: false,
      );

      var count = 0;
      throttle(() => ++count);
      async.elapse(const Duration(milliseconds: 10));
      throttle(() => ++count);
      async.elapse(const Duration(milliseconds: 200));
      throttle(() => ++count);
      async.elapse(const Duration(milliseconds: 1));
      expect(count, 2);
    });
  });

  test('leading false trailing true throttles to last call', () {
    fakeAsync((async) {
      final throttle = SmartThrottle<int>(
        interval: const Duration(milliseconds: 100),
        leading: false,
        trailing: true,
      );

      var count = 0;
      throttle(() => ++count);
      async.elapse(const Duration(milliseconds: 40));
      throttle(() => ++count);
      async.elapse(const Duration(milliseconds: 120));
      async.elapse(const Duration(milliseconds: 1));
      expect(count, 1);
    });
  });

  test('leading and trailing emit both edges when busy', () {
    fakeAsync((async) {
      final throttle = SmartThrottle<int>(
        interval: const Duration(milliseconds: 100),
      );

      var value = 0;
      throttle(() => ++value);
      async.elapse(const Duration(milliseconds: 20));
      throttle(() => ++value);
      async.elapse(const Duration(milliseconds: 120));
      throttle(() => ++value);
      async.elapse(const Duration(milliseconds: 120));
      expect(value, 3);
    });
  });

  test('cancel prevents trailing execution', () {
    fakeAsync((async) {
      final throttle = SmartThrottle<int>(interval: const Duration(milliseconds: 100));
      var count = 0;
      throttle(() => ++count);
      throttle.cancel();
      async.elapse(const Duration(milliseconds: 200));
      expect(count, 1);
    });
  });

  test('flush executes pending trailing action', () {
    fakeAsync((async) {
      final throttle = SmartThrottle<int>(interval: const Duration(milliseconds: 100));
      var value = 0;
      throttle(() => ++value);
      async.elapse(const Duration(milliseconds: 10));
      throttle.flush();
      expect(value, 1);
    });
  });
}
