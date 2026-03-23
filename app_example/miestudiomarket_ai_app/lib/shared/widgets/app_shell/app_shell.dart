import 'package:flutter/material.dart';

import '../../../features/market_gaps/presentation/market_gaps_page.dart';
import '../../../features/pricing_simulator/presentation/price_simulator_page.dart';
import '../../../features/report_ingestion/presentation/report_upload_page.dart';
import 'widgets/custom_bottom_nav_bar.dart';

/// App shell providing bottom navigation between features.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const _pages = <Widget>[
    ReportUploadPage(),
    MarketGapsPage(),
    PriceSimulatorPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ensure the body extends behind the navigation bar so the blur effect is visible
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
