import 'package:fake_async/fake_async.dart';
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() {
    debugNow = DateTime.now;
  });

  test('DebouncedValue emits via stream after delay', () {
    fakeAsync((async) {
      debugNow = () => async.getClock(DateTime.now).now();
      final value = DebouncedValue<int>(0, delay: const Duration(milliseconds: 50));
      final outputs = <int>[];
      value.stream.listen(outputs.add);

      value.set(1);
      async.elapse(const Duration(milliseconds: 30));
      value.set(2);
      async.elapse(const Duration(milliseconds: 30));

      expect(outputs, [2]);
      value.close();
    });
  });

  test('DebouncedValue throws after close', () async {
    final value = DebouncedValue<int>(0, delay: const Duration(milliseconds: 10));
    await value.close();
    expect(() => value.set(1), throwsStateError);
  });
}
