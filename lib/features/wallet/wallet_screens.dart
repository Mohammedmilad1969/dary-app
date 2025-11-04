import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:dary/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/wallet.dart';
import '../../widgets/transaction_card.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/payment_modal.dart';
import '../../widgets/login_required_screen.dart';
import '../../services/wallet_service.dart' as wallet_service;
import '../../services/persistence_service.dart';
import '../../services/theme_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isRecharging = false;

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    // Get current user from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletService = Provider.of<wallet_service.WalletService>(context, listen: false);
    final persistenceService = Provider.of<PersistenceService>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    final userId = currentUser?.id ?? 'user_001';
    if (kDebugMode) {
      debugPrint('🔄 Initializing wallet for user: $userId (authenticated: ${currentUser != null})');
    }
    
    await walletService.initialize(userId, persistenceService: persistenceService);
    // Remove setState call to avoid build conflicts
  }

  Future<void> _refreshWallet() async {
    // Get current user from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletService = Provider.of<wallet_service.WalletService>(context, listen: false);
    final persistenceService = Provider.of<PersistenceService>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser != null) {
      // Refresh wallet with current user's ID
      await walletService.initialize(currentUser.id, persistenceService: persistenceService);
    }
    // Remove setState call to avoid build conflicts
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showRechargeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Recharge Wallet',
            style: ThemeService.getHeadingStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your 16-digit recharge code:',
                style: ThemeService.getBodyStyle(
                  context,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                style: ThemeService.getBodyStyle(
                  context,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: '1234567890123456',
                  hintStyle: ThemeService.getBodyStyle(
                    context,
                    color: Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  prefixIcon: Icon(Icons.credit_card, color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                ),
                maxLength: 16,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _codeController.clear();
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: ThemeService.getBodyStyle(
                  context,
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isRecharging ? null : _processRecharge,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isRecharging
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Recharge',
                      style: ThemeService.getBodyStyle(
                        context,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processRecharge() async {
    if (_codeController.text.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 16-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current user from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletService = Provider.of<wallet_service.WalletService>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to recharge your wallet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isRecharging = true;
    });

    try {
      // Use the same user ID logic as initialization
      final userId = currentUser?.id ?? 'user_001';
      if (kDebugMode) {
        debugPrint('🔄 Attempting recharge for user: $userId with code: ${_codeController.text}');
      }
      final success = await walletService.rechargeWallet(userId, _codeController.text);
      
      if (success) {
        Navigator.of(context).pop();
        _codeController.clear();
        
        // Refresh wallet data to get updated balance
        await _refreshWallet();
        
        // Get the updated balance for the success message
        final newBalance = walletService.currentWallet?.balance ?? 0.0;
        final currency = 'LYD';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wallet recharged successfully! New balance: $newBalance $currency'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid recharge code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing recharge: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRecharging = false;
      });
    }
  }

  void _showCardPaymentDialog() {
    final amounts = [20.0, 50.0, 100.0, 300.0];
    
    // First show amount selection dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.credit_card, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Select Amount',
                      style: ThemeService.getBodyStyle(
                        context,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Choose the amount you want to add to your wallet:',
                  style: ThemeService.getBodyStyle(context),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: amounts.length,
                  itemBuilder: (context, index) {
                    final amount = amounts[index];
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close amount selection
                        _showPaymentModal(amount); // Open payment modal with selected amount
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        '${NumberFormat('#,###').format(amount)} LYD',
                        style: ThemeService.getBodyStyle(
                          context,
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPaymentModal(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PaymentModal(
          amount: amount,
          onPaymentComplete: (bool success) {
            if (success) {
              _refreshWallet();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment successful! Funds added to wallet.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        );
      },
    );
  }

  void _showBankTransferDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Bank Transfer',
            style: ThemeService.getHeadingStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Bank transfer integration coming soon!\n\nThis feature will allow you to transfer funds directly from your bank account.',
                textAlign: TextAlign.center,
                style: ThemeService.getBodyStyle(
                  context,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: ThemeService.getBodyStyle(
                  context,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMobileMoneyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Mobile Money',
            style: ThemeService.getHeadingStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_android,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Mobile money integration coming soon!\n\nThis feature will support popular mobile payment services like MomaLat.',
                textAlign: TextAlign.center,
                style: ThemeService.getBodyStyle(
                  context,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: ThemeService.getBodyStyle(
                  context,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Check authentication
    if (!authProvider.isAuthenticated) {
      return LoginRequiredScreen(
        featureName: l10n?.wallet ?? 'Wallet',
        description: 'Please login to access your wallet and manage transactions',
      );
    }

    return Consumer<wallet_service.WalletService>(
      builder: (context, walletService, child) {
        final balance = walletService.currentWallet?.balance ?? 0.0;
        final currency = 'LYD';
        final transactions = walletService.transactions;
        final isLoading = walletService.isLoading;

    return Column(
      children: [
        AppBar(
          title: Text(
            l10n?.wallet ?? 'Wallet',
            style: ThemeService.getHeadingStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            LanguageToggleButton(languageService: languageService),
          ],
        ),
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                // Balance Section
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.green, Colors.greenAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                            Text(
                              l10n?.currentBalance ?? 'Current Balance',
                              style: ThemeService.getBodyStyle(
                                context,
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                      const SizedBox(height: 8),
                      Text(
                        '$balance $currency',
                        style: ThemeService.getHeadingStyle(
                          context,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Recharge Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showRechargeDialog,
                          icon: const Icon(Icons.add),
                          label: Text(
                            l10n?.recharge ?? 'Recharge',
                            style: ThemeService.getBodyStyle(
                              context,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Payment Methods Section
                      Text(
                        'Payment Methods',
                        style: ThemeService.getHeadingStyle(
                          context,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Card Payment Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showCardPaymentDialog,
                          icon: const Icon(Icons.credit_card),
                          label: Text(
                            'Pay with Card',
                            style: ThemeService.getBodyStyle(
                              context,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Bank Transfer Button (placeholder)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showBankTransferDialog,
                          icon: const Icon(Icons.account_balance),
                          label: Text(
                            'Bank Transfer',
                            style: ThemeService.getBodyStyle(
                              context,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Mobile Money Button (placeholder)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showMobileMoneyDialog,
                          icon: const Icon(Icons.phone_android),
                          label: Text(
                            'Mobile Money',
                            style: ThemeService.getBodyStyle(
                              context,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Transaction History Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                                Text(
                                  l10n?.transactionHistory ?? 'Transaction History',
                                  style: ThemeService.getHeadingStyle(
                                    context,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n?.exportTransactions ?? 'Export transactions'),
                                ),
                              );
                            },
                            child: Text(
                              l10n?.export ?? 'Export',
                              style: ThemeService.getBodyStyle(
                                context,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (transactions.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n?.noTransactionsYet ?? 'No transactions yet',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            return TransactionCard(
                              transaction: transactions[index],
                            );
                          },
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
      },
    );
  }
}

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'View your transaction history',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddFundsScreen extends StatelessWidget {
  const AddFundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Funds'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_card,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            Text(
              'Add Funds',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Top up your wallet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
