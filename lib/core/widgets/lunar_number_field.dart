import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A numeric text field for a lunar day/month value, clamped to
/// [min]..[max] — replaces a long `DropdownButtonFormField` (scrolling
/// through up to 30 items is slow on mobile) with the numeric keypad
/// directly.
class LunarNumberField extends StatefulWidget {
  const LunarNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;

  /// Called with the value already clamped to [min]..[max].
  final ValueChanged<int> onChanged;

  @override
  State<LunarNumberField> createState() => _LunarNumberFieldState();
}

class _LunarNumberFieldState extends State<LunarNumberField> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.value}',
  );

  @override
  void didUpdateWidget(covariant LunarNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only overwrite the displayed text if it doesn't already represent
    // the current value — e.g. after `value` changed for some other
    // reason (a different field's change clamped this one). Comparing
    // the parsed number, not the raw string, avoids fighting the user's
    // cursor while they're still mid-keystroke on the same number.
    if (int.tryParse(_controller.text) != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final parsed = int.tryParse(raw);
    if (parsed == null) return;
    final clamped = parsed.clamp(widget.min, widget.max);
    widget.onChanged(clamped);
    if (clamped != parsed) {
      _controller.text = '$clamped';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(labelText: widget.label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: _commit,
    );
  }
}
