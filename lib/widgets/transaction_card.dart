import 'package:flutter/material.dart';
import '../models/wallet.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                color: _getTransactionColor().withOpacity(0.1),
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
                    transaction.description,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (transaction.referenceId != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Ref: ${transaction.referenceId}',
                      style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: transaction.amount > 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
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
    );
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
        return Colors.green;
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
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (transaction.status) {
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.failed:
        return 'Failed';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
