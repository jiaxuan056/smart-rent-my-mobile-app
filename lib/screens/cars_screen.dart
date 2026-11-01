import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/vehicle.dart';
import '../state/app_state.dart';
import '../widgets/vehicle_card.dart';
import 'comparison_screen.dart';
import 'recommendation_screen.dart';
import 'vehicle_details_screen.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
  static const _minimumDailyRate = 80.0;
  static const _maximumDailyRate = 400.0;

  final _searchController = TextEditingController();
  String _filter = 'All';
  String _transmission = 'All';
  int _minimumSeats = 1;
  RangeValues _priceRange = const RangeValues(
    _minimumDailyRate,
    _maximumDailyRate,
  );
  bool _filtersExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = _filteredVehicles();
    final compareCount = widget.appState.comparisonIds.length;
    final hasPriceFilter =
        _priceRange.start > _minimumDailyRate ||
        _priceRange.end < _maximumDailyRate;
    final activeFilterCount = _activeFilterCount;
    final filterSummary = _filterSummary;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find your car',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${vehicles.length} of ${widget.appState.vehicles.length} vehicles match your search.',
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(
                          () => _filtersExpanded = !_filtersExpanded,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tune_rounded, size: 20),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                _filtersExpanded
                                    ? 'Hide search and filters'
                                    : activeFilterCount == 0
                                    ? 'Search and filters'
                                    : 'Filters active ($activeFilterCount)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Icon(
                              _filtersExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (activeFilterCount > 0) ...[
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Clear all filters',
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.filter_alt_off_rounded),
                      ),
                    ],
                  ],
                ),
                if (!_filtersExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      filterSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: activeFilterCount == 0
                            ? Colors.blueGrey.shade500
                            : AppTheme.primary,
                        fontSize: 12,
                        fontWeight: activeFilterCount == 0
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                if (_filtersExpanded) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search brand, model or category',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              RecommendationScreen(appState: widget.appState),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Find my best match'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in const [
                          'All',
                          'Petrol',
                          'Hybrid',
                          'Electric',
                          'Diesel',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: _filter == filter,
                              onSelected: (_) =>
                                  setState(() => _filter = filter),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _transmission,
                          decoration: const InputDecoration(
                            labelText: 'Transmission',
                            isDense: true,
                          ),
                          items: const ['All', 'Automatic', 'Manual']
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _transmission = value ?? 'All'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _minimumSeats,
                          decoration: const InputDecoration(
                            labelText: 'Minimum seats',
                            isDense: true,
                          ),
                          items: const [1, 4, 5, 7]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value == 1 ? 'Any' : '$value seats',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _minimumSeats = value ?? 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE1E8E5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              size: 20,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Daily price range',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text(
                              '${formatRinggit(_priceRange.start)} – ${formatRinggit(_priceRange.end)}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: _priceRange,
                          min: _minimumDailyRate,
                          max: _maximumDailyRate,
                          divisions: 18,
                          labels: RangeLabels(
                            'RM ${_priceRange.start.round()}',
                            'RM ${_priceRange.end.round()}',
                          ),
                          onChanged: (values) =>
                              setState(() => _priceRange = values),
                        ),
                        Row(
                          children: [
                            Text(
                              'RM ${_minimumDailyRate.round()}',
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            if (hasPriceFilter)
                              TextButton(
                                onPressed: () => setState(
                                  () => _priceRange = const RangeValues(
                                    _minimumDailyRate,
                                    _maximumDailyRate,
                                  ),
                                ),
                                child: const Text('Reset price'),
                              ),
                            const Spacer(),
                            Text(
                              'RM ${_maximumDailyRate.round()}',
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: vehicles.isEmpty
                ? const _NoVehiclesFound()
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      4,
                      18,
                      compareCount >= 2 ? 100 : 26,
                    ),
                    itemCount: vehicles.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return VehicleCard(
                        vehicle: vehicle,
                        appState: widget.appState,
                        onTap: () => Navigator.of(context).push(
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
          if (compareCount >= 2)
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE1E8E5))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$compareCount vehicles selected',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ComparisonScreen(appState: widget.appState),
                        ),
                      ),
                      icon: const Icon(Icons.compare_arrows_rounded),
                      label: const Text('Compare'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  int get _activeFilterCount {
    var count = 0;
    if (_searchController.text.trim().isNotEmpty) count++;
    if (_filter != 'All') count++;
    if (_transmission != 'All') count++;
    if (_minimumSeats > 1) count++;
    if (_priceRange.start > _minimumDailyRate ||
        _priceRange.end < _maximumDailyRate) {
      count++;
    }
    return count;
  }

  String get _filterSummary {
    final filters = <String>[];
    final query = _searchController.text.trim();
    if (query.isNotEmpty) filters.add('Search: $query');
    if (_filter != 'All') filters.add(_filter);
    if (_transmission != 'All') filters.add(_transmission);
    if (_minimumSeats > 1) filters.add('$_minimumSeats+ seats');
    if (_priceRange.start > _minimumDailyRate ||
        _priceRange.end < _maximumDailyRate) {
      filters.add(
        '${formatRinggit(_priceRange.start)} - ${formatRinggit(_priceRange.end)}',
      );
    }
    return filters.isEmpty
        ? 'Tap to search or adjust vehicle filters.'
        : 'Applied: ${filters.join(' • ')}';
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _filter = 'All';
      _transmission = 'All';
      _minimumSeats = 1;
      _priceRange = const RangeValues(_minimumDailyRate, _maximumDailyRate);
    });
  }

  List<Vehicle> _filteredVehicles() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.appState.vehicles.where((vehicle) {
      if (!vehicle.canBeBooked) {
        return false;
      }
      final matchesFilter =
          _filter == 'All' || vehicle.powertrain.filterLabel == _filter;
      final matchesTransmission =
          _transmission == 'All' || vehicle.transmission == _transmission;
      final matchesSeats = vehicle.seats >= _minimumSeats;
      final searchable =
          '${vehicle.brand} ${vehicle.model} ${vehicle.category} ${vehicle.branch}'
              .toLowerCase();
      final matchesPrice =
          vehicle.dailyRate >= _priceRange.start &&
          vehicle.dailyRate <= _priceRange.end;
      return matchesFilter &&
          matchesTransmission &&
          matchesSeats &&
          matchesPrice &&
          (query.isEmpty || searchable.contains(query));
    }).toList();
  }
}

class _NoVehiclesFound extends StatelessWidget {
  const _NoVehiclesFound();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_crash_outlined,
              size: 58,
              color: Colors.blueGrey.shade300,
            ),
            const SizedBox(height: 14),
            Text(
              'No matching vehicles',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              'Try another search, fuel type or price range.',
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
