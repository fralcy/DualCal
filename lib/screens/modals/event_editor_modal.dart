import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/event_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/lunar_date.dart';
import '../../core/providers/event_provider.dart';
import '../../core/utils/lunar_calendar_service.dart';
import '../../models/calendar_event.dart';
import '../responsive_screen.dart';

/// Add/edit sheet for a note/event: title, date (solar picker or lunar
/// day/month/year + leap toggle), one-time vs yearly recurrence, reminder
/// offsets, and a category color tag.
///
/// Desktop/landscape shows this as a centered dialog (there's no reason to
/// anchor it to the bottom edge on a wide screen); mobile/portrait keeps
/// the bottom-sheet presentation.
Future<void> showEventEditorModal(
  BuildContext context, {
  required DateTime initialDate,
  CalendarEvent? existing,
}) {
  final isDesktop = ResponsiveScreen.isDesktopSize(MediaQuery.sizeOf(context));
  final form = _EventEditorForm(initialDate: initialDate, existing: existing);

  if (isDesktop) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
          child: form,
        ),
      ),
    );
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: form,
    ),
  );
}

class _EventEditorForm extends StatefulWidget {
  const _EventEditorForm({required this.initialDate, this.existing});

  final DateTime initialDate;
  final CalendarEvent? existing;

  @override
  State<_EventEditorForm> createState() => _EventEditorFormState();
}

class _EventEditorFormState extends State<_EventEditorForm> {
  static const _lunarService = LunarCalendarService();

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _reminderInputController;

