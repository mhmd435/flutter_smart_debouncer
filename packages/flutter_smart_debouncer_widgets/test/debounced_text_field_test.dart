import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_smart_debouncer_widgets/debounced_text_field.dart';

void main() {
  testWidgets('emits debounced value after delay', (tester) async {
    var debouncedValue = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebouncedTextField(
            delay: const Duration(milliseconds: 200),
            onChangedDebounced: (value) => debouncedValue = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump(const Duration(milliseconds: 100));
    expect(debouncedValue, isEmpty);

    await tester.pump(const Duration(milliseconds: 100));
    expect(debouncedValue, 'hello');
  });

  testWidgets('leading true emits immediately', (tester) async {
    var debouncedValue = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DebouncedTextField(
            delay: const Duration(milliseconds: 200),
            leading: true,
            onChangedDebounced: (value) => debouncedValue = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hi');
    await tester.pump();
    expect(debouncedValue, 'hi');
  });
}
