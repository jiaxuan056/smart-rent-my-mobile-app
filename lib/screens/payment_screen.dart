import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/input_formatters.dart';
import '../core/validators.dart';
import '../models/payment_result.dart';
import '../models/vehicle.dart';
import '../services/cost_calculation_service.dart';
import '../services/simulated_stripe_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.vehicle,
    required this.pickupDate,
    required this.returnDate,
    required this.expectedDistanceKm,
    required this.cost,
    this.paymentService = const SimulatedStripeService(),
  });

  final Vehicle vehicle;
  final DateTime pickupDate;
  final DateTime returnDate;
  final double expectedDistanceKm;
  final TripCost cost;
  final SimulatedStripeService paymentService;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();

  bool _isProcessing = false;
  String? _errorMessage;
  PaymentResult? _result;

  @override
  void dispose() {
    _nameController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return PopScope(
      canPop: result == null,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: result == null,
          title: Text(result == null ? 'Test payment' : 'Payment complete'),
        ),
        body: result == null
            ? _PaymentForm(
                formKey: _formKey,
                nameController: _nameController,
                cardController: _cardController,
                expiryController: _expiryController,
                cvcController: _cvcController,
                vehicle: widget.vehicle,
                pickupDate: widget.pickupDate,
                returnDate: widget.returnDate,
                expectedDistanceKm: widget.expectedDistanceKm,
                cost: widget.cost,
                isProcessing: _isProcessing,
                errorMessage: _errorMessage,
                onFillSuccessCard: _fillSuccessfulTestCard,
                onFillDeclinedCard: _fillDeclinedTestCard,
                onPay: _processPayment,
              )
            : _PaymentSuccess(
                result: result,
                vehicle: widget.vehicle,
                onReturn: () => Navigator.pop(context, result),
              ),
      ),
    );
  }

  void _fillSuccessfulTestCard() {
    _nameController.text = 'Demo Student';
    _cardController.text = '4242 4242 4242 4242';
    _expiryController.text = '12/34';
    _cvcController.text = '123';
    setState(() => _errorMessage = null);
  }

  void _fillDeclinedTestCard() {
    _nameController.text = 'Demo Student';
    _cardController.text = '4000 0000 0000 0002';
    _expiryController.text = '12/34';
    _cvcController.text = '123';
    setState(() => _errorMessage = null);
  }

  Future<void> _processPayment() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      final result = await widget.paymentService.confirmTestPayment(
        amount: widget.cost.totalCost,
        cardNumber: _cardController.text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _isProcessing = false;
      });
    } on SimulatedPaymentException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isProcessing = false;
      });
    }
  }
}

class _PaymentForm extends StatelessWidget {
  const _PaymentForm({
    required this.formKey,
    required this.nameController,
    required this.cardController,
    required this.expiryController,
    required this.cvcController,
    required this.vehicle,
    required this.pickupDate,
    required this.returnDate,
    required this.expectedDistanceKm,
    required this.cost,
    required this.isProcessing,
    required this.errorMessage,
    required this.onFillSuccessCard,
    required this.onFillDeclinedCard,
    required this.onPay,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController cardController;
  final TextEditingController expiryController;
  final TextEditingController cvcController;
  final Vehicle vehicle;
  final DateTime pickupDate;
  final DateTime returnDate;
  final double expectedDistanceKm;
  final TripCost cost;
  final bool isProcessing;
  final String? errorMessage;
  final VoidCallback onFillSuccessCard;
  final VoidCallback onFillDeclinedCard;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4D8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF4D48B)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.science_outlined, color: Color(0xFF8A5B00)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Stripe test-mode simulation\nNo API request or real charge is made. Never enter a real card.',
                    style: TextStyle(
                      color: Color(0xFF6B4700),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: AppTheme.mint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_car_rounded,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${formatDate(pickupDate)} → ${formatDate(returnDate)} · ${expectedDistanceKm.toStringAsFixed(0)} km',
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 26),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Test payment total',
                          style: TextStyle(fontWeight: FontWeight.w800),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: formKey,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test card details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use only the test numbers provided below.',
                      style: TextStyle(color: Colors.blueGrey.shade600),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      enabled: !isProcessing,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [LengthLimitingTextInputFormatter(60)],
                      decoration: const InputDecoration(
                        labelText: 'Cardholder name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: AppValidators.cardholderName,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cardController,
                      enabled: !isProcessing,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [CardNumberInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Test card number',
                        hintText: '4242 4242 4242 4242',
                        prefixIcon: Icon(Icons.credit_card_rounded),
                      ),
                      validator: (value) {
                        final digits =
                            value?.replaceAll(RegExp(r'\D'), '') ?? '';
                        if (digits.length != 16) {
                          return 'Enter a 16-digit test card number.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: expiryController,
                            enabled: !isProcessing,
                            keyboardType: TextInputType.number,
                            inputFormatters: const [ExpiryDateInputFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Expiry',
                              hintText: 'MM/YY',
                            ),
                            validator: _validateExpiry,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: cvcController,
                            enabled: !isProcessing,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'CVC',
                              hintText: '123',
                            ),
                            validator: (value) {
                              if (value == null || value.length != 3) {
                                return 'Enter 3 digits.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: isProcessing ? null : onFillSuccessCard,
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Fill success card'),
                        ),
                        TextButton(
                          onPressed: isProcessing ? null : onFillDeclinedCard,
                          child: const Text('Fill declined card'),
                        ),
                      ],
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE9E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: isProcessing ? null : onPay,
            icon: isProcessing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.lock_outline_rounded),
            label: Text(
              isProcessing
                  ? 'Processing test payment…'
                  : 'Pay ${formatRinggit(cost.totalCost)} (test)',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Card details remain only in this screen and are discarded when you leave.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade600),
          ),
        ],
      ),
    );
  }

  static String? _validateExpiry(String? value) {
    final match = RegExp(r'^(0[1-9]|1[0-2])/(\d{2})$').firstMatch(value ?? '');
    if (match == null) {
      return 'Use MM/YY.';
    }
    final month = int.parse(match.group(1)!);
    final year = 2000 + int.parse(match.group(2)!);
    final now = DateTime.now();
    if (year < now.year || (year == now.year && month < now.month)) {
      return 'Card is expired.';
    }
    return null;
  }
}

class _PaymentSuccess extends StatelessWidget {
  const _PaymentSuccess({
    required this.result,
    required this.vehicle,
    required this.onReturn,
  });

  final PaymentResult result;
  final Vehicle vehicle;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                color: AppTheme.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.primary,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Test payment successful',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${formatRinggit(result.amount)} was simulated for ${vehicle.name}. No money was charged.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade700, height: 1.45),
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _SuccessRow(label: 'Status', value: 'SUCCEEDED · TEST'),
                    const SizedBox(height: 12),
                    _SuccessRow(
                      label: 'Test card',
                      value: '•••• ${result.cardLast4}',
                    ),
                    const SizedBox(height: 12),
                    _SuccessRow(label: 'Reference', value: result.id),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onReturn,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Return to SmartRent MY'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey.shade600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
