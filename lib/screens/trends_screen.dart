import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/registration_record.dart';
import '../state/app_state.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  String _selectedFuel = 'electric';

  static const _fuelLabels = <String, String>{
    'petrol': 'Petrol',
    'diesel': 'Diesel',
    'electric': 'Electric',
    'hybrid': 'Hybrid',
  };

  @override
  Widget build(BuildContext context) {
    final records = widget.appState.trendFor(_selectedFuel);
    final latest = records.isEmpty ? 0 : records.last.registrations;
    final previous = records.length < 2
        ? latest
        : records[records.length - 2].registrations;
    final change = previous == 0 ? 0.0 : (latest - previous) / previous * 100;
    final total = records.fold<int>(
      0,
      (sum, record) => sum + record.registrations,
    );
    final selectedUsesFallback = _selectedFuel == 'hybrid'
        ? widget.appState.trendFallbackFuels.contains('hybrid_petrol') ||
              widget.appState.trendFallbackFuels.contains('hybrid_diesel')
        : widget.appState.trendFallbackFuels.contains(_selectedFuel);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: widget.appState.refreshTrends,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle trends',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppTheme.navy,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monthly Malaysian car registrations',
                        style: TextStyle(color: Colors.blueGrey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Refresh government data',
                  onPressed: widget.appState.isTrendLoading
                      ? null
                      : widget.appState.refreshTrends,
                  icon: widget.appState.isTrendLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final entry in _fuelLabels.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: _selectedFuel == entry.key,
                        onSelected: (_) =>
                            setState(() => _selectedFuel = entry.key),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (selectedUsesFallback)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFF4D99B)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 20,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        widget.appState.trendError == null
                            ? 'Demonstration trend values are shown until live data loads.'
                            : widget.appState.trendError!,
                        style: const TextStyle(
                          color: Color(0xFF744210),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _TrendStat(
                    label: 'Latest month',
                    value: formatInteger(latest),
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TrendStat(
                    label: 'Monthly change',
                    value:
                        '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%',
                    icon: change >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    valueColor: change >= 0
                        ? AppTheme.primary
                        : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TrendStat(
                    label: '12-month total',
                    value: _compactNumber(total),
                    icon: Icons.summarize_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_fuelLabels[_selectedFuel]} registrations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Latest 12 available monthly records',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 235,
                      child: records.isEmpty
                          ? const Center(child: Text('No records available'))
                          : CustomPaint(
                              size: const Size(double.infinity, 235),
                              painter: _TrendChartPainter(records),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.account_balance_rounded,
                          color: AppTheme.primary,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Official data transparency',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Source: Road Transport Department (JPJ) and Ministry of Transport via data.gov.my.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These figures measure vehicle registrations, not vehicle sales. Aggregate rows are excluded to prevent double-counting.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blueGrey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _compactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toString();
  }
}

class _TrendStat extends StatelessWidget {
  const _TrendStat({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: AppTheme.primary),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor ?? AppTheme.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 2,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.blueGrey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter(this.records);

  final List<RegistrationRecord> records;

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) {
      return;
    }
    const left = 8.0;
    const right = 8.0;
    const top = 10.0;
    const bottom = 35.0;
    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;
    final maxValue = records
        .map((record) => record.registrations)
        .fold<int>(1, math.max);
    final gridPaint = Paint()
      ..color = const Color(0xFFE5ECE9)
      ..strokeWidth = 1;

    for (var line = 0; line <= 4; line++) {
      final y = top + chartHeight * line / 4;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    final pointPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final fillPath = Path();
    final linePath = Path();

    for (var index = 0; index < records.length; index++) {
      final x = records.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * index / (records.length - 1);
      final ratio = records[index].registrations / maxValue;
      final y = top + chartHeight * (1 - ratio);
      if (index == 0) {
        linePath.moveTo(x, y);
        fillPath
          ..moveTo(x, top + chartHeight)
          ..lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4.3, pointPaint);
    }
    final lastX = records.length == 1
        ? left + chartWidth / 2
        : size.width - right;
    fillPath
      ..lineTo(lastX, top + chartHeight)
      ..close();
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x55006B5E), Color(0x05006B5E)],
      ).createShader(Rect.fromLTWH(left, top, chartWidth, chartHeight));
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    final labelIndexes = <int>{0, records.length ~/ 2, records.length - 1};
    for (final index in labelIndexes) {
      final x = records.length == 1
          ? left + chartWidth / 2
          : left + chartWidth * index / (records.length - 1);
      final painter = TextPainter(
        text: TextSpan(
          text: formatMonth(records[index].date),
          style: const TextStyle(color: Colors.blueGrey, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final constrainedX = (x - painter.width / 2)
          .clamp(0.0, size.width - painter.width)
          .toDouble();
      painter.paint(canvas, Offset(constrainedX, size.height - 19));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.records != records;
  }
}
