import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    debugNow = DateTime.now;
  });

  group('Debouncer', () {
    test('fires only once after delay for rapid calls', () async {
      final fake = FakeAsync();
      final completions = <Future<int?>>[];

      fake.run((async) {
        final debouncer = Debouncer<int>(
          delay: const Duration(milliseconds: 100),
        );

        var value = 0;
        completions.add(debouncer(() => ++value));
        async.elapse(const Duration(milliseconds: 20));
        completions.add(debouncer(() => ++value));
        async.elapse(const Duration(milliseconds: 20));
        completions.add(debouncer(() => ++value));

        expect(value, 0);
        async.elapse(const Duration(milliseconds: 100));
        expect(value, 1);
      });

      await Future.wait(completions);
    });

    test('cancel prevents pending action and completes futures', () {
      FakeAsync().run((async) {
        final debouncer = Debouncer<void>(
          delay: const Duration(milliseconds: 50),
        );

        var called = false;
        final future = debouncer(() {
          called = true;
        });

        debouncer.cancel();
        async.elapse(const Duration(milliseconds: 100));

        expect(called, isFalse);
        expect(future, completion(isNull));
      });
    });

    test('flush executes pending action immediately', () async {
      Future<void>? flushFuture;

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
        flushFuture = debouncer.flush();
        expect(callCount, 1);
      });

      await flushFuture;
    });
  });
}
