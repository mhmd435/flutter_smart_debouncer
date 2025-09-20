library flutter_smart_debouncer_widgets;

import 'package:flutter/material.dart';
import 'package:flutter_smart_debouncer/flutter_smart_debouncer.dart';

/// A [TextField] that debounces the [onChangedDebounced] callback.
class DebouncedTextField extends StatefulWidget {
  const DebouncedTextField({
    super.key,
    required this.delay,
    this.leading = false,
    this.trailing = true,
    this.maxWait,
    this.onChangedDebounced,
    this.onChanged,
    this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.style,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.obscureText = false,
    this.enabled,
    this.minLines,
    this.maxLines = 1,
    this.onSubmitted,
  })  : assert(!delay.isNegative, 'delay must be >= 0'),
        assert(leading || trailing, 'Either leading or trailing must be enabled');

  /// Debounce duration before firing [onChangedDebounced].
  final Duration delay;

  /// Whether to invoke the debounced callback immediately on the leading edge.
  final bool leading;

  /// Whether to invoke the debounced callback on the trailing edge.
  final bool trailing;

  /// Ensures a callback at least every [maxWait] duration if provided.
  final Duration? maxWait;

  /// Debounced change callback.
  final ValueChanged<String>? onChangedDebounced;

  /// Immediate change callback forwarded to the underlying [TextField].
  final ValueChanged<String>? onChanged;

  /// Controller for the underlying [TextField].
  final TextEditingController? controller;

  /// Focus node for the underlying [TextField].
  final FocusNode? focusNode;

  /// Decoration for the text field.
  final InputDecoration? decoration;

  /// Keyboard type for the field.
  final TextInputType? keyboardType;

  /// Text input action.
  final TextInputAction? textInputAction;

  /// Style for the entered text.
  final TextStyle? style;

  /// Alignment for the text.
  final TextAlign textAlign;

  /// Whether the field autofocuses.
  final bool autofocus;

  /// Whether the field obscures text.
  final bool obscureText;

  /// Whether the field is enabled.
  final bool? enabled;

  /// Minimum lines for the field.
  final int? minLines;

  /// Maximum lines for the field.
  final int? maxLines;

  /// Callback when the user submits the field.
  final ValueChanged<String>? onSubmitted;

  @override
  State<DebouncedTextField> createState() => _DebouncedTextFieldState();
}

class _DebouncedTextFieldState extends State<DebouncedTextField> {
  late SmartDebouncer<void> _debouncer;

  @override
  void initState() {
    super.initState();
    _debouncer = _createDebouncer();
  }

  @override
  void didUpdateWidget(DebouncedTextField oldWidget) {
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

  SmartDebouncer<void> _createDebouncer() {
    return SmartDebouncer<void>(
      delay: widget.delay,
      leading: widget.leading,
      trailing: widget.trailing,
      maxWait: widget.maxWait,
    );
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    final debounced = widget.onChangedDebounced;
    if (debounced != null) {
      _debouncer(() async {
        debounced(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      style: widget.style,
      textAlign: widget.textAlign,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      onChanged: _handleChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
