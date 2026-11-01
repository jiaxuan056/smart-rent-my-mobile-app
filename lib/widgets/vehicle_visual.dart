import 'dart:io';

import 'package:flutter/material.dart';

import '../models/vehicle.dart';

class VehicleVisual extends StatelessWidget {
  const VehicleVisual({
    super.key,
    required this.vehicle,
    this.height = 145,
    this.showDetails = true,
  });

  final Vehicle vehicle;
  final double height;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final color = Color(vehicle.colorValue);
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _VehicleImage(vehicle: vehicle, color: color),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0x0D000000),
                    Color(0x52000000),
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
            if (showDetails)
              Positioned(
                left: 14,
                top: 14,
                child: _VisualBadge(label: vehicle.category),
              ),
            if (showDetails)
              Positioned(
                right: 14,
                bottom: 14,
                child: _VisualBadge(label: vehicle.powertrain.filterLabel),
              ),
          ],
        ),
      ),
    );
  }
}

class _VehicleImage extends StatelessWidget {
  const _VehicleImage({required this.vehicle, required this.color});

  final Vehicle vehicle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final localPath = vehicle.imageLocalPath;
    if (localPath != null && File(localPath).existsSync()) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        alignment: Alignment.center,
        semanticLabel: '${vehicle.name} rental vehicle',
        errorBuilder: (_, _, _) => _fallbackOrNetwork(),
      );
    }
    return _fallbackOrNetwork();
  }

  Widget _fallbackOrNetwork() {
    final url = vehicle.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        semanticLabel: '${vehicle.name} rental vehicle',
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return const ColoredBox(
            color: Color(0xFFE8EEEC),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (_, _, _) => _assetOrFallback(),
      );
    }
    return _assetOrFallback();
  }

  Widget _assetOrFallback() {
    if (vehicle.imageAsset.isNotEmpty) {
      return Image.asset(
        vehicle.imageAsset,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        semanticLabel: '${vehicle.name} rental vehicle',
        errorBuilder: (_, _, _) =>
            _ImageFallback(color: color, isElectric: vehicle.isElectric),
      );
    }
    return _ImageFallback(color: color, isElectric: vehicle.isElectric);
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.color, required this.isElectric});

  final Color color;
  final bool isElectric;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.28) ?? color],
        ),
      ),
      child: Center(
        child: Icon(
          isElectric
              ? Icons.electric_car_rounded
              : Icons.directions_car_filled_rounded,
          size: 72,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _VisualBadge extends StatelessWidget {
  const _VisualBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF18302C),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
