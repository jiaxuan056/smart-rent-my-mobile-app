import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/booking.dart';
import '../models/vehicle.dart';
import '../state/app_state.dart';
import '../widgets/vehicle_visual.dart';
import 'receipt_screen.dart';
import 'vehicle_details_screen.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final active = appState.activeBookings;
    final history = appState.bookingHistory;
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My bookings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${active.length} active · ${history.length} historical',
                    style: TextStyle(color: Colors.blueGrey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEEC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                tabs: [
                  Tab(text: 'Active (${active.length})'),
                  Tab(text: 'History (${history.length})'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _BookingList(
                    bookings: active,
                    appState: appState,
                    emptyTitle: 'No active rentals',
                    emptyMessage:
                        'Confirmed and ongoing bookings will appear here.',
                    onBrowse: () => appState.setNavigationIndex(1),
                  ),
                  _BookingList(
                    bookings: history,
                    appState: appState,
                    emptyTitle: 'No booking history',
                    emptyMessage:
                        'Completed and cancelled bookings will appear here.',
                    onBrowse: () => appState.setNavigationIndex(1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.appState,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onBrowse,
  });

  final List<Booking> bookings;
  final AppState appState;
  final String emptyTitle;
  final String emptyMessage;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return _EmptyBookings(
        title: emptyTitle,
        message: emptyMessage,
        onBrowse: onBrowse,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) =>
          _BookingCard(booking: bookings[index], appState: appState),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.appState});

  final Booking booking;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(booking.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.id,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    booking.status.label.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 108,
                  child: VehicleVisual(
                    vehicle: booking.vehicle,
                    height: 88,
                    showDetails: false,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.vehicle.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${formatDate(booking.pickupDate)} – ${formatDate(booking.returnDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${booking.expectedDistanceKm.toStringAsFixed(0)} km · ${booking.cost.rentalDays} days',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (booking.status.isActive) ...[
              const SizedBox(height: 16),
              _BookingProgress(status: booking.status),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete trip total',
                        style: TextStyle(fontSize: 11),
                      ),
                      Text(
                        formatRinggit(booking.cost.totalCost),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Booking actions',
                  onSelected: (value) => _handleAction(context, value),
                  itemBuilder: (_) => [
                    if (booking.paymentReference != null)
                      const PopupMenuItem(
                        value: 'receipt',
                        child: ListTile(
                          leading: Icon(Icons.qr_code_rounded),
                          title: Text('View receipt'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    if (booking.status == BookingStatus.confirmed)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: ListTile(
                          leading: Icon(Icons.cancel_outlined),
                          title: Text('Cancel booking'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    if (booking.status == BookingStatus.completed &&
                        !appState.hasReviewedBooking(booking.id))
                      const PopupMenuItem(
                        value: 'review',
                        child: ListTile(
                          leading: Icon(Icons.star_outline_rounded),
                          title: Text('Write review'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    if (booking.status.isClosed)
                      const PopupMenuItem(
                        value: 'again',
                        child: ListTile(
                          leading: Icon(Icons.replay_rounded),
                          title: Text('Rent again'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Actions'),
                        SizedBox(width: 4),
                        Icon(Icons.more_vert_rounded),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (booking.status == BookingStatus.completed &&
                appState.hasReviewedBooking(booking.id))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Review submitted',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String value) async {
    if (value == 'receipt') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReceiptScreen(booking: booking)),
      );
      return;
    }
    if (value == 'cancel') {
      await _askToCancel(context);
      return;
    }
    if (value == 'review') {
      await _writeReview(context);
      return;
    }
    if (value == 'again') {
      final vehicle = appState.allVehicles.firstWhere(
        (item) => item.id == booking.vehicle.id,
        orElse: () => booking.vehicle,
      );
      if (vehicle.availability == VehicleAvailability.deactivated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This vehicle is no longer offered.')),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              VehicleDetailsScreen(vehicle: vehicle, appState: appState),
        ),
      );
    }
  }

  Future<void> _askToCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: Text(
          'Cancel ${booking.vehicle.name} for ${formatDate(booking.pickupDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final error = appState.cancelBooking(booking.id);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _writeReview(BuildContext context) async {
    final result = await showDialog<_ReviewData>(
      context: context,
      builder: (_) => _ReviewDialog(vehicleName: booking.vehicle.name),
    );
    if (result == null || !context.mounted) {
      return;
    }
    final error = appState.submitReview(
      bookingId: booking.id,
      rating: result.rating,
      comment: result.comment,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Thank you. Your review was submitted.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _BookingProgress extends StatelessWidget {
  const _BookingProgress({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final current = status == BookingStatus.confirmed ? 0 : 1;
    const labels = ['Confirmed', 'Ongoing', 'Completed'];
    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: index <= current
                      ? AppTheme.primary
                      : const Color(0xFFDCE5E2),
                  child: Icon(
                    index <= current ? Icons.check_rounded : Icons.circle,
                    size: index <= current ? 16 : 7,
                    color: index <= current ? Colors.white : Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(labels[index], style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
          if (index < labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                color: index < current
                    ? AppTheme.primary
                    : const Color(0xFFDCE5E2),
              ),
            ),
        ],
      ],
    );
  }
}

class _ReviewData {
  const _ReviewData(this.rating, this.comment);

  final int rating;
  final String comment;
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.vehicleName});

  final String vehicleName;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Review ${widget.vehicleName}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var value = 1; value <= 5; value++)
                  IconButton(
                    tooltip: '$value stars',
                    onPressed: () => setState(() => _rating = value),
                    icon: Icon(
                      value <= _rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: Colors.amber.shade700,
                    ),
                  ),
              ],
            ),
            TextFormField(
              controller: _commentController,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Your review',
                hintText: 'Describe your rental experience',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                final length = value?.trim().length ?? 0;
                if (length < 5) {
                  return 'Write at least 5 characters.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() != true) {
              return;
            }
            Navigator.pop(
              context,
              _ReviewData(_rating, _commentController.text.trim()),
            );
          },
          child: const Text('Submit review'),
        ),
      ],
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings({
    required this.title,
    required this.message,
    required this.onBrowse,
  });

  final String title;
  final String message;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 44,
              backgroundColor: AppTheme.mint,
              child: Icon(
                Icons.calendar_month_outlined,
                size: 43,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.directions_car_outlined),
              label: const Text('Browse vehicles'),
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(BookingStatus status) {
  return switch (status) {
    BookingStatus.confirmed => const Color(0xFF0369A1),
    BookingStatus.ongoing => AppTheme.primary,
    BookingStatus.completed => const Color(0xFF3F6212),
    BookingStatus.cancelled => const Color(0xFFB91C1C),
  };
}
