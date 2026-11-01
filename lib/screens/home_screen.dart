import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../state/app_state.dart';
import '../widgets/fuel_price_card.dart';
import '../widgets/section_heading.dart';
import '../widgets/vehicle_card.dart';
import 'notifications_screen.dart';
import 'recommendation_screen.dart';
import 'vehicle_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final electricTrend = appState.trendFor('electric');
    final latestElectric = electricTrend.isEmpty
        ? null
        : electricTrend.last.registrations;
    final electricUsesFallback = appState.trendFallbackFuels.contains(
      'electric',
    );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          _HomeTopBar(appState: appState),
          const SizedBox(height: 18),
          _MobilityHero(
            onPlanTrip: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecommendationScreen(appState: appState),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeading(
            title: 'Today’s official prices',
            subtitle: 'Used directly in your trip-cost estimates',
          ),
          const SizedBox(height: 12),
          FuelPriceCard(appState: appState),
          const SizedBox(height: 26),
          SectionHeading(
            title: 'Recommended vehicles',
            subtitle: 'Efficient choices for your next journey',
            actionLabel: 'View all',
            onAction: () => appState.setNavigationIndex(1),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 225,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: appState.vehicles.length < 4
                  ? appState.vehicles.length
                  : 4,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final vehicle = appState.vehicles[index];
                return CompactVehicleCard(
                  vehicle: vehicle,
                  onTap: () => _openVehicle(context, vehicle.id),
                );
              },
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeading(
            title: 'Mobility insight',
            subtitle: 'National vehicle-registration data',
          ),
          const SizedBox(height: 12),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => appState.setNavigationIndex(3),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F5FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.electric_bolt_rounded,
                        color: Color(0xFF0369A1),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latestElectric == null
                                ? 'Explore Malaysia’s vehicle trends'
                                : electricUsesFallback
                                ? 'Electric registration trend preview'
                                : '${formatInteger(latestElectric)} electric registrations',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            latestElectric == null
                                ? 'Compare petrol, diesel, hybrid and electric registrations.'
                                : electricUsesFallback
                                ? 'Open the dashboard to refresh the official government dataset.'
                                : 'Latest available monthly record for cars in Malaysia.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.blueGrey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 17),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF4D99B)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFB45309)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Compare the complete trip cost—not only the daily rental rate. A slightly higher rental price can still cost less after fuel.',
                    style: TextStyle(
                      color: Color(0xFF744210),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openVehicle(BuildContext context, String vehicleId) {
    final vehicle = appState.vehicles.firstWhere(
      (item) => item.id == vehicleId,
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VehicleDetailsScreen(vehicle: vehicle, appState: appState),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final firstName = appState.userName.split(' ').first;
    final initial = firstName.isEmpty ? 'S' : firstName.substring(0, 1);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, $firstName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.navy,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Where will your next trip take you?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blueGrey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NotificationsScreen(appState: appState),
            ),
          ),
          icon: Badge(
            isLabelVisible: appState.unreadNotificationCount > 0,
            label: Text('${appState.unreadNotificationCount}'),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => appState.setNavigationIndex(4),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primary,
            child: Text(
              initial.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobilityHero extends StatelessWidget {
  const _MobilityHero({required this.onPlanTrip});

  final VoidCallback onPlanTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.navy, Color(0xFF164E63)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.navy.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -35,
            child: Icon(
              Icons.route_rounded,
              size: 155,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'SMART MOBILITY',
                  style: TextStyle(
                    color: Color(0xFF9FE4D8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Know the true cost\nbefore you drive.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Rental, official fuel price and efficiency—calculated together.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.76),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.navy,
                ),
                onPressed: onPlanTrip,
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Plan a trip'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
