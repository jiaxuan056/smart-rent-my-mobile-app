import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/formatters.dart';
import '../../models/booking.dart';
import '../../state/app_state.dart';
import '../../widgets/vehicle_visual.dart';
import '../receipt_screen.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'All';
  String _sort = 'Newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final records = _records();
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking records',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${records.length} of ${widget.appState.allBookings.length} records',
                  style: TextStyle(color: Colors.blueGrey.shade600),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Booking ID, customer, vehicle or payment',
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                        ),
                        items:
                            const [
                                  'All',
                                  'Confirmed',
                                  'Ongoing',
                                  'Completed',
                                  'Cancelled',
                                ]
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) =>
                            setState(() => _statusFilter = value ?? 'All'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _sort,
                        decoration: const InputDecoration(
                          labelText: 'Sort',
                          isDense: true,
                        ),
                        items: const ['Newest', 'Pickup date', 'Highest total']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _sort = value ?? 'Newest'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: records.isEmpty
                ? const _NoAdminBookings()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 2, 18, 28),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _AdminBookingCard(
                      booking: records[index],
                      appState: widget.appState,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  List<Booking> _records() {
    final query = _searchController.text.trim().toLowerCase();
    final records = widget.appState.allBookings.where((booking) {
      final searchable = [
        booking.id,
        booking.customerName,
        booking.customerEmail,
        booking.vehicle.name,
        booking.paymentReference ?? '',
      ].join(' ').toLowerCase();
      final matchesStatus =
          _statusFilter == 'All' || booking.status.label == _statusFilter;
      return matchesStatus && (query.isEmpty || searchable.contains(query));
    }).toList();
    switch (_sort) {
      case 'Pickup date':
        records.sort((a, b) => a.pickupDate.compareTo(b.pickupDate));
      case 'Highest total':
        records.sort((a, b) => b.cost.totalCost.compareTo(a.cost.totalCost));
      default:
        records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return records;
  }
}

class _AdminBookingCard extends StatelessWidget {
  const _AdminBookingCard({required this.booking, required this.appState});

  final Booking booking;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final nextStatuses = BookingStatus.values
        .where(booking.status.canTransitionTo)
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 88,
                  child: VehicleVisual(
                    vehicle: booking.vehicle,
                    height: 72,
                    showDetails: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.vehicle.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(booking.customerName),
                      Text(
                        booking.id,
                        style: TextStyle(
                          color: Colors.blueGrey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: booking.status),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${formatDate(booking.pickupDate)} – ${formatDate(booking.returnDate)}',
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatRinggit(booking.cost.totalCost),
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showDetails(context),
                  child: const Text('Details'),
                ),
                if (nextStatuses.isNotEmpty)
                  PopupMenuButton<BookingStatus>(
                    tooltip: 'Update booking status',
                    onSelected: (status) => _confirmStatus(context, status),
                    itemBuilder: (_) => [
                      for (final status in nextStatuses)
                        PopupMenuItem(
                          value: status,
                          child: Text('Mark ${status.label.toLowerCase()}'),
                        ),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.edit_calendar_outlined),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStatus(
    BuildContext context,
    BookingStatus status,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update booking status?'),
        content: Text(
          'Change ${booking.id} from ${booking.status.label} to ${status.label}? The customer will receive an in-app notification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep current status'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Update status'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final error = appState.updateBookingStatus(booking.id, status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Booking status updated to ${status.label}.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          24 + MediaQuery.paddingOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.id,
              style: Theme.of(
                sheetContext,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            _DetailRow(label: 'Customer', value: booking.customerName),
            _DetailRow(label: 'Email', value: booking.customerEmail),
            _DetailRow(label: 'Vehicle', value: booking.vehicle.name),
            _DetailRow(label: 'Status', value: booking.status.label),
            _DetailRow(
              label: 'Rental dates',
              value:
                  '${formatDate(booking.pickupDate)} – ${formatDate(booking.returnDate)}',
            ),
            _DetailRow(
              label: 'Payment',
              value: booking.paymentReference ?? 'Not available',
            ),
            _DetailRow(
              label: 'Total',
              value: formatRinggit(booking.cost.totalCost),
            ),
            const SizedBox(height: 12),
            if (booking.paymentReference != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReceiptScreen(booking: booking),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_rounded),
                  label: const Text('Open receipt'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BookingStatus.confirmed => const Color(0xFF0369A1),
      BookingStatus.ongoing => AppTheme.primary,
      BookingStatus.completed => const Color(0xFF3F6212),
      BookingStatus.cancelled => const Color(0xFFB91C1C),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoAdminBookings extends StatelessWidget {
  const _NoAdminBookings();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No booking records match the current search and status filter.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
