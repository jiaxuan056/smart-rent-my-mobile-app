import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'bookings_screen.dart';
import 'cars_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'trends_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(appState: appState),
      CarsScreen(appState: appState),
      BookingsScreen(appState: appState),
      TrendsScreen(appState: appState),
      ProfileScreen(appState: appState),
    ];

    return Scaffold(
      body: IndexedStack(index: appState.navigationIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appState.navigationIndex,
        onDestinationSelected: appState.setNavigationIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car_rounded),
            label: 'Cars',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats_outlined),
            selectedIcon: Icon(Icons.query_stats_rounded),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
