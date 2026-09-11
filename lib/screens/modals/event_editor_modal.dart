import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/event_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/providers/event_provider.dart';
import '../../core/utils/lunar_calendar_service.dart';
import '../../models/calendar_event.dart';

/// Add/edit sheet for a note/event: title, date (solar picker or lunar
/// day/month/year + leap toggle), one-time vs yearly recurrence, reminder
/// offsets, and a category color tag.
Future<void> showEventEditorModal(
  BuildContext context, {
  required DateTime initialDate,
  CalendarEvent? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _EventEditorForm(initialDate: initialDate, existing: existing),
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
                  onSelectionChanged: (s) => setState(() => _dateType = s.first),
                ),
                const SizedBox(height: 12),
                if (_dateType == EventDateType.solar)
                  _buildSolarDatePicker(context)
                else
                  _buildLunarDatePicker(context, l10n),
                const SizedBox(height: 16),
                SegmentedButton<EventRecurrence>(
                  segments: [
                    ButtonSegment(
                      value: EventRecurrence.none,
                      label: Text(l10n.recurrenceNone),
                    ),
                    ButtonSegment(
                      value: EventRecurrence.yearly,
                      label: Text(l10n.recurrenceYearly),
                    ),
                  ],
                  selected: {_recurrence},
                  onSelectionChanged: (s) => setState(() => _recurrence = s.first),
                ),
                const SizedBox(height: 16),
                Text(l10n.reminderDaysBeforeLabel, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                _buildReminderChips(context, l10n),
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
    return Wrap(
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
        final selected = i == _colorTag;
        return GestureDetector(
          onTap: () => setState(() => _colorTag = i),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: eventCategoryColors[i],
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 2)
                  : null,
            ),
          ),
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
