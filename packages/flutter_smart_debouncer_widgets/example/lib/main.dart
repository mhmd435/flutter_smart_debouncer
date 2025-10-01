import 'package:flutter/material.dart';
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';
import 'package:flutter_smart_debouncer_widgets/debounced_text_field.dart';

void main() {
  runApp(const DebouncerDemoApp());
}

class DebouncerDemoApp extends StatelessWidget {
  const DebouncerDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Debouncer Demo',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final SmartDebouncer<void> _autoSave = SmartDebouncer<void>(
    delay: const Duration(seconds: 2),
    leading: true,
    trailing: true,
    maxWait: const Duration(seconds: 6),
  );
  final SmartThrottle<void> _scrollThrottle = SmartThrottle<void>(
    interval: const Duration(milliseconds: 250),
  );
  final DebouncePool<void> _validationPool = DebouncePool<void>(
    defaultDelay: const Duration(milliseconds: 600),
  );
  final ScrollController _scrollController = ScrollController();

  String _searchStatus = 'Idle';
  String _autosaveStatus = 'Synced';
  String _scrollStatus = 'Stopped';
  String _emailStatus = 'Idle';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollThrottle(() async {
        setState(() {
          _scrollStatus = 'Scroll position ${_scrollController.offset.toStringAsFixed(1)}';
        });
      });
    });
  }

  @override
  void dispose() {
    _autoSave.dispose();
    _scrollThrottle.dispose();
    _validationPool.disposeAll();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String query) async {
    setState(() {
      _searchStatus = 'Searching "$query"…';
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _searchStatus = 'Results ready for "$query"';
    });
  }

  void _onDocumentEdited(String value) {
    setState(() {
      _autosaveStatus = 'Dirty';
    });
    _autoSave(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _autosaveStatus = 'Saved at ${TimeOfDay.now().format(context)}';
      });
    });
  }

  void _validateEmail(String value) {
    _validationPool.call('email', () async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _emailStatus = value.contains('@') ? 'Looks good!' : 'Missing @ symbol';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Debouncer Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DebouncedTextField(
              delay: const Duration(milliseconds: 350),
              leading: false,
              onChangedDebounced: _runSearch,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search…'),
            ),
            const SizedBox(height: 4),
            Text(_searchStatus),
            const Divider(height: 32),
            Text('Auto-save', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Type to auto-save…'),
              onChanged: _onDocumentEdited,
            ),
            const SizedBox(height: 4),
            Text(_autosaveStatus),
            const Divider(height: 32),
            Text('Form validation (per-key)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              onChanged: _validateEmail,
            ),
            const SizedBox(height: 4),
            Text(_emailStatus),
            const Divider(height: 32),
            Text('Scroll throttle', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: 100,
                itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
              ),
            ),
            Text(_scrollStatus),
          ],
        ),
      ),
    );
  }
}
