import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/input_formatters.dart';
import '../models/recommendation.dart';
import '../services/cost_calculation_service.dart';
import '../state/app_state.dart';
import '../widgets/vehicle_visual.dart';
import 'vehicle_details_screen.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _distanceController = TextEditingController(text: '300');
  final _budgetController = TextEditingController(text: '700');
  late DateTime _pickupDate;
  late DateTime _returnDate;
  int _passengers = 4;
  String _fuel = 'Any';
  List<VehicleRecommendation>? _results;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _pickupDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    _returnDate = _pickupDate.add(const Duration(days: 3));
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart car finder')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.navy, Color(0xFF164E63)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tell us about your journey. SmartRent MY will check availability and rank cars using the complete estimated trip cost.',
                    style: TextStyle(color: Colors.white, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'Pickup',
                            value: formatDate(_pickupDate),
                            onTap: () => _pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateField(
                            label: 'Return',
                            value: formatDate(_returnDate),
                            onTap: () => _pickDate(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _distanceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        const MaximumIntegerInputFormatter(5000),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Expected distance',
                        prefixIcon: Icon(Icons.route_outlined),
                        suffixText: 'km',
                        helperText: 'From 1 to 5,000 km',
                      ),
                      validator: (value) {
                        final distance = double.tryParse(value ?? '');
                        if (distance == null ||
                            distance <
                                CostCalculationService
                                    .minimumExpectedDistanceKm ||
                            distance >
                                CostCalculationService
                                    .maximumExpectedDistanceKm) {
                          return 'Enter a distance from 1 to 5,000 km.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d{0,5}(\.\d{0,2})?'),
                        ),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Maximum complete-trip budget',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        prefixText: 'RM ',
                      ),
                      validator: (value) {
                        final budget = double.tryParse(value ?? '');
                        if (budget == null || budget < 100 || budget > 50000) {
                          return 'Enter a budget from RM100 to RM50,000.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: _passengers,
                      decoration: const InputDecoration(
                        labelText: 'Passengers',
                        prefixIcon: Icon(Icons.people_outline_rounded),
                      ),
                      items: [
                        for (var value = 1; value <= 7; value++)
                          DropdownMenuItem(
                            value: value,
                            child: Text(
                              '$value ${value == 1 ? 'person' : 'people'}',
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _passengers = value ?? 1),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _fuel,
                      decoration: const InputDecoration(
                        labelText: 'Preferred energy type',
                        prefixIcon: Icon(Icons.energy_savings_leaf_outlined),
                      ),
                      items:
                          const [
                                'Any',
                                'Petrol',
                                'Hybrid',
                                'Electric',
                                'Diesel',
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) =>
                          setState(() => _fuel = value ?? 'Any'),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _findCars,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Find my best matches'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          if (_results == null)
            const _RecommendationIntro()
          else if (_results!.isEmpty)
            const _NoRecommendation()
          else ...[
            Text(
              '${_results!.length} suitable ${_results!.length == 1 ? 'vehicle' : 'vehicles'}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Ranked using availability, trip cost, capacity, efficiency and rating.',
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < _results!.length; index++) ...[
              _RecommendationCard(
                result: _results![index],
                rank: index + 1,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VehicleDetailsScreen(
                      vehicle: _results![index].vehicle,
                      appState: widget.appState,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate(bool pickup) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: pickup ? _pickupDate : _returnDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      if (pickup) {
        _pickupDate = selected;
        if (!_returnDate.isAfter(selected)) {
          _returnDate = selected.add(const Duration(days: 1));
        }
      } else if (selected.isAfter(_pickupDate)) {
        _returnDate = selected;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Return date must follow pickup date.')),
        );
      }
    });
  }

  void _findCars() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    FocusScope.of(context).unfocus();
    final criteria = RecommendationCriteria(
      pickupDate: _pickupDate,
      returnDate: _returnDate,
      expectedDistanceKm: double.parse(_distanceController.text),
      passengers: _passengers,
      maximumBudget: double.parse(_budgetController.text),
      preferredFuel: _fuel,
    );
    setState(() => _results = widget.appState.recommendVehicles(criteria));
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8F7),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFDDE5E2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 17,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.result,
    required this.rank,
    required this.onTap,
  });

  final VehicleRecommendation result;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  VehicleVisual(vehicle: result.vehicle, height: 150),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: rank == 1 ? AppTheme.primary : AppTheme.navy,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        rank == 1 ? 'BEST MATCH' : 'MATCH #$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.vehicle.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    formatRinggit(result.cost.totalCost),
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              for (final reason in result.reasons)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(child: Text(reason)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationIntro extends StatelessWidget {
  const _RecommendationIntro();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Complete the journey details to receive transparent recommendations.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NoRecommendation extends StatelessWidget {
  const _NoRecommendation();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 58,
              color: Colors.blueGrey.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              'No vehicle matches every requirement. Try increasing the budget or selecting Any energy type.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
