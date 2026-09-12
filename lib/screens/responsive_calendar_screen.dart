import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/providers/calendar_provider.dart';
import 'desktop_landscape_calendar_screen.dart';
import 'mobile_portrait_calendar_screen.dart';
import 'modals/day_detail_modal.dart';
import 'modals/event_editor_modal.dart';
import 'modals/settings_modal.dart';
import 'modals/shortcuts_help_modal.dart';
import 'responsive_screen.dart';

/// Keyboard shortcuts (mainly useful on desktop/web, harmless elsewhere):
/// arrow keys move the selected day (up/down by a week), Page Up/Down
/// change month, Shift+Page Up/Down change year, Home or T jumps to today,
/// Enter adds a new note on the selected day, Space opens that day's detail
/// (view/edit/delete existing events), S opens settings, and ? opens a
/// shortcuts help sheet. None of these collide with a browser/OS-reserved
/// combo (e.g. Ctrl+PageUp/PageDown, which switches browser tabs, is
/// deliberately avoided in favor of Shift+PageUp/PageDown for year).
class ResponsiveCalendarScreen extends StatelessWidget {
  const ResponsiveCalendarScreen({super.key});

  void _openDayDetail(BuildContext context, CalendarProvider calendar) {
    final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));
    if (isDesktop) {
      // The day-detail panel is always visible on desktop already — nothing
      // to open. (A future improvement could shift focus into the panel.)
      return;
    }
    showDayDetailModal(context, calendar.selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            const _MoveSelectionIntent(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            const _MoveSelectionIntent(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const _MoveSelectionIntent(-7),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const _MoveSelectionIntent(7),
        const SingleActivator(LogicalKeyboardKey.pageUp):
            const _ChangeMonthIntent(-1),
        const SingleActivator(LogicalKeyboardKey.pageDown):
            const _ChangeMonthIntent(1),
        const SingleActivator(LogicalKeyboardKey.pageUp, shift: true):
            const _ChangeYearIntent(-1),
        const SingleActivator(LogicalKeyboardKey.pageDown, shift: true):
            const _ChangeYearIntent(1),
        const SingleActivator(LogicalKeyboardKey.home): const _GoTodayIntent(),
        const SingleActivator(LogicalKeyboardKey.keyT): const _GoTodayIntent(),
        const SingleActivator(LogicalKeyboardKey.enter): const _QuickAddIntent(),
        const SingleActivator(LogicalKeyboardKey.numpadEnter):
            const _QuickAddIntent(),
        const SingleActivator(LogicalKeyboardKey.space):
            const _OpenDayDetailIntent(),
        const SingleActivator(LogicalKeyboardKey.keyS):
            const _OpenSettingsIntent(),
        // Shift+"/" is bound two ways: browsers/web typically report the
        // produced character key directly as LogicalKeyboardKey.question
        // (so the base-key-plus-shift chord below never matches there),
        // while native desktop platforms report the physical "/" key with
        // a shift modifier instead — covering both makes "?" work
        // everywhere regardless of keyboard layout.
        const SingleActivator(LogicalKeyboardKey.question):
            const _ShowShortcutHelpIntent(),
        const SingleActivator(LogicalKeyboardKey.slash, shift: true):
            const _ShowShortcutHelpIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _MoveSelectionIntent: CallbackAction<_MoveSelectionIntent>(
            onInvoke: (intent) {
              final calendar = context.read<CalendarProvider>();
              calendar.selectDate(
                calendar.selectedDate.add(Duration(days: intent.days)),
              );
              return null;
            },
          ),
          _ChangeMonthIntent: CallbackAction<_ChangeMonthIntent>(
            onInvoke: (intent) {
              final calendar = context.read<CalendarProvider>();
              if (intent.months < 0) {
                calendar.goToPreviousMonth();
              } else {
                calendar.goToNextMonth();
              }
              return null;
            },
          ),
          _ChangeYearIntent: CallbackAction<_ChangeYearIntent>(
            onInvoke: (intent) {
              final calendar = context.read<CalendarProvider>();
              final current = calendar.visibleMonth;
              calendar.selectDate(
                DateTime(current.year + intent.years, current.month, 1),
              );
              return null;
            },
          ),
          _GoTodayIntent: CallbackAction<_GoTodayIntent>(
            onInvoke: (_) {
              context.read<CalendarProvider>().goToToday();
              return null;
            },
          ),
          _QuickAddIntent: CallbackAction<_QuickAddIntent>(
            onInvoke: (_) {
              final calendar = context.read<CalendarProvider>();
              showEventEditorModal(context, initialDate: calendar.selectedDate);
              return null;
            },
          ),
          _OpenDayDetailIntent: CallbackAction<_OpenDayDetailIntent>(
            onInvoke: (_) {
              _openDayDetail(context, context.read<CalendarProvider>());
              return null;
            },
          ),
          _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
            onInvoke: (_) {
              showSettingsModal(context);
              return null;
            },
          ),
          _ShowShortcutHelpIntent: CallbackAction<_ShowShortcutHelpIntent>(
            onInvoke: (_) {
              showShortcutsHelpModal(context);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: const ResponsiveScreen(
            mobileBuilder: _buildMobile,
            desktopBuilder: _buildDesktop,
          ),
        ),
      ),
    );
  }

  static Widget _buildMobile(BuildContext context) =>
      const MobilePortraitCalendarScreen();

  static Widget _buildDesktop(BuildContext context) =>
      const DesktopLandscapeCalendarScreen();
}

/// Moves the selected day by [days] (negative = backward).
class _MoveSelectionIntent extends Intent {
  const _MoveSelectionIntent(this.days);
  final int days;
}

/// Changes the visible month by [months] (negative = backward).
class _ChangeMonthIntent extends Intent {
  const _ChangeMonthIntent(this.months);
  final int months;
}

/// Changes the visible year by [years] (negative = backward).
class _ChangeYearIntent extends Intent {
  const _ChangeYearIntent(this.years);
  final int years;
}

class _GoTodayIntent extends Intent {
  const _GoTodayIntent();
}

/// Quick-adds a new event on the selected day.
class _QuickAddIntent extends Intent {
  const _QuickAddIntent();
}

/// Opens the selected day's detail (existing events) for viewing/editing.
class _OpenDayDetailIntent extends Intent {
  const _OpenDayDetailIntent();
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

class _ShowShortcutHelpIntent extends Intent {
  const _ShowShortcutHelpIntent();
}
