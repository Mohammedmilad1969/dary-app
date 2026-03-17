import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../l10n/app_localizations.dart';
import '../services/theme_service.dart';
class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showTransactionDetails(context),
      borderRadius: BorderRadius.circular(8),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Transaction Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTransactionColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getTransactionIcon(),
                  color: _getTransactionColor(),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Transaction Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLocalizedTransactionDescription(context, transaction.description, transaction.amount),
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(context, transaction.createdAt),
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (transaction.referenceId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Ref: ${transaction.referenceId}',
                        style: ThemeService.getDynamicStyle(
                          context,
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Amount and Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transaction.amount > 0 ? '+' : ''}${transaction.amount.toStringAsFixed(0)} ${WalletService.currency}',
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: transaction.amount > 0 ? const Color(0xFF01352D) : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getLocalizedStatusText(context),
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getTransactionColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getTransactionIcon(), color: _getTransactionColor()),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getLocalizedTransactionDescription(context, transaction.description, transaction.amount),
                            style: ThemeService.getHeadingStyle(
                              context,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getLocalizedStatusText(context),
                            style: ThemeService.getDynamicStyle(
                              context,
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${transaction.amount > 0 ? '+' : ''}${transaction.amount.toStringAsFixed(0)} ${WalletService.currency}',
                      style: ThemeService.getHeadingStyle(
                        context,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: transaction.amount > 0 ? const Color(0xFF01352D) : Colors.red,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 48),
                _buildDetailItem(l10n?.date ?? 'Date', _formatDate(context, transaction.createdAt)),
                if (transaction.referenceId != null)
                  _buildDetailItem(l10n?.referenceId ?? 'Reference ID', transaction.referenceId!),
                
                // Metadata items
                if (transaction.metadata != null && transaction.metadata!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Additional Information',
                    style: ThemeService.getHeadingStyle(
                      context,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...transaction.metadata!.entries.map((entry) {
                    return _buildDetailItem(_capitalize(entry.key), entry.value.toString());
                  }).toList(),
                  const SizedBox(height: 16),
                  if (transaction.metadata!['support_id'] != null)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          final supportInfo = 'Transaction Info:\n'
                              'ID: ${transaction.id}\n'
                              'Ref: ${transaction.referenceId}\n'
                              'Amount: ${transaction.amount}\n'
                              'Support ID: ${transaction.metadata!['support_id']}\n'
                              'Metadata: ${transaction.metadata}';
                          Clipboard.setData(ClipboardData(text: supportInfo));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Support information copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16, color: Color(0xFF01352D)),
                        label: const Text(
                          'Copy info for Support',
                          style: TextStyle(color: Color(0xFF01352D), fontSize: 12),
                        ),
                      ),
                    ),
                ],
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF01352D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l10n?.close ?? 'Close'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }


  IconData _getTransactionIcon() {
    switch (transaction.type) {
      case TransactionType.recharge:
        return Icons.add_circle;
      case TransactionType.purchase:
        return Icons.shopping_cart;
      case TransactionType.refund:
        return Icons.refresh;
      case TransactionType.withdrawal:
        return Icons.account_balance;
      case TransactionType.deposit:
        return Icons.credit_card;
    }
  }

  Color _getTransactionColor() {
    switch (transaction.type) {
      case TransactionType.recharge:
        return const Color(0xFF01352D);
      case TransactionType.purchase:
        return Colors.orange;
      case TransactionType.refund:
        return Colors.blue;
      case TransactionType.withdrawal:
        return Colors.purple;
      case TransactionType.deposit:
        return Colors.teal;
    }
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case TransactionStatus.completed:
        return const Color(0xFF01352D);
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }

  String _getStatusText() {
    // Note: This method needs context for localization
    // For now, returning English. Will be updated to use localized strings.
    switch (transaction.status) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }

  String _getLocalizedStatusText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (transaction.status) {
      case TransactionStatus.completed:
        return l10n?.transactionCompleted ?? 'Completed';
      case TransactionStatus.pending:
        return l10n?.transactionPending ?? 'Pending';
      case TransactionStatus.failed:
        return l10n?.transactionFailed ?? 'Failed';
    }
  }

  String _formatDate(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final timeStr = DateFormat('hh:mm a', locale).format(date);

    if (difference.inDays == 0) {
      return l10n?.todayAt(timeStr) ?? 'Today $timeStr';
    } else if (difference.inDays == 1) {
      return l10n?.yesterdayAt(timeStr) ?? 'Yesterday $timeStr';
    } else if (difference.inDays < 7) {
      return l10n?.daysAgo(difference.inDays.toString()) ?? '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy • hh:mm a', locale).format(date);
    }
  }

  String _getLocalizedTransactionDescription(BuildContext context, String description, double amount) {
    if (description.isEmpty) return description;
    final l10n = AppLocalizations.of(context);
    
    // 1. Recharged via Moamalat Card
    if (description == 'Recharged via Moamalat Card') {
      return l10n?.transactionRechargeMoamalat ?? description;
    }
    
    // 2. Purchase [Package] - Add [Count] property slots
    final purchaseRegex = RegExp(r'^Purchase (.*) - Add (\d+) property slots$');
    final purchaseMatch = purchaseRegex.firstMatch(description);
    if (purchaseMatch != null) {
      final packageName = purchaseMatch.group(1) ?? '';
      final slotsCount = purchaseMatch.group(2) ?? '';
      return l10n?.transactionPurchaseSlots(_getLocalizedPackageName(context, packageName), slotsCount) ?? description;
    }
    
    // 3. Top Listing Purchase - [Name]
    if (description.startsWith('Top Listing Purchase - ')) {
      String name = description.replaceFirst('Top Listing Purchase - ', '');
      
      // Retroactive fix: If name is generic "Top Listing", try to infer from amount
      // (Prices: 20 -> Plus, 50 -> Emerald, 100 -> Premium, 300 -> Elite)
      if (name.toLowerCase().trim() == 'top listing') {
        final absAmount = amount.abs();
        if (absAmount == 20.0) name = 'Plus';
        else if (absAmount == 50.0) name = 'Emerald';
        else if (absAmount == 100.0) name = 'Premium';
        else if (absAmount == 300.0) name = 'Elite';
      }
      
      return l10n?.transactionTopListing(_getLocalizedPackageName(context, name)) ?? description;
    }
    
    // 4. Boost: [Package Name] (e.g., "Boost: Emerald", "Boost: Bronze")
    if (description.startsWith('Boost: ')) {
      final packageName = description.replaceFirst('Boost: ', '');
      return l10n?.transactionBoost(_getLocalizedPackageName(context, packageName)) ?? description;
    }
    
    // 5. Boost New Listing: Plus
    if (description == 'Boost New Listing: Plus') {
      return l10n?.transactionBoostPlus ?? description;
    }
    
    // 6. Fee Percentage
    if (description == 'Fee Percentage' || description.toLowerCase().contains('fee percentage')) {
      return l10n?.transactionFeePercentage ?? description;
    }
    
    // 7. Voucher Recharge
    if (description == 'Voucher Recharge') {
      return l10n?.transactionVoucherRecharge ?? description;
    }
    
    // 8. Admin Manual Credit
    if (description == 'Admin Manual Credit') {
      return l10n?.transactionAdminCredit ?? description;
    }
    
    // 9. Refund - [Reason]
    if (description.startsWith('Refund - ')) {
      final reason = description.replaceFirst('Refund - ', '');
      return l10n?.transactionRefund(reason) ?? description;
    }
    
    return description;
  }

  String _getLocalizedPackageName(BuildContext context, String name) {
    if (name.isEmpty) return name;
    final l10n = AppLocalizations.of(context);
    final normalized = name.toLowerCase().trim();
    
    // Boost package names
    if (normalized == 'emerald' || normalized.contains('emerald')) return l10n?.packageEmerald ?? name;
    if (normalized == 'bronze' || normalized.contains('bronze')) return l10n?.packageBronze ?? name;
    if (normalized == 'silver' || normalized.contains('silver')) return l10n?.packageSilver ?? name;
    if (normalized == 'gold' || normalized.contains('gold')) return l10n?.packageGold ?? name;
    
    // Slot package names
    if (normalized == 'starter') return l10n?.packageStarter ?? name;
    if (normalized == 'professional') return l10n?.packageProfessional ?? name;
    if (normalized == 'enterprise') return l10n?.packageEnterprise ?? name;
    if (normalized == 'elite') return l10n?.packageElite ?? name;
    if (normalized == 'top listing') return l10n?.packageTopListing ?? name;
    
    // Handle durations in names
    if (normalized.contains('1 day')) return name.replaceFirst(RegExp('1 [Dd]ay', caseSensitive: false), l10n?.package1Day ?? '1 Day');
    if (normalized.contains('3 days')) return name.replaceFirst(RegExp('3 [Dd]ays', caseSensitive: false), l10n?.package3Days ?? '3 Days');
    if (normalized.contains('1 week')) return name.replaceFirst(RegExp('1 [Ww]eek', caseSensitive: false), l10n?.package1Week ?? '1 Week');
    if (normalized.contains('1 month')) return name.replaceFirst(RegExp('1 [Mm]onth', caseSensitive: false), l10n?.package1Month ?? '1 Month');
    if (normalized.contains('top listing')) return name.replaceFirst(RegExp('top listing', caseSensitive: false), l10n?.packageTopListing ?? 'Top Listing');

    return name;
  }
}
