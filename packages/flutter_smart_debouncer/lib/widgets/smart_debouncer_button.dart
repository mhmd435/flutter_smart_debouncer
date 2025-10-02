import 'package:flutter/material.dart';

import '../core/debouncer.dart';

/// A convenience button that protects against accidental double taps using a
/// [Debouncer].
class SmartDebouncerButton extends StatefulWidget {
  const SmartDebouncerButton({
    super.key,
    required this.child,
    required this.delay,
    this.onPressed,
    this.leading = true,
    this.trailing = false,
    this.maxWait,
    this.style,
  })  : assert(!delay.isNegative, 'delay must be >= 0'),
        assert(leading || trailing, 'Either leading or trailing must be enabled');

  /// The visual contents of the button.
  final Widget child;

  /// Called once the debounced action executes.
  final VoidCallback? onPressed;

  /// Debounce duration before firing [onPressed].
  final Duration delay;

  /// Whether to invoke [onPressed] immediately on the leading edge.
  final bool leading;

  /// Whether to invoke [onPressed] on the trailing edge.
  final bool trailing;

  /// Ensures a callback at least every [maxWait] duration if provided.
  final Duration? maxWait;

  /// Optional style forwarded to [ElevatedButton].
  final ButtonStyle? style;

  @override
  State<SmartDebouncerButton> createState() => _SmartDebouncerButtonState();
}

class _SmartDebouncerButtonState extends State<SmartDebouncerButton> {
  late Debouncer<void> _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = _createDebouncer();
  }

  @override
  void didUpdateWidget(SmartDebouncerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delay != widget.delay ||
        oldWidget.leading != widget.leading ||
        oldWidget.trailing != widget.trailing ||
        oldWidget.maxWait != widget.maxWait) {
      _debouncer.dispose();
      _debouncer = _createDebouncer();
    }
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  Debouncer<void> _createDebouncer() {
    return Debouncer<void>(
      delay: widget.delay,
      leading: widget.leading,
      trailing: widget.trailing,
      maxWait: widget.maxWait,
    );
  }

  Future<void> _handlePressed() async {
    final handler = widget.onPressed;
    if (handler == null) {
      return;
    }
    await _debouncer(() async {
      handler();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: widget.style,
      onPressed: widget.onPressed == null ? null : _handlePressed,
      child: widget.child,
    );
  }
}
