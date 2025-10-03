import 'package:fake_async/fake_async.dart';
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';
import 'package:flutter_smart_debouncer/src/core/smart_debouncer.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    debugNow = DateTime.now;
  });

  group('Debouncer', () {
    test('fires only once after delay for rapid calls', () {
      final fake = FakeAsync();

      fake.run((async) {
        final debouncer = Debouncer<int>(
          delay: const Duration(milliseconds: 100),
        );

        var value = 0;
        debouncer(() => ++value);
        async.elapse(const Duration(milliseconds: 20));
        debouncer(() => ++value);
        async.elapse(const Duration(milliseconds: 20));
        debouncer(() => ++value);

        expect(value, 0);
        async.elapse(const Duration(milliseconds: 100));
        expect(value, 1);
        // Ensure all microtasks complete before leaving the zone
        async.flushMicrotasks();
      });
    });

    test('cancel prevents pending action and completes futures', () {
      FakeAsync().run((async) {
        final debouncer = Debouncer<void>(
          delay: const Duration(milliseconds: 50),
        );

        var called = false;
        debouncer(() {
          called = true;
        });

        debouncer.cancel();
        async.elapse(const Duration(milliseconds: 100));
        async.flushMicrotasks();

        expect(called, isFalse);
      });
    });

    test('flush executes pending action immediately', () {
      FakeAsync().run((async) {
        debugNow = () => async.getClock(DateTime.now()).now();
        final debouncer = Debouncer<void>(
          delay: const Duration(milliseconds: 200),
        );

        var callCount = 0;
        debouncer(() async {
          callCount++;
        });

        async.elapse(const Duration(milliseconds: 50));
        debouncer.flush();
        expect(callCount, 1);
        async.flushMicrotasks();
      });
    });
  });
}
