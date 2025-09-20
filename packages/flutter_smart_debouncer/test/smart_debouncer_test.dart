import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() {
    debugNow = DateTime.now;
  });

  test('leading only executes immediately and ignores trailing calls', () async {
    final futures = <Future<int?>>[];
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final debouncer = SmartDebouncer<int>(
        delay: const Duration(milliseconds: 100),
        leading: true,
        trailing: false,
      );

      var count = 0;
      final first = debouncer(() => ++count);
      futures.add(first);
      expect(count, 1);

      async.elapse(const Duration(milliseconds: 50));
      final second = debouncer(() => ++count);
      futures.add(second);
      expect(count, 1);

      async.elapse(const Duration(milliseconds: 60));
      final third = debouncer(() => ++count);
      futures.add(third);
      expect(count, 2);
    });

    final values = await Future.wait(futures);
    expect(values.first, 1);
    expect(values[1], 1);
    expect(values.last, 2);
  });

  test('trailing only executes once after delay', () async {
    final futures = <Future<int?>>[];
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final debouncer = SmartDebouncer<int>(
        delay: const Duration(milliseconds: 100),
      );

      var count = 0;
      futures.add(debouncer(() => ++count));
      futures.add(debouncer(() => ++count));
      expect(count, 0);

      async.elapse(const Duration(milliseconds: 100));
      expect(count, 1);
    });

    final values = await Future.wait(futures);
    expect(values, everyElement(1));
  });

  test('leading and trailing executes on both edges', () async {
    final futures = <Future<int?>>[];
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final debouncer = SmartDebouncer<int>(
        delay: const Duration(milliseconds: 100),
        leading: true,
        trailing: true,
      );

      var value = 0;
      futures.add(debouncer(() => ++value));
      expect(value, 1);

      async.elapse(const Duration(milliseconds: 50));
      futures.add(debouncer(() => ++value));
      async.elapse(const Duration(milliseconds: 50));
      expect(value, 1);

      async.elapse(const Duration(milliseconds: 50));
      expect(value, 2);
    });

    final values = await Future.wait(futures);
    expect(values.first, 1);
    expect(values.last, 2);
  });

  test('maxWait enforces execution cadence during rapid calls', () async {
    final futures = <Future<int?>>[];
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final debouncer = SmartDebouncer<int>(
        delay: const Duration(milliseconds: 100),
        leading: false,
        trailing: true,
        maxWait: const Duration(milliseconds: 250),
      );

      var calls = 0;
      Future<int?> tick() => debouncer(() => ++calls);

      for (var i = 0; i < 5; i++) {
        futures.add(tick());
        async.elapse(const Duration(milliseconds: 60));
      }

      expect(calls, 0);
      async.elapse(const Duration(milliseconds: 80));
      expect(calls, greaterThanOrEqualTo(1));
    });

    final results = await Future.wait(futures);
    expect(results.whereType<int?>().length, equals(results.length));
  });

  test('pause and resume preserves remaining delay', () async {
    Future<int?>? future;
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final debouncer = SmartDebouncer<int>(delay: const Duration(milliseconds: 100));

      var result = 0;
      future = debouncer(() => ++result);
      async.elapse(const Duration(milliseconds: 40));
      debouncer.pause();
      async.elapse(const Duration(milliseconds: 200));
      expect(result, 0);
      debouncer.resume();
      async.elapse(const Duration(milliseconds: 61));
      expect(result, 1);
    });

    final value = await future!;
    expect(value, 1);
  });

  test('onLeadingInvoke triggers on immediate execution', () async {
    var leadingCount = 0;
    Future<int?>? future;
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final debouncer = SmartDebouncer<int>(
        delay: const Duration(milliseconds: 100),
        leading: true,
        trailing: false,
        onLeadingInvoke: () => leadingCount++,
      );

      future = debouncer(() => 42);
      async.elapse(const Duration(milliseconds: 10));
    });

    expect(await future!, 42);
    expect(leadingCount, 1);
  });

  test('cancel prevents trailing execution', () async {
    Future<int?>? future;
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final debouncer = SmartDebouncer<int>(delay: const Duration(milliseconds: 50));

      var value = 0;
      future = debouncer(() => ++value);
      debouncer.cancel();
      async.elapse(const Duration(milliseconds: 50));
      expect(value, 0);
    });

    final result = await future!;
    expect(result, isNull);
  });

  test('flush executes immediately when idle', () async {
    Future<int?>? future;
    Future<int?>? flushFuture;
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final debouncer = SmartDebouncer<int>(delay: const Duration(milliseconds: 100));

      var count = 0;
      future = debouncer(() => ++count);
      async.elapse(const Duration(milliseconds: 20));
      flushFuture = debouncer.flush();
      expect(count, 1);
    });

    expect(await future!, 1);
    expect(await flushFuture!, 1);
  });

  test('flush waits for running action then executes pending one', () async {
    Future<void>? flushFuture;
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final debouncer = SmartDebouncer<void>(delay: const Duration(milliseconds: 100));

      final log = <String>[];
      final completer = Completer<void>();
      debouncer(() async {
        log.add('start');
        await completer.future;
        log.add('end');
      });

      async.elapse(const Duration(milliseconds: 10));
      flushFuture = debouncer.flush();
      log.add('flush called');
      debouncer(() {
        log.add('pending');
      });
      async.elapse(const Duration(milliseconds: 20));
      completer.complete();
      async.elapse(const Duration(milliseconds: 100));

      expect(log, ['start', 'flush called', 'end', 'pending']);
    });

    await flushFuture;
  });

  test('propagates async errors and calls onError', () async {
    Future<void>? future;
    Object? captured;
    StackTrace? capturedTrace;
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final debouncer = SmartDebouncer<void>(
        delay: const Duration(milliseconds: 10),
        onError: (error, stackTrace) {
          captured = error;
          capturedTrace = stackTrace;
        },
      );

      future = debouncer(() async {
        await Future<void>.value();
        throw StateError('boom');
      });
      async.elapse(const Duration(milliseconds: 20));
    });

    await expectLater(future, throwsA(isA<StateError>()));
    expect(captured, isA<StateError>());
    expect(capturedTrace, isNotNull);
  });
}
