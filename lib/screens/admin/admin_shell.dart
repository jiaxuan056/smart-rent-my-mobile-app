import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import 'admin_bookings_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_reviews_screen.dart';
import 'admin_vehicles_screen.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      AdminDashboardScreen(appState: appState),
      AdminBookingsScreen(appState: appState),
      AdminVehiclesScreen(appState: appState),
      AdminCustomersScreen(appState: appState),
      AdminReviewsScreen(appState: appState),
    ];
    return Scaffold(
      body: IndexedStack(index: appState.navigationIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appState.navigationIndex,
        onDestinationSelected: appState.setNavigationIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car_rounded),
            label: 'Vehicles',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.reviews_outlined),
            selectedIcon: Icon(Icons.reviews_rounded),
            label: 'Reviews',
          ),
        ],
      ),
    );
  }
}
