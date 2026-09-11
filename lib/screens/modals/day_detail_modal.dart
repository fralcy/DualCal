import 'package:flutter/material.dart';

import '../../core/widgets/day_detail_content.dart';

/// Mobile-only bottom sheet showing the same day-detail content the
/// desktop layout renders as a persistent side panel.
Future<void> showDayDetailModal(BuildContext context, DateTime date) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DayDetailContent(date: date),
  );
}
