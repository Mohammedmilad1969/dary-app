import 'package:flutter/material.dart';
import 'dary_loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mobile-specific Moamalat Payment implementation
/// Launches external browser for payment processing
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
  bool _browserLaunched = false;

  @override
  void initState() {
    super.initState();
    _launchPaymentBrowser();
  }

  Future<void> _launchPaymentBrowser() async {
    // New dedicated payment handler URL (independent of dary_web)
    // You should deploy the 'payment_handler' folder to this site
    const baseUrl = 'https://www.dary.ly';
    final url = Uri.parse('$baseUrl/recharge.html?uid=${widget.userId}&amount=${widget.amount}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      setState(() {
        _browserLaunched = true;
      });
    } else {
      widget.onPaymentError('Could not launch payment browser');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Redirect'),
        backgroundColor: const Color(0xFF01352D),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.open_in_browser, size: 64, color: Color(0xFF01352D)),
              const SizedBox(height: 24),
              const Text(
                'Completing payment in your browser...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'You will be automatically redirected back to the app once the payment is finished.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_browserLaunched)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Return to Wallet'),
                ),
              const SizedBox(height: 16),
              const DaryLoadingIndicator(
                color: Color(0xFF01352D),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


