import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';

void main() {
  testWidgets('SmartDebouncerTextField notifies once user stops typing', (tester) async {
    final values = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartDebouncerTextField(
            delay: const Duration(milliseconds: 100),
            onChangedDebounced: values.add,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'H');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(find.byType(TextField), 'Hi');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(find.byType(TextField), 'Hi!');

    expect(values, isEmpty);

    await tester.pump(const Duration(milliseconds: 120));
    expect(values, ['Hi!']);
  });

  testWidgets('SmartDebouncerButton prevents rapid double taps', (tester) async {
    var pressed = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SmartDebouncerButton(
              delay: const Duration(milliseconds: 200),
              onPressed: () => pressed++,
              child: const Text('Submit'),
            ),
          ),
        ),
      ),
    );

    final button = find.byType(ElevatedButton);
    await tester.tap(button);
    await tester.pump();
    expect(pressed, 1);

    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 100));
    expect(pressed, 1);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(button);
    await tester.pump();
    expect(pressed, 2);
  });
}
