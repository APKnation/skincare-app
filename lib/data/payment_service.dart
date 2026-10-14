import 'dart:async';
import 'dart:math';

import '../models/order.dart';

class PaymentPrompt {
  final PaymentMethod method;
  final String phone;
  final int amountTZS;
  final String reference;

  const PaymentPrompt({
    required this.method,
    required this.phone,
    required this.amountTZS,
    required this.reference,
  });
}

class PaymentOutcome {
  final bool success;
  final String? reference;
  final String message;

  const PaymentOutcome({required this.success, this.reference, required this.message});
}

/// Prototype payment gateway. In production this class is the client stub for
/// a backend that holds provider credentials, initiates STK-push / cash
/// requests, receives provider callbacks and performs the authoritative
/// verification — the app must never trust a client-side "paid" flag.
class PaymentService {
  final _rng = Random();

  PaymentPrompt createPrompt(PaymentMethod method, String phone, int amountTZS) {
    final tag = String.fromCharCode(65 + _rng.nextInt(26)) +
        String.fromCharCode(65 + _rng.nextInt(26)) +
        _rng.nextInt(9000 + 1000).toString();
    return PaymentPrompt(
      method: method,
      phone: phone,
      amountTZS: amountTZS,
      reference: 'SY${DateTime.now().millisecondsSinceEpoch}$tag',
    );
  }

  Future<PaymentOutcome> confirm(PaymentPrompt prompt, String pin) async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      return const PaymentOutcome(
        success: false,
        message: 'Enter the 4-digit mobile money PIN.',
      );
    }
    if (pin == '0000') {
      return const PaymentOutcome(
        success: false,
        message: 'Transaction declined on your handset. No money was moved.',
      );
    }
    return PaymentOutcome(
      success: true,
      reference: prompt.reference,
      message: 'Payment confirmed by ${prompt.method.label}.',
    );
  }
}
