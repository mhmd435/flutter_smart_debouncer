import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';
import 'package:test/test.dart';

void main() {
  group('SmartDebouncer', () {
    test('leading only executes immediately and ignores trailing calls', () {
      FakeAsync().run((async) {
        final debouncer = SmartDebouncer<int>(
          delay: const Duration(milliseconds: 100),
          leading: true,
          trailing: false,
        );

        var count = 0;
        final first = debouncer(() => ++count);
        expect(count, 1);
        
        async.elapse(const Duration(milliseconds: 50));
        final second = debouncer(() => ++count);
        expect(count, 1);
        
        async.elapse(const Duration(milliseconds: 60));
        final third = debouncer(() => ++count);
        expect(count, 2);
      });
    });

    test('trailing only executes once after delay', () async {
      final fakeAsync = FakeAsync();
      final futures = <Future<int?>>[];
      
      fakeAsync.run((async) {
        final debouncer = SmartDebouncer<int>(
          delay: const Duration(milliseconds: 100),
          leading: false,
          trailing: true,
        );

        var count = 0;
        futures.add(debouncer(() => ++count));
        futures.add(debouncer(() => ++count));
        expect(count, 0);

        async.elapse(const Duration(milliseconds: 100));
        expect(count, 1);
      });
    });
  test('flush waits for running action then executes pending one', () async {
    Future<void>? flushFuture;
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now()).now();
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
      debugNow = () => async.getClock(DateTime.now()).now();
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
  });

}
