import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/vehicle.dart';
import '../services/cost_calculation_service.dart';
import '../state/app_state.dart';
import '../widgets/vehicle_visual.dart';
import 'vehicle_details_screen.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final _distanceController = TextEditingController(text: '300');
  int _days = 3;

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = widget.appState.comparisonVehicles;
    final distance = double.tryParse(_distanceController.text) ?? 0;
    final calculations = <String, TripCost>{
      for (final vehicle in vehicles)
        vehicle.id: CostCalculationService.calculate(
          vehicle: vehicle,
          fuelPrice: widget.appState.fuelPrice,
          rentalDays: _days,
          expectedDistanceKm: distance,
        ),
    };
    String? lowestTotalId;
    if (calculations.isNotEmpty) {
      lowestTotalId = calculations.entries
          .reduce(
            (current, next) =>
                next.value.totalCost < current.value.totalCost ? next : current,
          )
          .key;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare trip costs'),
        actions: [
          TextButton(
            onPressed: () {
              widget.appState.clearComparison();
              setState(() {});
            },
            child: const Text('Clear'),
          ),
        ],
      ),
      body: vehicles.length < 2
          ? _ComparisonEmpty(onBack: () => Navigator.pop(context))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              children: [
                Text(
                  'One journey. Every cost.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rental and estimated fuel or charging costs are calculated using the same distance and duration.',
                  style: TextStyle(
                    color: Colors.blueGrey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _distanceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Distance',
                              suffixText: 'km',
                              prefixIcon: Icon(Icons.route_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 58,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F8F7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFDDE5E2),
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _days <= 1
                                      ? null
                                      : () => setState(() => _days--),
                                  icon: const Icon(Icons.remove_rounded),
                                ),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$_days',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        _days == 1 ? 'day' : 'days',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _days >= 30
                                      ? null
                                      : () => setState(() => _days++),
                                  icon: const Icon(Icons.add_rounded),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 525,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: vehicles.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return _ComparisonVehicleCard(
                        vehicle: vehicle,
                        cost: calculations[vehicle.id]!,
                        isLowestTotal: lowestTotalId == vehicle.id,
                        onRemove: () {
                          widget.appState.toggleComparison(vehicle.id);
                          setState(() {});
                        },
                        onView: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VehicleDetailsScreen(
                              vehicle: vehicle,
                              appState: widget.appState,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppTheme.mint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: AppTheme.primary),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          '“Lowest trip cost” includes the rental rate, estimated energy cost, protection plan and service fee.',
                          style: TextStyle(
                            color: Color(0xFF15473F),
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
}

class _ComparisonVehicleCard extends StatelessWidget {
  const _ComparisonVehicleCard({
    required this.vehicle,
    required this.cost,
    required this.isLowestTotal,
    required this.onRemove,
    required this.onView,
  });

  final Vehicle vehicle;
  final TripCost cost;
  final bool isLowestTotal;
  final VoidCallback onRemove;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 265,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: isLowestTotal ? AppTheme.primary : const Color(0xFFE7ECEA),
            width: isLowestTotal ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  VehicleVisual(
                    vehicle: vehicle,
                    height: 120,
                    showDetails: false,
                  ),
                  if (isLowestTotal)
                    const Positioned(left: 8, top: 8, child: _WinnerBadge()),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.90),
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: onRemove,
                        icon: const Icon(Icons.close_rounded, size: 19),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                vehicle.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                vehicle.powertrain.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blueGrey.shade600,
                ),
              ),
              const Divider(height: 24),
              _ComparisonRow(
                label: 'Daily rental',
                value: formatRinggit(vehicle.dailyRate),
              ),
              _ComparisonRow(
                label: 'Efficiency',
                value: vehicle.efficiencyLabel,
              ),
              _ComparisonRow(label: 'Seats', value: '${vehicle.seats}'),
              _ComparisonRow(
                label: 'Rental subtotal',
                value: formatRinggit(cost.rentalCost),
              ),
              _ComparisonRow(
                label: vehicle.isElectric ? 'Charging' : 'Fuel estimate',
                value: formatRinggit(cost.energyCost),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: isLowestTotal
                      ? AppTheme.mint
                      : const Color(0xFFF3F6F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete trip estimate',
                      style: TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatRinggit(cost.totalCost),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onView,
                child: const SizedBox(
                  width: double.infinity,
                  child: Text('View vehicle', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WinnerBadge extends StatelessWidget {
  const _WinnerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'LOWEST TRIP COST',
        style: TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade600),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ComparisonEmpty extends StatelessWidget {
  const _ComparisonEmpty({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.compare_arrows_rounded,
              size: 64,
              color: AppTheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Choose at least two cars',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Return to the catalogue and select two or three vehicles.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: onBack, child: const Text('Browse cars')),
          ],
        ),
      ),
    );
  }
}
