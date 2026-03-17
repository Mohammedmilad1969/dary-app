import 'package:flutter/material.dart';

import 'moamalat_payment_screen_impl_stub.dart'
    if (dart.library.js) 'moamalat_payment_screen_web.dart'
    if (dart.library.io) 'moamalat_payment_screen_mobile.dart';

/// Moamalat Payment Screen using Lightbox
/// Routes to platform-specific implementation
class MoamalatPaymentScreen extends StatelessWidget {
  final double amount;
  final String userId;
  final Function(bool success, Map<String, dynamic>? data) onPaymentComplete;
  final Function(String error) onPaymentError;
  final Function() onPaymentCancel;

  const MoamalatPaymentScreen({
    super.key,
    required this.amount,
    required this.userId,
    required this.onPaymentComplete,
    required this.onPaymentError,
    required this.onPaymentCancel,
  });

  @override
  Widget build(BuildContext context) {
    return MoamalatPaymentScreenImpl(
      amount: amount,
      userId: userId,
      onPaymentComplete: onPaymentComplete,
      onPaymentError: onPaymentError,
      onPaymentCancel: onPaymentCancel,
    );
  }
}
