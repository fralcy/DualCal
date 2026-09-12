import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/providers/calendar_provider.dart';
import 'desktop_landscape_calendar_screen.dart';
import 'mobile_portrait_calendar_screen.dart';
import 'modals/event_editor_modal.dart';
import 'modals/settings_modal.dart';
import 'responsive_screen.dart';

/// Keyboard shortcuts (mainly useful on desktop/web, harmless elsewhere):
/// arrow keys move the selected day, Page Up/Down change month, Home or T
/// jumps to today, Enter adds a note on the selected day, Escape opens
/// settings.
class ResponsiveCalendarScreen extends StatefulWidget {
  const ResponsiveCalendarScreen({super.key});

  @override
  State<ResponsiveCalendarScreen> createState() =>
      _ResponsiveCalendarScreenState();
}

class _ResponsiveCalendarScreenState extends State<ResponsiveCalendarScreen> {
  final _focusNode = FocusNode(debugLabel: 'ResponsiveCalendarScreen');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final calendar = context.read<CalendarProvider>();
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        calendar.selectDate(
          calendar.selectedDate.subtract(const Duration(days: 1)),
        );
      case LogicalKeyboardKey.arrowRight:
        calendar.selectDate(
          calendar.selectedDate.add(const Duration(days: 1)),
        );
      case LogicalKeyboardKey.arrowUp:
        calendar.selectDate(
          calendar.selectedDate.subtract(const Duration(days: 7)),
        );
      case LogicalKeyboardKey.arrowDown:
        calendar.selectDate(
          calendar.selectedDate.add(const Duration(days: 7)),
        );
      case LogicalKeyboardKey.pageUp:
        calendar.goToPreviousMonth();
      case LogicalKeyboardKey.pageDown:
        calendar.goToNextMonth();
      case LogicalKeyboardKey.home:
      case LogicalKeyboardKey.keyT:
        calendar.goToToday();
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        showEventEditorModal(context, initialDate: calendar.selectedDate);
      case LogicalKeyboardKey.escape:
        showSettingsModal(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: const ResponsiveScreen(
        mobileBuilder: _buildMobile,
        desktopBuilder: _buildDesktop,
      ),
    );
  }

  static Widget _buildMobile(BuildContext context) =>
      const MobilePortraitCalendarScreen();

  static Widget _buildDesktop(BuildContext context) =>
      const DesktopLandscapeCalendarScreen();
}
