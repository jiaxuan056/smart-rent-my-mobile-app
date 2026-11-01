import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/booking.dart';
import '../../models/vehicle.dart';
import '../../state/app_state.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final bookings = appState.allBookings;
    int count(BookingStatus status) =>
        bookings.where((booking) => booking.status == status).length;
    final activeVehicles = appState.allVehicles
        .where((vehicle) => vehicle.availability.canBeBooked)
        .length;
    final revenue = bookings
        .where((booking) => booking.status != BookingStatus.cancelled)
        .fold<double>(0, (sum, booking) => sum + booking.cost.totalCost);
    final recent = bookings.take(4).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin dashboard',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rental fleet and booking operations',
                      style: TextStyle(color: Colors.blueGrey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Sign out',
                onPressed: appState.signOut,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.navy, Color(0xFF164E63)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 27,
                  backgroundColor: Color(0x24FFFFFF),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SmartRent Administrator',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${bookings.length} booking records · ${appState.allVehicles.length} vehicles',
                        style: const TextStyle(color: Color(0xFFD5E9E4)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _MetricCard(
                label: 'Confirmed',
                value: '${count(BookingStatus.confirmed)}',
                icon: Icons.verified_outlined,
                color: const Color(0xFF0369A1),
              ),
              _MetricCard(
                label: 'Ongoing',
                value: '${count(BookingStatus.ongoing)}',
                icon: Icons.key_rounded,
                color: AppTheme.primary,
              ),
              _MetricCard(
                label: 'Completed',
                value: '${count(BookingStatus.completed)}',
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF3F6212),
              ),
              _MetricCard(
                label: 'Available cars',
                value: '$activeVehicles',
                icon: Icons.directions_car_outlined,
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                backgroundColor: AppTheme.mint,
                child: Icon(Icons.payments_outlined, color: AppTheme.primary),
              ),
              title: const Text(
                'Simulated booking value',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Excludes cancelled records'),
              trailing: Text(
                formatRinggit(revenue),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent booking records',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => appState.setNavigationIndex(1),
                child: const Text('View all'),
              ),
            ],
          ),
          if (recent.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No booking records are available.'),
              ),
            )
          else
            for (final booking in recent)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.mint,
                    child: Text(booking.vehicle.brand.substring(0, 1)),
                  ),
                  title: Text(
                    booking.vehicle.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text('${booking.customerName} · ${booking.id}'),
                  trailing: Text(
                    booking.status.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(label, style: TextStyle(color: Colors.blueGrey.shade600)),
          ],
        ),
      ),
    );
  }
}
