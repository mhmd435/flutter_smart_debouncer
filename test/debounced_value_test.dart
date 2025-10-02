import 'package:fake_async/fake_async.dart';
import 'package:test/test.dart';

import '../lib/flutter_smart_debouncer.dart';

void main() {
  test('DebouncedValue emits via stream after delay', () {
    FakeAsync().run((async) {
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
