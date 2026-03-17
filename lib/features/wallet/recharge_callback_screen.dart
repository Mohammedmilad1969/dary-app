import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/wallet_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dary_loading_indicator.dart';

class RechargeCallbackScreen extends StatefulWidget {
  final String? status;
  final String? message;

  const RechargeCallbackScreen({
    super.key,
    this.status,
    this.message,
  });

  @override
  State<RechargeCallbackScreen> createState() => _RechargeCallbackScreenState();
}

class _RechargeCallbackScreenState extends State<RechargeCallbackScreen> {
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _handleResult();
  }

  Future<void> _handleResult() async {
    // Wait a moment for Firestore to sync and for the user to see the redirection worked
    await Future.delayed(const Duration(seconds: 2));
    
    if (widget.status == 'success') {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final walletService = Provider.of<WalletService>(context, listen: false);
      
      if (authProvider.currentUser != null) {
        // Force refresh wallet data from Firestore
        await walletService.initialize(authProvider.currentUser!.id);
      }
    }
    
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
      
      if (widget.status == 'success') {
        _showFeedback(
          'Payment Successful!', 
          'Your balance has been updated. You can now use your credit.',
          Icons.check_circle_outline,
          Colors.green
        );
      } else if (widget.status == 'error') {
        _showFeedback(
          'Payment Failed', 
          widget.message ?? 'An error occurred during the transaction. Please try again.',
          Icons.error_outline,
          Colors.red
        );
      } else {
        context.go('/wallet');
      }
    }
  }

  void _showFeedback(String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/wallet');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF01352D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Back to Wallet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const DaryLoadingIndicator(
              color: Color(0xFF01352D),
            ),
            const SizedBox(height: 32),
            Text(
              _isProcessing ? 'Verifying payment...' : 'Verification complete',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF01352D),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please don\'t close the app',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
