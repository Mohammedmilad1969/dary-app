// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../l10n/app_localizations.dart';
import 'dary_loading_indicator.dart';

/// Web-specific Moamalat Payment implementation
/// Uses an iframe pointing to the dedicated payment_handler project
class MoamalatPaymentScreenImpl extends StatefulWidget {
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
  State<MoamalatPaymentScreenImpl> createState() => _MoamalatPaymentScreenImplState();
}

class _MoamalatPaymentScreenImplState extends State<MoamalatPaymentScreenImpl> {
  String? _viewId;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializePayment();
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _initializePayment() {
    _viewId = 'moamalat-payment-${DateTime.now().millisecondsSinceEpoch}';

    // Listen for messages from the iframe
    _messageSubscription = html.window.onMessage.listen((event) {
      final data = event.data;
      if (data != null && data is Map && data['type'] == 'payment_status') {
        final status = data['status'];
        final message = data['message'];
        
        if (status == 'success') {
          widget.onPaymentComplete(true, {
            'amount': data['amount'],
            'referenceId': data['merchantReference'],
            'txnDate': data['txnDate'],
            'status': status,
          });
        } else if (status == 'error') {
          widget.onPaymentError(message ?? 'Payment failed');
        } else if (status == 'cancel') {
          widget.onPaymentCancel();
        }
      }
    });

    // Register iframe pointing to the dedicated payment handler
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId!,
      (int viewId) {
        const baseUrl = 'https://www.dary.ly';
        final url = '$baseUrl/recharge.html?uid=${widget.userId}&amount=${widget.amount}';
        
        final iframe = html.IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'payment';
        
        return iframe;
      },
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.securePayment ?? 'Secure Payment'),
        backgroundColor: const Color(0xFF01352D),
        foregroundColor: Colors.white,
      ),
      body: _viewId != null
            ? HtmlElementView(viewType: _viewId!)
            : const Center(
                child: DaryLoadingIndicator(
                  color: Color(0xFF01352D),
                ),
              ),
    );
  }
}