  late EventDateType _dateType;
  late DateTime _solarDate;
  late int _lunarDay;
  late int _lunarMonth;
  late int _lunarYear;
  late bool _isLeapMonth;
  late EventRecurrence _recurrence;
  late List<int> _reminderDaysBefore;
  late TimeOfDay _reminderTime;
  late int _colorTag;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _reminderInputController = TextEditingController();
    _dateType = e?.dateType ?? EventDateType.solar;
    _solarDate = e?.solarDate ?? widget.initialDate;
    final initialLunar = _lunarService.solarToLunar(widget.initialDate);
    _lunarDay = e?.lunarDay ?? initialLunar.day;
    _lunarMonth = e?.lunarMonth ?? initialLunar.month;
    _lunarYear = e?.lunarYear ?? initialLunar.year;
    _isLeapMonth = e?.isLeapMonth ?? false;
    _recurrence = e?.recurrence ?? EventRecurrence.none;
    _reminderDaysBefore = List<int>.from(e?.reminderDaysBefore ?? const [1]);
    _reminderTime =
        TimeOfDay(hour: e?.reminderHour ?? 8, minute: e?.reminderMinute ?? 0);
    _colorTag = e?.colorTag ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reminderInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.existing == null ? l10n.addNote : l10n.editNote,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: l10n.titleLabel),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.titleRequired : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: l10n.descriptionLabel),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SegmentedButton<EventDateType>(
                  segments: [
                    ButtonSegment(
                      value: EventDateType.solar,
                      label: Text(l10n.dateTypeSolar),
                    ),
                    ButtonSegment(
                      value: EventDateType.lunar,
                      label: Text(l10n.dateTypeLunar),
                    ),
                  ],
                  selected: {_dateType},
                  onSelectionChanged: (s) => setState(() {
                    _dateType = s.first;
                    // weekly/quarterly only make sense for a solar-anchored
                    // event — reset to something valid when switching away.
                    if (_dateType != EventDateType.solar &&
                        (_recurrence == EventRecurrence.weekly ||
                            _recurrence == EventRecurrence.quarterly)) {
                      _recurrence = EventRecurrence.none;
                    }
                  }),
                ),
                const SizedBox(height: 12),
                if (_dateType == EventDateType.solar)
                  _buildSolarDatePicker(context)
                else
                  _buildLunarDatePicker(context, l10n),
                const SizedBox(height: 16),
                Text(l10n.recurrenceLabel, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Ordered from "doesn't repeat" through shortest to
                    // longest interval, rather than an arbitrary grouping —
                    // easier to scan than the yearly-first order this used
                    // to have.
                    _RecurrenceChip(
                      label: l10n.recurrenceNone,
                      value: EventRecurrence.none,
                      groupValue: _recurrence,
                      onSelected: (v) => setState(() => _recurrence = v),
                    ),
                    if (_dateType == EventDateType.solar)
                      _RecurrenceChip(
                        label: l10n.recurrenceWeekly,
                        value: EventRecurrence.weekly,
                        groupValue: _recurrence,
                        onSelected: (v) => setState(() => _recurrence = v),
                      ),
                    _RecurrenceChip(
                      label: l10n.recurrenceMonthly,
                      value: EventRecurrence.monthly,
                      groupValue: _recurrence,
                      onSelected: (v) => setState(() => _recurrence = v),
                    ),
                    if (_dateType == EventDateType.solar)
                      _RecurrenceChip(
                        label: l10n.recurrenceQuarterly,
                        value: EventRecurrence.quarterly,
                        groupValue: _recurrence,
                        onSelected: (v) => setState(() => _recurrence = v),
                      ),
                    _RecurrenceChip(
                      label: l10n.recurrenceYearly,
                      value: EventRecurrence.yearly,
                      groupValue: _recurrence,
                      onSelected: (v) => setState(() => _recurrence = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.reminderDaysBeforeLabel, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                _buildReminderChips(context, l10n),
                const SizedBox(height: 12),
                _buildReminderTimePicker(context, l10n),
                const SizedBox(height: 16),
                Text(l10n.categoryColorLabel, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                _buildColorPicker(context),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (widget.existing != null)
                      TextButton(
                        onPressed: _delete,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        child: Text(l10n.delete),
                      ),
                    const Spacer(),
                    FilledButton(onPressed: _save, child: Text(l10n.save)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolarDatePicker(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${_solarDate.day}/${_solarDate.month}/${_solarDate.year}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _solarDate,
          firstDate: DateTime(1900),
          lastDate: DateTime(2200),
        );
        if (picked != null) setState(() => _solarDate = picked);
      },
    );
  }

  Widget _buildLunarDatePicker(BuildContext context, AppLocalizations l10n) {
    final daysInMonth = _lunarService.daysInLunarMonth(
      _lunarYear,
      _lunarMonth,
      isLeapMonth: _isLeapMonth,
    );
    final clampedDay = _lunarDay > daysInMonth ? daysInMonth : _lunarDay;
    final leapMonthOfYear = _lunarService.getLeapMonthOfYear(_lunarYear);
    final canBeLeap = leapMonthOfYear == _lunarMonth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: clampedDay,
                decoration: InputDecoration(labelText: l10n.lunarDayLabel),
                items: List.generate(
                  daysInMonth,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                ),
                onChanged: (v) => setState(() => _lunarDay = v ?? _lunarDay),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _lunarMonth,
                decoration: InputDecoration(labelText: l10n.lunarMonthLabel),
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                ),
                onChanged: (v) => setState(() {
                  _lunarMonth = v ?? _lunarMonth;
                  _isLeapMonth = false;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: '$_lunarYear',
                decoration: InputDecoration(labelText: l10n.lunarYearLabel),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final y = int.tryParse(v);
                  if (y != null) setState(() => _lunarYear = y);
                },
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            // The numeric year above is still what's stored (and what leap
            // years are computed from) — this is just its Can Chi name, as
            // a caption under the whole row instead of a per-field
            // helperText (which made the 3 fields distort/misalign since
            // only one of them would grow taller than the others).
            Localizations.localeOf(context).languageCode == 'vi'
                ? canChiForYear(_lunarYear)
                : canChiEnglishForYear(_lunarYear),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (canBeLeap)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _isLeapMonth,
            title: Text(l10n.leapMonthLabel),
            onChanged: (v) => setState(() => _isLeapMonth = v ?? false),
          ),
      ],
    );
  }

  Widget _buildReminderChips(BuildContext context, AppLocalizations l10n) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          ..._reminderDaysBefore.map(
            (d) => Chip(
              label: Text(
                d == 0 ? l10n.reminderSameDay : l10n.reminderDaysBeforeChip(d),
              ),
              onDeleted: () => setState(() => _reminderDaysBefore.remove(d)),
            ),
          ),
          SizedBox(
            width: 130,
            child: TextField(
              controller: _reminderInputController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: l10n.addReminderHint, isDense: true),
              onSubmitted: _addReminderDay,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTimePicker(BuildContext context, AppLocalizations l10n) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.access_time),
      title: Text(l10n.reminderTimeLabel),
      trailing: Text(
        _reminderTime.format(context),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _reminderTime,
        );
        if (picked != null) setState(() => _reminderTime = picked);
      },
    );
  }

  void _addReminderDay(String value) {
    final n = int.tryParse(value.trim());
    if (n != null && n >= 0 && !_reminderDaysBefore.contains(n)) {
      setState(() {
        _reminderDaysBefore = [..._reminderDaysBefore, n]..sort();
      });
    }
    _reminderInputController.clear();
  }

  Widget _buildColorPicker(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: List.generate(eventCategoryColors.length, (i) {
        return _ColorSwatch(
          color: eventCategoryColors[i],
          selected: i == _colorTag,
          onTap: () => setState(() => _colorTag = i),
        );
      }),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<EventProvider>();
    final title = _titleController.text.trim();
    final description =
        _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim();

    if (widget.existing == null) {
      await provider.addEvent(
        title: title,
        description: description,
        dateType: _dateType,
        solarDate: _dateType == EventDateType.solar ? _solarDate : null,
        lunarDay: _dateType == EventDateType.lunar ? _lunarDay : null,
        lunarMonth: _dateType == EventDateType.lunar ? _lunarMonth : null,
        lunarYear: _dateType == EventDateType.lunar ? _lunarYear : null,
        isLeapMonth: _dateType == EventDateType.lunar ? _isLeapMonth : false,
        recurrence: _recurrence,
        reminderDaysBefore: _reminderDaysBefore,
        colorTag: _colorTag,
        reminderHour: _reminderTime.hour,
        reminderMinute: _reminderTime.minute,
      );
    } else {
      await provider.updateEvent(
        widget.existing!.copyWith(
          title: title,
          description: description,
          dateType: _dateType,
          solarDate: _dateType == EventDateType.solar ? _solarDate : null,
          lunarDay: _dateType == EventDateType.lunar ? _lunarDay : null,
          lunarMonth: _dateType == EventDateType.lunar ? _lunarMonth : null,
          lunarYear: _dateType == EventDateType.lunar ? _lunarYear : null,
          isLeapMonth: _dateType == EventDateType.lunar ? _isLeapMonth : false,
          recurrence: _recurrence,
          reminderDaysBefore: _reminderDaysBefore,
          colorTag: _colorTag,
          reminderHour: _reminderTime.hour,
          reminderMinute: _reminderTime.minute,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing != null) {
      await context.read<EventProvider>().deleteEvent(widget.existing!.id);
    }
    if (mounted) Navigator.of(context).pop();
  }
}

/// One recurrence choice in a single-select group — a [ChoiceChip] sizes to
/// its own label and wraps to the next line instead of being squeezed into
/// an equal-width segment (unlike [SegmentedButton], which was cramming 5
/// short Vietnamese labels into segments narrow enough to wrap mid-word).
class _RecurrenceChip extends StatelessWidget {
  const _RecurrenceChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String label;
  final EventRecurrence value;
  final EventRecurrence groupValue;
  final ValueChanged<EventRecurrence> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: value == groupValue,
      onSelected: (_) => onSelected(value),
    );
  }
}

/// A single category-color choice — a plain tappable circle that is also
/// Tab/Enter/Space-reachable, so the color picker doesn't require a mouse.
class _ColorSwatch extends StatefulWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ColorSwatch> createState() => _ColorSwatchState();
}

class _ColorSwatchState extends State<_ColorSwatch> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: _focused
                  ? primary
                  : (widget.selected ? onSurface : Colors.transparent),
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
