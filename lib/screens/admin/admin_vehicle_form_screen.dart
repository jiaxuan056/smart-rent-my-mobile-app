import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/validators.dart';
import '../../models/vehicle.dart';
import '../../services/vehicle_photo_service.dart';
import '../../state/app_state.dart';

class AdminVehicleFormScreen extends StatefulWidget {
  const AdminVehicleFormScreen({
    super.key,
    required this.appState,
    this.vehicle,
    this.photoService = const VehiclePhotoService(),
  });

  final AppState appState;
  final Vehicle? vehicle;
  final VehiclePhotoService photoService;

  @override
  State<AdminVehicleFormScreen> createState() => _AdminVehicleFormScreenState();
}

class _AdminVehicleFormScreenState extends State<AdminVehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _categoryController;
  late final TextEditingController _rateController;
  late final TextEditingController _branchController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _efficiencyController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _sourceUrlController;
  late VehiclePowertrain _powertrain;
  late VehicleAvailability _availability;
  late String _transmission;
  late int _seats;
  String? _localImagePath;
  bool _isPickingPhoto = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    _brandController = TextEditingController(text: vehicle?.brand ?? '');
    _modelController = TextEditingController(text: vehicle?.model ?? '');
    _yearController = TextEditingController(
      text: '${vehicle?.year ?? DateTime.now().year}',
    );
    _categoryController = TextEditingController(text: vehicle?.category ?? '');
    _rateController = TextEditingController(
      text: vehicle?.dailyRate.toStringAsFixed(0) ?? '',
    );
    _branchController = TextEditingController(text: vehicle?.branch ?? '');
    _descriptionController = TextEditingController(
      text: vehicle?.description ?? '',
    );
    _efficiencyController = TextEditingController(
      text: vehicle?.isElectric == true
          ? vehicle?.energyKwhPer100Km?.toString() ?? ''
          : vehicle?.efficiencyKmPerLitre?.toString() ?? '',
    );
    _imageUrlController = TextEditingController(text: vehicle?.imageUrl ?? '');
    _sourceUrlController = TextEditingController(
      text: vehicle?.sourceUrl ?? '',
    );
    _powertrain = vehicle?.powertrain ?? VehiclePowertrain.petrolRon95;
    _availability = vehicle?.availability ?? VehicleAvailability.available;
    _transmission = vehicle?.transmission ?? 'Automatic';
    _seats = vehicle?.seats ?? 5;
    _localImagePath = vehicle?.imageLocalPath;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _categoryController.dispose();
    _rateController.dispose();
    _branchController.dispose();
    _descriptionController.dispose();
    _efficiencyController.dispose();
    _imageUrlController.dispose();
    _sourceUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.vehicle != null;
    final localFile = _localImagePath == null ? null : File(_localImagePath!);
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit vehicle' : 'Add vehicle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            if (localFile != null && localFile.existsSync()) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(localFile, height: 190, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _isPickingPhoto ? null : _pickPhoto,
              icon: _isPickingPhoto
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _localImagePath == null
                    ? 'Upload vehicle image'
                    : 'Replace vehicle image',
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Image URL (optional)',
                prefixIcon: Icon(Icons.link_rounded),
                helperText: 'Used when no uploaded image is selected',
              ),
              validator: _optionalUrl,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Brand'),
                    validator: (value) => AppValidators.requiredText(
                      value,
                      label: 'brand',
                      maximum: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Model'),
                    validator: (value) => AppValidators.requiredText(
                      value,
                      label: 'model',
                      maximum: 50,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: const InputDecoration(labelText: 'Year'),
                    validator: (value) {
                      final year = int.tryParse(value ?? '');
                      if (year == null ||
                          year < 2000 ||
                          year > DateTime.now().year + 1) {
                        return 'Use 2000–${DateTime.now().year + 1}.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Category'),
                    validator: (value) => AppValidators.requiredText(
                      value,
                      label: 'category',
                      maximum: 30,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<VehiclePowertrain>(
              initialValue: _powertrain,
              decoration: const InputDecoration(labelText: 'Powertrain'),
              items: VehiclePowertrain.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _powertrain = value ?? VehiclePowertrain.petrolRon95;
                  _efficiencyController.clear();
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _efficiencyController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,3}(\.\d{0,2})?'),
                ),
              ],
              decoration: InputDecoration(
                labelText: _powertrain == VehiclePowertrain.electric
                    ? 'Energy consumption'
                    : 'Fuel efficiency',
                suffixText: _powertrain == VehiclePowertrain.electric
                    ? 'kWh/100 km'
                    : 'km/L',
              ),
              validator: (value) => AppValidators.positiveNumber(
                value,
                label: _powertrain == VehiclePowertrain.electric
                    ? 'energy consumption'
                    : 'fuel efficiency',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _transmission,
                    decoration: const InputDecoration(
                      labelText: 'Transmission',
                    ),
                    items: const ['Automatic', 'Manual']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _transmission = value ?? 'Automatic'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _seats,
                    decoration: const InputDecoration(labelText: 'Seats'),
                    items: [
                      for (var value = 2; value <= 12; value++)
                        DropdownMenuItem(value: value, child: Text('$value')),
                    ],
                    onChanged: (value) => setState(() => _seats = value ?? 5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{0,5}(\.\d{0,2})?'),
                ),
              ],
              decoration: const InputDecoration(
                labelText: 'Daily rental rate',
                prefixText: 'RM ',
              ),
              validator: (value) =>
                  AppValidators.positiveNumber(value, label: 'daily rate'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _branchController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Pickup branch',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) => AppValidators.requiredText(
                value,
                label: 'pickup branch',
                maximum: 80,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Vehicle description',
                alignLabelWithHint: true,
              ),
              validator: (value) => AppValidators.requiredText(
                value,
                label: 'description',
                minimum: 20,
                maximum: 300,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Specification source URL (optional)',
                prefixIcon: Icon(Icons.source_outlined),
              ),
              validator: _optionalUrl,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<VehicleAvailability>(
              initialValue: _availability,
              decoration: const InputDecoration(labelText: 'Availability'),
              items: VehicleAvailability.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(
                () => _availability = value ?? VehicleAvailability.available,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(editing ? 'Save vehicle changes' : 'Add vehicle'),
            ),
          ],
        ),
      ),
    );
  }

  String? _optionalUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(text);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return 'Enter a complete http or https URL.';
    }
    return null;
  }

  Future<void> _pickPhoto() async {
    setState(() => _isPickingPhoto = true);
    try {
      final path = await widget.photoService.pickPhoto();
      if (path != null && mounted) {
        setState(() => _localImagePath = path);
      }
    } on VehiclePhotoException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    if (widget.vehicle == null &&
        _localImagePath == null &&
        _imageUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload an image or enter an image URL.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    final consumption = double.parse(_efficiencyController.text);
    final existing = widget.vehicle;
    final now = DateTime.now();
    final vehicle = Vehicle(
      id: existing?.id ?? 'fleet-${now.microsecondsSinceEpoch}',
      imageAsset: existing?.imageAsset ?? '',
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? existing?.imageUrl
          : _imageUrlController.text.trim(),
      imageLocalPath: _localImagePath,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      year: int.parse(_yearController.text),
      category: _categoryController.text.trim(),
      powertrain: _powertrain,
      transmission: _transmission,
      seats: _seats,
      dailyRate: double.parse(_rateController.text),
      branch: _branchController.text.trim(),
      rating: existing?.rating ?? 0,
      description: _descriptionController.text.trim(),
      colorValue: existing?.colorValue ?? AppTheme.primary.toARGB32(),
      efficiencyKmPerLitre: _powertrain == VehiclePowertrain.electric
          ? null
          : consumption,
      energyKwhPer100Km: _powertrain == VehiclePowertrain.electric
          ? consumption
          : null,
      sourceName: existing?.sourceName ?? 'SmartRent MY fleet record',
      sourceUrl: _sourceUrlController.text.trim().isEmpty
          ? existing?.sourceUrl
          : _sourceUrlController.text.trim(),
      availability: _availability,
      createdAt: existing?.createdAt ?? now,
    );
    final error = widget.appState.saveVehicle(vehicle);
    if (!mounted) {
      return;
    }
    setState(() => _isSaving = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    Navigator.pop(context, true);
  }
}
