import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../services/wallet_service.dart' as wallet_service;
import '../utils/text_input_formatters.dart';
import 'dary_loading_indicator.dart';

class PaymentModal extends StatefulWidget {
  final double amount;
  final Function(bool success) onPaymentComplete;

  const PaymentModal({
    super.key,
    required this.amount,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  
  bool _isProcessing = false;
  bool _isSuccess = false;
  String? _errorMessage;

  AppLocalizations? get l10n => AppLocalizations.of(context);

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: _isSuccess ? _buildSuccessView() : _buildPaymentForm(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: Color(0xFF01352D),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n?.paymentSuccessful ?? 'Payment Successful!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF01352D),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n?.addedToWallet('${NumberFormat('#,###').format(widget.amount)} ${l10n?.currencyLYD ?? "LYD"}') ?? '${NumberFormat('#,###').format(widget.amount)} LYD has been added to your wallet.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onPaymentComplete(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF01352D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(l10n?.continueText ?? 'Continue'),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.credit_card, color: Color(0xFF01352D)),
              const SizedBox(width: 8),
              Text(
                l10n?.payWithCard ?? 'Pay with Card',
                style: const TextStyle(
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
          const SizedBox(height: 8),
          Text(
            l10n?.amountLabel('${NumberFormat('#,###').format(widget.amount)} ${l10n?.currencyLYD ?? "LYD"}') ?? 'Amount: ${NumberFormat('#,###').format(widget.amount)} LYD',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF01352D),
            ),
          ),
          const SizedBox(height: 24),

          // Card Number
          TextFormField(
            controller: _cardNumberController,
            decoration: InputDecoration(
              labelText: l10n?.cardNumber ?? 'Card Number',
              hintText: '1234 5678 9012 3456',
              prefixIcon: const Icon(Icons.credit_card),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(19),
              CardNumberInputFormatter(),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n?.enterCardNumber ?? 'Please enter card number';
              }
              if (value.replaceAll(' ', '').length < 13) {
                return l10n?.cardTooShort ?? 'Card number must be at least 13 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Expiry Date and CVV
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryDateController,
                  decoration: InputDecoration(
                    labelText: l10n?.expiryDate ?? 'Expiry Date',
                    hintText: 'MM/YY',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    ExpiryDateInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n?.requiredField ?? 'Required';
                    }
                    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                      return l10n?.invalidFormat ?? 'Invalid format';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: InputDecoration(
                    labelText: l10n?.cvv ?? 'CVV',
                    hintText: '123',
                    prefixIcon: const Icon(Icons.security),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n?.requiredField ?? 'Required';
                    }
                    if (value.length < 3) {
                      return l10n?.tooShort ?? 'Too short';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cardholder Name
          TextFormField(
            controller: _cardholderNameController,
            inputFormatters: [BasicTextFormatter()],
            decoration: InputDecoration(
              labelText: l10n?.cardholderName ?? 'Cardholder Name',
              hintText: 'John Doe',
              prefixIcon: const Icon(Icons.person),
              border: const OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n?.enterCardholderName ?? 'Please enter cardholder name';
              }
              if (value.trim().split(' ').length < 2) {
                return l10n?.enterFullName ?? 'Please enter full name';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Error Message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Payment Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF01352D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: DaryLoadingIndicator(
                            size: 20,
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(l10n?.processing ?? 'Processing...'),
                      ],
                    )
                  : Text(l10n?.payNow ?? 'Pay Now'),
            ),
          ),
          const SizedBox(height: 16),

          // Test Cards Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      l10n?.testCards ?? 'Test Cards',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.testCardsInfo ?? 'Success: 4242 4242 4242 4242\nDecline: 4000 0000 0000 0002\nExpired: 4000 0000 0000 0069',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final success = await wallet_service.WalletService().payWithCard(
        widget.amount,
        cardNumber: _cardNumberController.text,
        expiryDate: _expiryDateController.text,
        cvv: _cvvController.text,
        cardholderName: _cardholderNameController.text,
      );

      if (success) {
        setState(() {
          _isSuccess = true;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _errorMessage = l10n?.paymentFailed ?? 'Payment failed. Please check your card details and try again.';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = l10n?.errorOccurred ?? 'An error occurred. Please try again.';
        _isProcessing = false;
      });
    }
  }
}

/// Input formatter for card numbers
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Input formatter for expiry dates
class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        buffer.write('/');
      }
      buffer.write(text[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
