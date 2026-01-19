/// Dwolla Sandbox Practice Dashboard - Flutter Frontend
///
/// This app provides a visual interface to learn and understand
/// the entire Dwolla payment system end-to-end.
///
/// Architecture:
/// - API Service: Handles all HTTP communication with the backend
/// - Provider: State management for app-wide data
/// - Pages: Individual screens for each Dwolla feature

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/dwolla_provider.dart';
import 'pages/settings_page.dart';
import 'pages/customers_page.dart';
import 'pages/payments_page.dart';
import 'pages/transfers_page.dart';
import 'pages/webhooks_page.dart';
import 'pages/account_page.dart';
import 'pages/visualizer_page.dart';

void main() {
  runApp(const DwollaDashboardApp());
}

class DwollaDashboardApp extends StatelessWidget {
  const DwollaDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // API Service - handles all backend communication
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        // Dwolla Provider - manages app state
        ChangeNotifierProvider<DwollaProvider>(
          create: (context) => DwollaProvider(context.read<ApiService>()),
        ),
      ],
      child: MaterialApp(
        title: 'Dwolla Sandbox Dashboard',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2D2D2D),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // Clean, readable typography
          textTheme: const TextTheme(
            headlineLarge: TextStyle(fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(fontSize: 16),
          ),
        ),
        home: const MainNavigationPage(),
      ),
    );
  }
}

/// Main navigation page with sidebar/bottom navigation
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  // All pages in the app
  static const List<Widget> _pages = [
    SettingsPage(),
    CustomersPage(),
    PaymentsPage(),
    TransfersPage(),
    WebhooksPage(),
    AccountPage(),
    VisualizerPage(),
  ];

  // Navigation items with icons and labels
  static const List<NavigationItem> _navItems = [
    NavigationItem(icon: Icons.settings, label: 'Settings'),
    NavigationItem(icon: Icons.people, label: 'Customers'),
    NavigationItem(icon: Icons.payment, label: 'Payments'),
    NavigationItem(icon: Icons.swap_horiz, label: 'Transfers'),
    NavigationItem(icon: Icons.webhook, label: 'Webhooks'),
    NavigationItem(icon: Icons.account_balance, label: 'My Account'),
    NavigationItem(icon: Icons.schema, label: 'Visualizer'),
  ];

  @override
  Widget build(BuildContext context) {
    // Use NavigationRail for larger screens, BottomNavigationBar for mobile
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          // Side navigation for wide screens
          if (isWideScreen)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.grey[100],
              destinations: _navItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
          // Main content area
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
      // Bottom navigation for narrow screens
      bottomNavigationBar: isWideScreen
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: _navItems
                  .map((item) => NavigationDestination(
                        icon: Icon(item.icon),
                        label: item.label,
                      ))
                  .toList(),
            ),
    );
  }
}

/// Helper class for navigation items
class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({required this.icon, required this.label});
}
