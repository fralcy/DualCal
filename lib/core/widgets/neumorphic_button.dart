import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import 'neumorphic_container.dart';

/// A tappable [NeumorphicContainer] — raised at rest, flat/tinted while
/// pressed, matching soft-UI button conventions.
class NeumorphicButton extends StatefulWidget {
  const NeumorphicButton({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.all(10),
    this.borderRadius = 14,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  /// Forces the pressed/inset look even when not actively being tapped —
  /// used to show a persistent selection (e.g. the active theme swatch).
  final bool selected;

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressing = true),
      onTapCancel: () => setState(() => _pressing = false),
      onTapUp: (_) => setState(() => _pressing = false),
      child: NeumorphicContainer(
        padding: widget.padding,
        borderRadius: widget.borderRadius,
        pressed: widget.selected || _pressing,
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: context.watch<SettingsProvider>().themeConfig.textPrimary,
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              color: context.watch<SettingsProvider>().themeConfig.textPrimary,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
