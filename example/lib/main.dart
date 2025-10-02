import 'package:flutter/material.dart';
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';

void main() {
  runApp(const DebouncerExampleApp());
}

class DebouncerExampleApp extends StatelessWidget {
  const DebouncerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_smart_debouncer',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const DebouncerDemoPage(),
    );
  }
}

class DebouncerDemoPage extends StatefulWidget {
  const DebouncerDemoPage({super.key});

  @override
  State<DebouncerDemoPage> createState() => _DebouncerDemoPageState();
}

class _DebouncerDemoPageState extends State<DebouncerDemoPage> {
  late final Debouncer<void> _apiDebouncer = Debouncer<void>(
    delay: const Duration(milliseconds: 350),
    maxWait: const Duration(seconds: 1),
  );

  final List<String> _log = <String>[];
  int _submissionCount = 0;

  @override
  void dispose() {
    _apiDebouncer.dispose();
    super.dispose();
  }

  void _appendLog(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _log.insert(0, message);
    });
  }

  void _handleManualSearch(String query) {
    _appendLog('Input changed to "$query" (core Debouncer queued)');
    _apiDebouncer(() async {
      _appendLog('Calling API for "$query"...');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _appendLog('API call for "$query" finished');
    });
  }

  void _handleWidgetSearch(String value) {
    _appendLog('SmartDebouncerTextField emitted "$value"');
  }

  void _handleProtectedSubmit() {
    setState(() {
      _submissionCount++;
    });
    _appendLog('SmartDebouncerButton accepted tap #$_submissionCount');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart debouncing demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Function-level debouncing', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Search (manual Debouncer)',
            ),
            onChanged: _handleManualSearch,
          ),
          const SizedBox(height: 24),
          Text('Widget-level debouncing', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SmartDebouncerTextField(
            delay: const Duration(milliseconds: 250),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Search (SmartDebouncerTextField)',
            ),
            onChangedDebounced: _handleWidgetSearch,
          ),
          const SizedBox(height: 16),
          SmartDebouncerButton(
            delay: const Duration(milliseconds: 700),
            onPressed: _handleProtectedSubmit,
            child: const Text('Submit once'),
          ),
          const SizedBox(height: 8),
          Text('Accepted submissions: $_submissionCount'),
          const SizedBox(height: 24),
          Text('Event log', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_log.isEmpty)
            const Text('Interact with the widgets to populate the log.')
          else
            ..._log.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(entry),
                )),
        ],
      ),
    );
  }
}
