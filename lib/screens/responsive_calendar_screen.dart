import 'package:flutter/material.dart';

import 'desktop_landscape_calendar_screen.dart';
import 'mobile_portrait_calendar_screen.dart';
import 'responsive_screen.dart';

class ResponsiveCalendarScreen extends StatelessWidget {
  const ResponsiveCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveScreen(
      mobileBuilder: _buildMobile,
      desktopBuilder: _buildDesktop,
    );
  }

  static Widget _buildMobile(BuildContext context) =>
      const MobilePortraitCalendarScreen();

  static Widget _buildDesktop(BuildContext context) =>
      const DesktopLandscapeCalendarScreen();
}
