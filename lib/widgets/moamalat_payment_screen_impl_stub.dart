
import 'package:flutter/material.dart';

/// Stub implementation for Moamalat Payment Screen
/// This file is used when neither web nor mobile implementations are available
/// or as a placeholder for the conditional import
class MoamalatPaymentScreenImpl extends StatelessWidget {
  final double amount;
  final String userId;
  final Function(bool success, Map<String, dynamic>? data) onPaymentComplete;
  final Function(String error) onPaymentError;
  final Function() onPaymentCancel;

  const MoamalatPaymentScreenImpl({
    super.key,
    required this.amount,
    required this.userId,
    required this.onPaymentComplete,
    required this.onPaymentError,
    required this.onPaymentCancel,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Platform not supported for payment'),
      ),
    );
  }
}
