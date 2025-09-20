import 'dart:async';

import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';

Future<void> main() async {
  final debouncer = SmartDebouncer<void>(delay: const Duration(milliseconds: 300));
  final throttle = SmartThrottle<void>(interval: const Duration(milliseconds: 200));
  final pool = DebouncePool<void>(
    defaultDelay: const Duration(milliseconds: 400),
    ttl: const Duration(seconds: 5),
  );

  print('Type queries (Ctrl+C to exit):');
  final lines = Stream.periodic(const Duration(milliseconds: 150), (i) => 'query $i').take(5);

  await for (final query in lines) {
    await debouncer(() async {
      print('[debounce] searching for $query');
    });
  }

  print('Simulating autosave edits');
  for (var i = 0; i < 3; i++) {
    debouncer(() async {
      print('[autosave] commit revision $i');
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  print('Throttle scrolling');
  for (var i = 0; i < 5; i++) {
    await throttle(() async {
      print('[throttle] frame $i');
    });
  }

  print('Per-field validation');
  for (final field in ['email', 'username', 'email']) {
    await pool.call(field, () async {
      print('[pool] validating $field');
    });
  }

  final debouncedValue = DebouncedValue<String>('', delay: const Duration(milliseconds: 200));
  debouncedValue.stream.listen((value) => print('[value] $value'));
  debouncedValue.set('hello');
  debouncedValue.set('hello world');
  await Future<void>.delayed(const Duration(milliseconds: 300));
  await debouncedValue.close();
}
