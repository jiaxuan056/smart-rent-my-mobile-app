import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/booking.dart';
import '../services/receipt_service.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({
    super.key,
    required this.booking,
    this.receiptService = const ReceiptService(),
  });

  final Booking booking;
  final ReceiptService receiptService;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Scaffold(
      appBar: AppBar(title: const Text('Digital receipt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: AppTheme.primary,
                    size: 42,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SmartRent MY',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text('Digital booking receipt'),
                  const Divider(height: 30),
                  _ReceiptRow(label: 'Booking', value: booking.id),
                  _ReceiptRow(label: 'Status', value: booking.status.label),
                  _ReceiptRow(label: 'Customer', value: booking.customerName),
                  _ReceiptRow(label: 'Vehicle', value: booking.vehicle.name),
                  _ReceiptRow(
                    label: 'Rental dates',
                    value:
                        '${formatDate(booking.pickupDate)} – ${formatDate(booking.returnDate)}',
                  ),
                  _ReceiptRow(
                    label: 'Distance',
                    value:
                        '${booking.expectedDistanceKm.toStringAsFixed(0)} km',
                  ),
                  const Divider(height: 24),
                  _ReceiptRow(
                    label: 'Vehicle rental',
                    value: formatRinggit(booking.cost.rentalCost),
                  ),
                  _ReceiptRow(
                    label: 'Fuel / charging',
                    value: formatRinggit(booking.cost.energyCost),
                  ),
                  _ReceiptRow(
                    label: 'Protection plan',
                    value: formatRinggit(booking.cost.insuranceCost),
                  ),
                  _ReceiptRow(
                    label: 'Service fee',
                    value: formatRinggit(booking.cost.serviceFee),
                  ),
                  const Divider(height: 24),
                  _ReceiptRow(
                    label: 'Total',
                    value: formatRinggit(booking.cost.totalCost),
                    emphasize: true,
                  ),
                  _ReceiptRow(
                    label: 'Payment reference',
                    value: booking.paymentReference ?? 'Not available',
                  ),
                  const SizedBox(height: 18),
                  Semantics(
                    label: 'QR code for booking ${booking.id}',
                    child: QrImageView(
                      data: widget.receiptService.qrPayload(booking),
                      version: QrVersions.auto,
                      size: 180,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppTheme.navy,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppTheme.navy,
                      ),
                    ),
                  ),
                  Text(
                    'Present this code with your booking reference during vehicle collection.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _isSaving ? null : _savePdf,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(_isSaving ? 'Saving receipt...' : 'Save PDF receipt'),
          ),
          const SizedBox(height: 10),
          Text(
            'This receipt records a simulated classroom payment. No real card was charged.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _savePdf() async {
    setState(() => _isSaving = true);
    try {
      final path = await widget.receiptService.savePdf(widget.booking);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Receipt saved privately at $path'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } on ReceiptException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.blueGrey.shade600),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: emphasize ? AppTheme.primary : null,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
                fontSize: emphasize ? 17 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
