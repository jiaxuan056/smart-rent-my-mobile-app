import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../state/app_state.dart';

class FuelPriceCard extends StatelessWidget {
  const FuelPriceCard({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final price = appState.fuelPrice;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppTheme.mint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_gas_station_rounded,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Official fuel prices',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        price.isFallback
                            ? 'Offline demonstration values'
                            : 'Effective ${formatDate(price.effectiveDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: price.isFallback
                              ? Colors.orange.shade800
                              : Colors.blueGrey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh official prices',
                  onPressed: appState.isFuelLoading
                      ? null
                      : appState.refreshFuelPrice,
                  icon: appState.isFuelLoading
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
            Row(
              children: [
                Expanded(
                  child: _PriceItem(
                    label: 'RON95',
                    value: price.ron95,
                    color: const Color(0xFF15803D),
                  ),
                ),
                Expanded(
                  child: _PriceItem(
                    label: 'RON97',
                    value: price.ron97,
                    color: const Color(0xFFB45309),
                  ),
                ),
                Expanded(
                  child: _PriceItem(
                    label: 'Diesel',
                    value: price.dieselPeninsular,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Ministry of Finance via data.gov.my · RM per litre',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ),
              ],
            ),
            if (appState.fuelError != null) ...[
              const SizedBox(height: 10),
              Text(
                '${appState.fuelError} Showing clearly labelled fallback values.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.orange.shade900),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceItem extends StatelessWidget {
  const _PriceItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.blueGrey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          formatRinggit(value).replaceFirst('RM ', 'RM'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
