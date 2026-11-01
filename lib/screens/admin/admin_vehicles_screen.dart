import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/vehicle.dart';
import '../../state/app_state.dart';
import '../../widgets/vehicle_visual.dart';
import 'admin_vehicle_form_screen.dart';

class AdminVehiclesScreen extends StatefulWidget {
  const AdminVehiclesScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AdminVehiclesScreen> createState() => _AdminVehiclesScreenState();
}

class _AdminVehiclesScreenState extends State<AdminVehiclesScreen> {
  final _searchController = TextEditingController();
  String _availability = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = _vehicles();
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle fleet',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${vehicles.length} of ${widget.appState.allVehicles.length} vehicles',
                      style: TextStyle(color: Colors.blueGrey.shade600),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search brand, model, branch or category',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: _availability,
                      decoration: const InputDecoration(
                        labelText: 'Availability filter',
                        isDense: true,
                      ),
                      items:
                          [
                                'All',
                                ...VehicleAvailability.values.map(
                                  (v) => v.label,
                                ),
                              ]
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      onChanged: (value) =>
                          setState(() => _availability = value ?? 'All'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: vehicles.isEmpty
                    ? const Center(child: Text('No vehicle records match.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(18, 2, 18, 96),
                        itemCount: vehicles.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _VehicleAdminCard(
                          vehicle: vehicles[index],
                          appState: widget.appState,
                          onEdit: () => _openForm(vehicles[index]),
                        ),
                      ),
              ),
            ],
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: FloatingActionButton.extended(
              onPressed: () => _openForm(null),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add vehicle'),
            ),
          ),
        ],
      ),
    );
  }

  List<Vehicle> _vehicles() {
    final query = _searchController.text.trim().toLowerCase();
    return widget.appState.allVehicles.where((vehicle) {
      final searchable =
          '${vehicle.brand} ${vehicle.model} ${vehicle.branch} ${vehicle.category}'
              .toLowerCase();
      final matchesAvailability =
          _availability == 'All' || vehicle.availability.label == _availability;
      return matchesAvailability &&
          (query.isEmpty || searchable.contains(query));
    }).toList();
  }

  Future<void> _openForm(Vehicle? vehicle) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AdminVehicleFormScreen(appState: widget.appState, vehicle: vehicle),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }
}

class _VehicleAdminCard extends StatelessWidget {
  const _VehicleAdminCard({
    required this.vehicle,
    required this.appState,
    required this.onEdit,
  });

  final Vehicle vehicle;
  final AppState appState;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 105,
                  child: VehicleVisual(
                    vehicle: vehicle,
                    height: 88,
                    showDetails: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text('${vehicle.year} · ${vehicle.category}'),
                      Text(
                        '${formatRinggit(vehicle.dailyRate)}/day · ${vehicle.branch}',
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        vehicle.availability.label,
                        style: TextStyle(
                          color: vehicle.canBeBooked
                              ? AppTheme.primary
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PopupMenuButton<VehicleAvailability>(
                    onSelected: (value) {
                      final error = appState.changeVehicleAvailability(
                        vehicle.id,
                        value,
                      );
                      if (error != null) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
                    itemBuilder: (_) => [
                      for (final value in VehicleAvailability.values)
                        PopupMenuItem(value: value, child: Text(value.label)),
                    ],
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD8D4)),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('Change status'),
                    ),
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
