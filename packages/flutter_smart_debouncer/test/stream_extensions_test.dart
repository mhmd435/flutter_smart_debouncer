import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';
import 'package:test/test.dart';

void main() {
  test('debounceTime emits last value after quiet period', () {
    fakeAsync((async) {
      final controller = StreamController<int>();
      final events = <int>[];
      controller.stream.debounceTime(const Duration(milliseconds: 50)).listen(events.add);

      controller.add(1);
      async.elapse(const Duration(milliseconds: 40));
      controller.add(2);
      async.elapse(const Duration(milliseconds: 60));
      expect(events, [2]);

      controller.close();
    });
  });

  test('throttleTime with leading emits first and trailing emits last', () {
    fakeAsync((async) {
      final controller = StreamController<int>();
      final events = <int>[];
      controller
          .stream
          .throttleTime(const Duration(milliseconds: 100), leading: true, trailing: true)
          .listen(events.add);

      controller.add(1);
      async.elapse(const Duration(milliseconds: 20));
      controller.add(2);
      async.elapse(const Duration(milliseconds: 120));
      controller.add(3);
      async.elapse(const Duration(milliseconds: 120));

      expect(events, [1, 2, 3]);
      controller.close();
    });
  });

  test('cancelling listener stops timers', () {
    fakeAsync((async) {
      final controller = StreamController<int>();
      final subscription = controller.stream.debounceTime(const Duration(milliseconds: 100)).listen((_) {});
      controller.add(1);
      async.elapse(const Duration(milliseconds: 10));
      subscription.cancel();
      async.elapse(const Duration(milliseconds: 200));
      expect(() {}, returnsNormally);
      controller.close();
    });
  });
}
