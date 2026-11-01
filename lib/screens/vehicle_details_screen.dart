import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/input_formatters.dart';
import '../models/payment_result.dart';
import '../models/vehicle.dart';
import '../services/cost_calculation_service.dart';
import '../state/app_state.dart';
import '../widgets/section_heading.dart';
import '../widgets/vehicle_visual.dart';
import 'payment_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({
    super.key,
    required this.vehicle,
    required this.appState,
  });

  final Vehicle vehicle;
  final AppState appState;

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  late DateTime _pickupDate;
  late DateTime _returnDate;
  late final TextEditingController _distanceController;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _pickupDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    _returnDate = _pickupDate.add(const Duration(days: 3));
    _distanceController = TextEditingController(text: '300');
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distance = double.tryParse(_distanceController.text) ?? 0;
    final distanceIsValid =
        distance >= CostCalculationService.minimumExpectedDistanceKm &&
        distance <= CostCalculationService.maximumExpectedDistanceKm;
    final days = CostCalculationService.rentalDays(_pickupDate, _returnDate);
    final cost = CostCalculationService.calculate(
      vehicle: widget.vehicle,
      fuelPrice: widget.appState.fuelPrice,
      rentalDays: days,
      expectedDistanceKm: distance,
    );
    final isFavourite = widget.appState.favouriteIds.contains(
      widget.vehicle.id,
    );
    final reviews = widget.appState.reviewsForVehicle(widget.vehicle.id);
    final rating = widget.appState.ratingForVehicle(widget.vehicle);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.name),
        actions: [
          IconButton(
            tooltip: isFavourite ? 'Remove favourite' : 'Add favourite',
            onPressed: () {
              widget.appState.toggleFavourite(widget.vehicle.id);
              setState(() {});
            },
            icon: Icon(
              isFavourite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: isFavourite ? Colors.redAccent : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
        children: [
          VehicleVisual(vehicle: widget.vehicle, height: 210),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vehicle.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.vehicle.year} · ${widget.vehicle.category} · ${widget.vehicle.branch}',
                      style: TextStyle(color: Colors.blueGrey.shade600),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRinggit(widget.vehicle.dailyRate),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text('per day'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.vehicle.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: Colors.blueGrey.shade700,
            ),
          ),
          if (widget.vehicle.sourceName != null) ...[
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 17,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Specification reference: ${widget.vehicle.sourceName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blueGrey.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 5),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 5),
              Text(
                reviews.isEmpty
                    ? 'Catalogue rating'
                    : '${reviews.length} customer ${reviews.length == 1 ? 'review' : 'reviews'}',
                style: TextStyle(color: Colors.blueGrey.shade600),
              ),
            ],
          ),
          if (!widget.vehicle.canBeBooked) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_busy_outlined,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This vehicle is ${widget.vehicle.availability.label.toLowerCase()} and cannot be booked.',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SpecTile(
                  icon: Icons.airline_seat_recline_normal_rounded,
                  label: '${widget.vehicle.seats} seats',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SpecTile(
                  icon: Icons.settings_rounded,
                  label: widget.vehicle.transmission,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SpecTile(
                  icon: Icons.energy_savings_leaf_rounded,
                  label: widget.vehicle.efficiencyLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SectionHeading(
            title: 'Estimate your complete trip',
            subtitle: 'Official fuel prices are included automatically',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DateInput(
                          label: 'Pickup',
                          value: formatDate(_pickupDate),
                          onTap: () => _pickDate(isPickup: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateInput(
                          label: 'Return',
                          value: formatDate(_returnDate),
                          onTap: () => _pickDate(isPickup: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _distanceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      const MaximumIntegerInputFormatter(5000),
                    ],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Expected travel distance',
                      helperText: 'Enter 1–5,000 km',
                      suffixText: 'km',
                      prefixIcon: Icon(Icons.route_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _CostBreakdown(
            vehicle: widget.vehicle,
            cost: cost,
            priceIsFallback: widget.appState.fuelPrice.isFallback,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: distanceIsValid && widget.vehicle.canBeBooked
                ? () => _confirmBooking(cost)
                : null,
            icon: const Icon(Icons.payment_rounded),
            label: const Text('Review and continue to payment'),
          ),
          const SizedBox(height: 10),
          Text(
            'Actual fuel or charging cost may vary with traffic, road conditions, charging operator and driving behaviour.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade600),
          ),
          const SizedBox(height: 24),
          SectionHeading(
            title: 'Customer reviews',
            subtitle: reviews.isEmpty
                ? 'No completed-rental reviews yet'
                : '${reviews.length} verified completed-rental ${reviews.length == 1 ? 'review' : 'reviews'}',
          ),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Customers can review this vehicle after a completed booking.',
              ),
            )
          else
            for (final review in reviews.take(3))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              review.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          for (var star = 1; star <= 5; star++)
                            Icon(
                              star <= review.rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 16,
                              color: Colors.amber.shade700,
                            ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(review.comment),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isPickup}) async {
    final initial = isPickup ? _pickupDate : _returnDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      if (isPickup) {
        _pickupDate = selected;
        if (!_returnDate.isAfter(_pickupDate)) {
          _returnDate = _pickupDate.add(const Duration(days: 1));
        }
      } else if (selected.isAfter(_pickupDate)) {
        _returnDate = selected;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Return date must be after the pickup date.'),
          ),
        );
      }
    });
  }

  Future<void> _confirmBooking(TripCost cost) async {
    final distance = double.tryParse(_distanceController.text) ?? 0;
    if (distance < CostCalculationService.minimumExpectedDistanceKm ||
        distance > CostCalculationService.maximumExpectedDistanceKm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a distance from 1 to 5,000 km.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.vehicle.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('${formatDate(_pickupDate)} → ${formatDate(_returnDate)}'),
            Text('${distance.toStringAsFixed(0)} km estimated journey'),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(child: Text('Estimated trip total')),
                Text(
                  formatRinggit(cost.totalCost),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue to payment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    if (!widget.appState.isVehicleAvailable(
      widget.vehicle.id,
      _pickupDate,
      _returnDate,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This vehicle is already booked for those dates.'),
        ),
      );
      return;
    }

    final payment = await Navigator.of(context).push<PaymentResult>(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          vehicle: widget.vehicle,
          pickupDate: _pickupDate,
          returnDate: _returnDate,
          expectedDistanceKm: distance,
          cost: cost,
        ),
      ),
    );
    if (payment?.succeeded != true || !mounted) {
      return;
    }

    try {
      final booking = widget.appState.addBooking(
        vehicle: widget.vehicle,
        pickup: _pickupDate,
        returnDate: _returnDate,
        expectedDistanceKm: distance,
        paymentReference: payment!.id,
      );
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.primary,
            size: 52,
          ),
          title: const Text('Booking confirmed'),
          content: Text(
            'Booking ${booking.id}\nTest payment ${payment.id}\n\nYour paid test booking is now saved.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('View booking'),
            ),
          ],
        ),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.appState.setNavigationIndex(2);
      }
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E9E6)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 21, color: AppTheme.primary),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DateInput extends StatelessWidget {
  const _DateInput({
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
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
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

class _CostBreakdown extends StatelessWidget {
  const _CostBreakdown({
    required this.vehicle,
    required this.cost,
    required this.priceIsFallback,
  });

  final Vehicle vehicle;
  final TripCost cost;
  final bool priceIsFallback;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _CostRow(
              label: 'Vehicle rental (${cost.rentalDays} days)',
              value: cost.rentalCost,
            ),
            const SizedBox(height: 11),
            _CostRow(
              label: vehicle.isElectric
                  ? 'Estimated charging'
                  : 'Estimated fuel',
              value: cost.energyCost,
              detail:
                  '${cost.energyQuantity.toStringAsFixed(1)} ${cost.energyUnit} × ${formatRinggit(cost.energyRate)}',
            ),
            const SizedBox(height: 11),
            _CostRow(label: 'Protection plan', value: cost.insuranceCost),
            const SizedBox(height: 11),
            _CostRow(label: 'Service fee', value: cost.serviceFee),
            const Divider(height: 26),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Estimated trip total',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  formatRinggit(cost.totalCost),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (vehicle.isElectric || priceIsFallback) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  vehicle.isElectric
                      ? 'Charging uses SmartRent MY’s configured estimate of RM1.20/kWh; it is not government fuel-price data.'
                      : 'The live API is unavailable, so this calculation currently uses clearly labelled demonstration fuel values.',
                  style: const TextStyle(
                    color: Color(0xFF7C4A03),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.label, required this.value, this.detail});

  final String label;
  final double value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              if (detail != null)
                Text(
                  detail!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blueGrey.shade600,
                  ),
                ),
            ],
          ),
        ),
        Text(
          formatRinggit(value),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
