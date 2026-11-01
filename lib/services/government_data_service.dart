import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/fuel_price.dart';
import '../models/registration_record.dart';

class GovernmentDataException implements Exception {
  const GovernmentDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GovernmentDataService {
  static const String dataSource = 'data.gov.my';
  static const String fuelSource = 'Ministry of Finance Malaysia';
  static const String registrationSource =
      'Road Transport Department (JPJ) and Ministry of Transport';
  static const Set<String> supportedFuelTypes = {
    'petrol',
    'diesel',
    'electric',
    'hybrid_petrol',
    'hybrid_diesel',
  };

  Future<FuelPrice> fetchLatestFuelPrice() async {
    final uri = Uri.https('api.data.gov.my', '/data-catalogue', {
      'id': 'fuelprice',
      'ifilter': 'level@series_type',
      'sort': '-date',
      'limit': '1',
    });
    final rows = await _getRows(uri);
    if (rows.isEmpty) {
      throw const GovernmentDataException('No fuel-price records returned.');
    }
    return FuelPrice.fromJson(rows.first);
  }

  Future<List<RegistrationRecord>> fetchVehicleRegistrations() async {
    final currentYear = DateTime.now().year;
    final uri = Uri.https('api.data.gov.my', '/data-catalogue', {
      'id': 'registrations_type_fuel',
      'ifilter': 'car@type',
      'date_start': '${currentYear - 2}-01-01@date',
      'sort': '-date',
      'limit': '1000',
      'include': 'date,type,fuel,registrations',
    });
    final rows = await _getRows(uri);
    final records =
        rows
            .map(RegistrationRecord.fromJson)
            .where(
              (record) =>
                  supportedFuelTypes.contains(record.fuel) &&
                  record.registrations >= 0,
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    if (records.isEmpty) {
      throw const GovernmentDataException(
        'No vehicle-registration records returned.',
      );
    }
    return records;
  }

  Future<List<Map<String, dynamic>>> _getRows(Uri uri) async {
    final client = HttpClient()
      ..userAgent = 'SmartRentMY/1.0 university-mobile-assignment';
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 12));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) {
        throw GovernmentDataException(
          'Government API returned ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(body);
      final dynamic rows = decoded is List
          ? decoded
          : decoded is Map<String, dynamic>
          ? decoded['data'] ?? decoded['results']
          : null;
      if (rows is! List) {
        throw const GovernmentDataException(
          'Unexpected response from government API.',
        );
      }
      return rows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } on TimeoutException {
      throw const GovernmentDataException(
        'The government-data request timed out.',
      );
    } on SocketException {
      throw const GovernmentDataException(
        'No internet connection is available.',
      );
    } on FormatException {
      throw const GovernmentDataException(
        'The government API returned unreadable data.',
      );
    } finally {
      client.close(force: true);
    }
  }

  List<RegistrationRecord> fallbackRegistrations() {
    const values = <String, List<int>>{
      'petrol': [
        53200,
        49800,
        55100,
        52600,
        57400,
        56800,
        54100,
        58600,
        55900,
        60100,
        57800,
        61200,
      ],
      'diesel': [
        9300,
        8700,
        9600,
        9100,
        9900,
        10100,
        9700,
        10300,
        9800,
        10600,
        10200,
        10800,
      ],
      'electric': [
        2100,
        2300,
        2500,
        2750,
        2900,
        3200,
        3450,
        3700,
        4050,
        4300,
        4650,
        5100,
      ],
      'hybrid_petrol': [
        3300,
        3500,
        3700,
        3900,
        4100,
        4450,
        4600,
        4850,
        5100,
        5350,
        5600,
        5900,
      ],
      'hybrid_diesel': [
        180,
        170,
        190,
        185,
        205,
        210,
        220,
        215,
        230,
        240,
        235,
        250,
      ],
    };
    final now = DateTime.now();
    final records = <RegistrationRecord>[];
    for (final entry in values.entries) {
      for (var index = 0; index < entry.value.length; index++) {
        final monthsBack = entry.value.length - 1 - index;
        final date = DateTime(now.year, now.month - monthsBack, 1);
        records.add(
          RegistrationRecord(
            date: date,
            fuel: entry.key,
            registrations: entry.value[index],
          ),
        );
      }
    }
    return records;
  }
}
