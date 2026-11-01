import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/formatters.dart';
import '../models/booking.dart';

class ReceiptException implements Exception {
  const ReceiptException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReceiptService {
  const ReceiptService();

  static const _storageChannel = MethodChannel('smartrent_my/local_storage');

  String qrPayload(Booking booking) {
    return [
      'SMARTRENT-MY',
      booking.id,
      booking.customerEmail,
      booking.vehicle.id,
      booking.pickupDate.toIso8601String(),
      booking.returnDate.toIso8601String(),
      booking.status.name,
      booking.paymentReference ?? 'NO-PAYMENT-REFERENCE',
    ].join('|');
  }

  Future<String> savePdf(Booking booking) async {
    if (!Platform.isAndroid) {
      throw const ReceiptException(
        'PDF receipt saving is currently available on Android.',
      );
    }
    try {
      final root = await _storageChannel.invokeMethod<String>(
        'getAppFilesPath',
      );
      if (root == null || root.isEmpty) {
        throw const ReceiptException('Private receipt storage is unavailable.');
      }
      final directory = Directory('$root${Platform.pathSeparator}receipts');
      await directory.create(recursive: true);
      final safeId = booking.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final file = File(
        '${directory.path}${Platform.pathSeparator}$safeId.pdf',
      );
      final document = pw.Document(
        title: 'SmartRent MY receipt ${booking.id}',
        author: 'SmartRent MY',
      );
      document.addPage(
        pw.MultiPage(
          build: (_) => [
            pw.Text(
              'SmartRent MY',
              style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text('Digital booking receipt'),
            pw.Divider(height: 28),
            _row('Booking reference', booking.id),
            _row('Status', booking.status.label),
            _row('Customer', booking.customerName),
            _row('Email', booking.customerEmail),
            _row('Vehicle', booking.vehicle.name),
            _row('Pickup', formatDate(booking.pickupDate)),
            _row('Return', formatDate(booking.returnDate)),
            _row(
              'Expected distance',
              '${booking.expectedDistanceKm.toStringAsFixed(0)} km',
            ),
            _row('Rental', formatRinggit(booking.cost.rentalCost)),
            _row('Fuel / charging', formatRinggit(booking.cost.energyCost)),
            _row('Protection', formatRinggit(booking.cost.insuranceCost)),
            _row('Service fee', formatRinggit(booking.cost.serviceFee)),
            pw.Divider(height: 24),
            _row('Total', formatRinggit(booking.cost.totalCost), bold: true),
            _row(
              'Payment reference',
              booking.paymentReference ?? 'Not available',
            ),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: qrPayload(booking),
                width: 130,
                height: 130,
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              'This receipt records a simulated classroom payment and is not proof of a real financial charge.',
              style: const pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      );
      await file.writeAsBytes(await document.save(), flush: true);
      return file.path;
    } on ReceiptException {
      rethrow;
    } on MissingPluginException {
      throw const ReceiptException(
        'Restart the Android app before saving a receipt.',
      );
    } on PlatformException catch (error) {
      throw ReceiptException(
        error.message ?? 'The receipt could not be saved.',
      );
    } on FileSystemException {
      throw const ReceiptException('The PDF receipt could not be written.');
    } catch (_) {
      throw const ReceiptException('The PDF receipt could not be generated.');
    }
  }

  pw.Widget _row(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(width: 130, child: pw.Text(label)),
          pw.Expanded(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
            ),
          ),
        ],
      ),
    );
  }
}
