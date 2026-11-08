import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/bookshelf/bookshelf_screen.dart';
import 'presentation/screens/scanner/barcode_scanner_screen.dart';
import 'presentation/screens/settings_backup/settings_backup_screen.dart';
import 'presentation/screens/stats/stats_screen.dart';

/// Root application widget configuring navigation tabs, state persistence, and Material 3 theme.
class ShelfCraftApp extends StatefulWidget {
  const ShelfCraftApp({super.key});

  @override
  State<ShelfCraftApp> createState() => _ShelfCraftAppState();
}

class _ShelfCraftAppState extends State<ShelfCraftApp> {
  int _currentIndex = 0;

  static const _screens = [
    BookshelfScreen(),
    BarcodeScannerScreen(),
    StatsScreen(),
    SettingsBackupScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShelfCraft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.shelves),
              label: 'Bookshelf',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan ISBN',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings),
              label: 'Backup & Pro',
            ),
          ],
        ),
      ),
    );
  }
}
