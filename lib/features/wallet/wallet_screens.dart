import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/wallet.dart' as wallet_models;
import '../../widgets/transaction_card.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/moamalat_payment_screen.dart';
import '../../widgets/dary_loading_indicator.dart';
import '../../services/wallet_service.dart' as wallet_service;
import '../../services/persistence_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/theme_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isRecharging = false;
  String? _vStatusMessage;
  bool? _vIsSuccess;
  double? _vRechargeAmount;
  DateTime? _startDate;
  DateTime? _endDate;
  wallet_models.TransactionType? _selectedType;

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
    _amountController.dispose();
    super.dispose();
  }

  void _showCreditCardRechargeDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF01352D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                     Transform.translate(
                      offset: const Offset(-10, -10),
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Container(
                          width: 50,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    Transform.rotate(
                      angle: 0.1,
                      child: Container(
                        width: 50,
                        height: 35,
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.sim_card, color: Colors.amber, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.localCreditCard ?? 'Local credit card',
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n?.amount ?? 'Amount',
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: ThemeService.getDynamicStyle(
                    context,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: ThemeService.getDynamicStyle(
                      context,
                      color: Colors.black54,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _amountController.clear();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        l10n?.cancel ?? 'Cancel',
                        style: ThemeService.getDynamicStyle(
                          context,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(_amountController.text);
                        if (amount != null && amount > 0) {
                          Navigator.pop(context);
                          _showPaymentModal(amount);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n?.pleaseEnterValidAmount ?? 'Please enter a valid amount')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1E1E1E),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        l10n?.recharge ?? 'Top up',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showVoucherRechargeDialog() {
    final l10n = AppLocalizations.of(context);
    
    // Reset status when opening
    setState(() {
      _vStatusMessage = null;
      _vIsSuccess = null;
      _vRechargeAmount = null;
    });

    showDialog(
      context: context,
      barrierDismissible: !_isRecharging,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Function to call _processRecharge and update dialog state
            Future<void> handleRecharge() async {
              setDialogState(() {
                _isRecharging = true;
                _vStatusMessage = null;
              });
              
              await _processRecharge();
              
              if (mounted) {
                setDialogState(() {}); // Rebuild with results
              }
            }

            return Dialog(
              backgroundColor: const Color(0xFF01352D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/dary_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.daryVouchers ?? 'DARY Vouchers',
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    if (_vIsSuccess != true) ...[
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          l10n?.enter13DigitCode ?? 'Enter 13-digit code',
                          style: ThemeService.getDynamicStyle(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        enabled: !_isRecharging,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(13),
                        ],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        maxLength: 13,
                      ),
                    ],
                    
                    // Status Box
                    if (_vStatusMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (_vIsSuccess ?? false) ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_vIsSuccess ?? false) ? Colors.green : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  (_vIsSuccess ?? false) ? Icons.check_circle : Icons.error,
                                  color: (_vIsSuccess ?? false) ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _vStatusMessage!,
                                    style: ThemeService.getDynamicStyle(
                                      context,
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_vIsSuccess == true && _vRechargeAmount != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${l10n?.amount ?? 'Amount'}: ${_vRechargeAmount!.toStringAsFixed(2)} LYD',
                                style: ThemeService.getDynamicStyle(
                                  context,
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n?.whereToBuyVouchers ?? 'Where to buy vouchers / أين يتم شراء القسائم ؟',
                        style: ThemeService.getDynamicStyle(
                          context,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                     ),
                     const SizedBox(height: 12),
                     Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.voucherPurchaseInstruction1 ?? '• Purchase from any store with Umbrella or Anis POS terminals.',
                              style: ThemeService.getDynamicStyle(
                                context,
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n?.voucherPurchaseInstruction2 ?? '• يمكنك الشراء من أي محل تتوفر لديه ماكينة دفع (المظلة) أو (أنيس).',
                              style: ThemeService.getDynamicStyle(
                                context,
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                     ),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isRecharging ? null : () {
                            _codeController.clear();
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            l10n?.cancel ?? 'Cancel',
                            style: ThemeService.getDynamicStyle(
                              context,
                              color: _isRecharging ? Colors.grey : Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isRecharging 
                              ? null 
                              : (_vIsSuccess == true 
                                  ? () => Navigator.of(context).pop() 
                                  : handleRecharge),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E1E1E),
                            disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isRecharging) ...[
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: DaryLoadingIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1E1E1E),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  l10n?.loading ?? 'Loading...',
                                  style: ThemeService.getDynamicStyle(
                                    context,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E1E1E),
                                  ),
                                ),
                              ] else ...[
                                Text(
                                  _vIsSuccess == true ? (l10n?.done ?? 'Done') : (l10n?.recharge ?? 'Top up'),
                                  style: ThemeService.getDynamicStyle(
                                    context,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E1E1E),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openWhatsAppSupport() async {
    const phoneNumber = '+218911322666';
    const message = 'Hello Dary Support! I would like to top up my wallet.';
    final uri = Uri.parse('https://wa.me/218911322666?text=${Uri.encodeComponent(message)}');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showLyPayDialog() {
    const iban = 'LY70025014146446643414015';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF01352D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.qr_code_scanner, color: Colors.teal, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.directSupport ?? 'Direct Support / الدعم الفني',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // IBAN Display with Copy Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          iban,
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(const ClipboardData(text: iban));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context)?.ibanCopied ?? 'IBAN copied to clipboard'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.copy, color: Colors.black54, size: 20),
                            const SizedBox(height: 2),
                            Text(
                              AppLocalizations.of(context)?.copy ?? 'Copy',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Cancel Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        AppLocalizations.of(context)?.cancel ?? 'Cancel',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRechargeOptionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF01352D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)?.selectChargeMethod ?? 'Select charge method',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildChargeMethodTile(
                  icon: Icons.credit_card,
                  iconColor: Colors.blue,
                  title: AppLocalizations.of(context)?.localCreditCard ?? 'Local credit card',
                  onTap: () {
                    Navigator.pop(context);
                    _showCreditCardRechargeDialog();
                  },
                ),
                const SizedBox(height: 12),
                _buildChargeMethodTile(
                  imageAsset: 'assets/images/dary_logo.png', // Using Dary logo
                  title: AppLocalizations.of(context)?.daryVouchers ?? 'DARY Vouchers',
                  onTap: () {
                    Navigator.pop(context); // Close bottom sheet
                    _showVoucherRechargeDialog(); // Open voucher dialog
                  },
                ),
                const SizedBox(height: 12),
                _buildChargeMethodTile(
                  icon: Icons.chat_rounded, // Chat icon for WhatsApp
                  iconColor: Colors.green,
                  title: AppLocalizations.of(context)?.customerSupport ?? 'Customer Support / الدعم الفني',
                  onTap: () {
                    Navigator.pop(context);
                    _openWhatsAppSupport();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChargeMethodTile({
    IconData? icon,
    Color? iconColor,
    String? imageAsset,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 32, // Card proportions roughly
                decoration: BoxDecoration(
                   color: Colors.grey[100],
                   borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: imageAsset != null
                    ? Image.asset(imageAsset, width: 32, height: 32, fit: BoxFit.contain)
                    : Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processRecharge() async {
    final l10n = AppLocalizations.of(context);
    
    if (_codeController.text.length != 13) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.pleaseEnterValid13DigitCode ?? 'Please enter a valid 13-digit code'),
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
        SnackBar(
          content: Text(l10n?.pleaseLoginToPurchase ?? 'Please login to recharge your wallet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isRecharging = true;
    });

    setState(() {
      _isRecharging = true;
    });

    try {
      // Use the same user ID logic as initialization
      final userId = currentUser.id;
      if (kDebugMode) {
        debugPrint('🔄 Attempting recharge for user: $userId with code: ${_codeController.text}');
      }
      
      final result = await walletService.rechargeWallet(userId, _codeController.text);
      final bool success = result['success'] ?? false;
      
      if (!mounted) return;
      
      if (success) {
        // Refresh wallet data to get updated balance
        await _refreshWallet();
        
        // Get the updated balance for the success message
        final double rechargeAmount = (result['amount'] ?? 0.0).toDouble();
        
        setState(() {
          _vIsSuccess = true;
          _vRechargeAmount = rechargeAmount;
          _vStatusMessage = l10n?.rechargeSuccessful ?? 'Recharge Successful';
        });
      } else {
        // Check the error message from wallet service or result
        final errorMessage = walletService.errorMessage;
        String displayMessage;
        
        if (errorMessage?.contains('already been redeemed') == true || result['error'] == 'Already used') {
          displayMessage = l10n?.voucherAlreadyRedeemed ?? 'This voucher has already been redeemed.';
        } else if (errorMessage?.contains('Invalid voucher') == true || result['error'] == 'Not found') {
          displayMessage = l10n?.invalidVoucherCode ?? 'Invalid voucher code. Please check and try again.';
        } else {
          displayMessage = errorMessage ?? (l10n?.invalidRechargeCode ?? 'Invalid recharge code. Please try again.');
        }
        
        setState(() {
          _vIsSuccess = false;
          _vStatusMessage = displayMessage;
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _vIsSuccess = false;
        _vStatusMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRecharging = false;
        });
      }
    }
  }

  void _showPaymentModal(double amount) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id ?? 'user_001';
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MoamalatPaymentScreen(
          amount: amount,
          userId: userId,
          onPaymentComplete: (bool success, Map<String, dynamic>? data) async {
            if (success) {
              // Give Firestore a moment to sync the background update from the iframe
              await Future.delayed(const Duration(milliseconds: 1500));
              await _refreshWallet();
              
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)?.paymentSuccessful ?? 'Payment successful! Your balance has been updated.'),
                    backgroundColor: const Color(0xFF01352D),
                  ),
                );
              }
            }
          },
          onPaymentError: (String error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Payment failed: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          onPaymentCancel: () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Check authentication
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    return Consumer<wallet_service.WalletService>(
      builder: (context, walletService, child) {
        final balance = walletService.currentWallet?.balance ?? 0.0;
        const currency = 'LYD';
        final allTransactions = walletService.transactions;
        final isLoading = walletService.isLoading;
        
        final transactions = allTransactions.where((t) {
          if (_startDate != null && t.createdAt.isBefore(_startDate!)) return false;
          if (_endDate != null && t.createdAt.isAfter(_endDate!.add(const Duration(days: 1)))) return false;
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: CustomScrollView(
            slivers: [
              // Modern Gradient App Bar
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF01352D),
                        Color(0xFF024035),
                        Color(0xFF015F4D),
                      ],
                    ),
                  ),
                  child: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -30,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n?.wallet ?? 'Wallet',
                                          style: ThemeService.getDynamicStyle(
                                            context,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l10n?.manageBalanceTransactions ?? 'Manage your balance and transactions',
                                          style: ThemeService.getDynamicStyle(
                                            context,
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  LanguageToggleButton(languageService: languageService),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              if (isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: DaryLoadingIndicator(
                      color: Color(0xFF01352D),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                // Balance Section - Card Style with Visa
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF01352D), Color(0xFF024638)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF01352D).withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card header with chip and logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Chip icon
                          Container(
                            width: 45,
                            height: 35,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.amber[300]!, Colors.amber[600]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.memory,
                                color: Colors.amber[900],
                                size: 20,
                              ),
                            ),
                          ),
                          // Visa logo
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VISA',
                              style: TextStyle(
                                color: Color(0xFF1A1F71),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Card number dots
                      Row(
                        children: [
                          for (int i = 0; i < 4; i++) ...[
                            Row(
                              children: List.generate(4, (index) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                              )),
                            ),
                            if (i < 3) const SizedBox(width: 12),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Balance
                      Text(
                        l10n?.currentBalance ?? 'Current Balance',
                        style: ThemeService.getBodyStyle(
                          context,
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$balance $currency',
                        style: ThemeService.getHeadingStyle(
                          context,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Recharge Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showRechargeOptionsModal,
                          icon: const Icon(Icons.add),
                          label: Text(
                            l10n?.recharge ?? 'Top up',
                            style: ThemeService.getBodyStyle(
                              context,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                            style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF01352D),
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
                              color: Colors.black,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.date_range, color: Color(0xFF01352D)),
                                onPressed: _selectDateRange,
                              ),
                              if (_startDate != null || _endDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear_all, color: Colors.red),
                                  onPressed: _clearFilters,
                                  tooltip: 'Clear Filters',
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (_startDate != null && _endDate != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Chip(
                            label: Text(
                              '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd').format(_endDate!)}',
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                            backgroundColor: const Color(0xFF01352D),
                            onDeleted: _clearFilters,
                            deleteIconColor: Colors.white,
                          ),
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
              ]),
            ),
          ],
        ),
      );
    },
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF01352D),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedType = null;
    });
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
              color: Color(0xFF01352D),
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
              color: Color(0xFF01352D),
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
