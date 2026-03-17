import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  recharge,
  purchase,
  refund,
  withdrawal,
  deposit,
}

enum TransactionStatus {
  completed,
  pending,
  failed,
}

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime createdAt;
  final TransactionStatus status;
  final String? referenceId;
  final Map<String, dynamic>? metadata;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    required this.status,
    this.referenceId,
    this.metadata,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      type: _parseTransactionType(json['type']),
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['timestamp'] != null
              ? DateTime.parse(json['timestamp'])
              : json['created_at'] != null
                  ? DateTime.parse(json['created_at'])
                  : DateTime.now(),
      status: _parseTransactionStatus(json['status']),
      referenceId: json['reference_id'] ?? json['referenceId'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'amount': amount,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'referenceId': referenceId,
      'metadata': metadata,
    };
  }

  factory Transaction.fromFirestore(String id, Map<String, dynamic> data) {
    return Transaction(
      id: id,
      amount: (data['amount'] ?? 0).toDouble(),
      type: _parseTransactionType(data['type']),
      description: data['description'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      status: TransactionStatus.completed, // Default to completed for Firestore
      referenceId: data['referenceId'],
      metadata: data['metadata'],
    );
  }

  static TransactionType _parseTransactionType(dynamic type) {
    if (type == null) return TransactionType.recharge;
    final typeString = type.toString().toLowerCase();
    switch (typeString) {
      case 'recharge': case 'credit': return TransactionType.recharge;
      case 'purchase': case 'debit': return TransactionType.purchase;
      case 'refund': return TransactionType.refund;
      case 'withdrawal': return TransactionType.withdrawal;
      default: return TransactionType.recharge;
    }
  }

  static TransactionStatus _parseTransactionStatus(dynamic status) {
    if (status == null) return TransactionStatus.completed;
    final statusString = status.toString().toLowerCase();
    switch (statusString) {
      case 'completed': case 'success': return TransactionStatus.completed;
      case 'pending': return TransactionStatus.pending;
      case 'failed': case 'error': return TransactionStatus.failed;
      default: return TransactionStatus.completed;
    }
  }
}

class Wallet {
  final String userId;
  final double balance;
  final String currency;
  final List<Transaction> transactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.userId,
    required this.balance,
    required this.currency,
    required this.transactions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final List<dynamic> transactionsData = json['transactions'] ?? [];
    return Wallet(
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'LYD',
      transactions: transactionsData.map((data) => Transaction.fromJson(data)).toList(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  factory Wallet.fromFirestore(String userId, Map<String, dynamic> data) {
    return Wallet(
      userId: userId,
      balance: (data['balance'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'LYD',
      transactions: [], // Transactions are loaded separately from subcollection
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] is Timestamp 
              ? (data['createdAt'] as Timestamp).toDate() 
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] is Timestamp 
              ? (data['updatedAt'] as Timestamp).toDate() 
              : DateTime.tryParse(data['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}

class WalletService {
  static const double _currentBalance = 200.0;
  static const String _currency = 'LYD';

  static final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      type: TransactionType.recharge,
      amount: 50.0,
      description: 'Wallet Recharge',
      createdAt: DateTime(2024, 3, 15, 14, 30),
      status: TransactionStatus.completed,
      referenceId: 'RCH123456789',
    ),
    Transaction(
      id: '2',
      type: TransactionType.purchase,
      amount: -25.0,
      description: 'Property Listing Fee',
      createdAt: DateTime(2024, 3, 14, 10, 15),
      status: TransactionStatus.completed,
      referenceId: 'PUR987654321',
    ),
    Transaction(
      id: '3',
      type: TransactionType.recharge,
      amount: 100.0,
      description: 'Wallet Recharge',
      createdAt: DateTime(2024, 3, 10, 16, 45),
      status: TransactionStatus.completed,
      referenceId: 'RCH456789123',
    ),
    Transaction(
      id: '4',
      type: TransactionType.purchase,
      amount: -15.0,
      description: 'Premium Listing Upgrade',
      createdAt: DateTime(2024, 3, 8, 09, 20),
      status: TransactionStatus.completed,
      referenceId: 'PUR789123456',
    ),
    Transaction(
      id: '5',
      type: TransactionType.refund,
      amount: 10.0,
      description: 'Listing Refund',
      createdAt: DateTime(2024, 3, 5, 11, 30),
      status: TransactionStatus.completed,
      referenceId: 'REF321654987',
    ),
    Transaction(
      id: '6',
      type: TransactionType.recharge,
      amount: 75.0,
      description: 'Wallet Recharge',
      createdAt: DateTime(2024, 3, 1, 13, 15),
      status: TransactionStatus.completed,
      referenceId: 'RCH654987321',
    ),
    Transaction(
      id: '7',
      type: TransactionType.purchase,
      amount: -30.0,
      description: 'Property Listing Fee',
      createdAt: DateTime(2024, 2, 28, 15, 45),
      status: TransactionStatus.completed,
      referenceId: 'PUR147258369',
    ),
    Transaction(
      id: '8',
      type: TransactionType.withdrawal,
      amount: -50.0,
      description: 'Bank Transfer',
      createdAt: DateTime(2024, 2, 25, 12, 00),
      status: TransactionStatus.pending,
      referenceId: 'WTH369258147',
    ),
  ];

  static double get currentBalance => _currentBalance;
  static String get currency => _currency;
  static List<Transaction> get transactions => _transactions;

  static Future<bool> rechargeWallet(String code) async {
    // TODO: Implement actual recharge logic
    await Future.delayed(const Duration(seconds: 2));
    
    // Mock validation - accept any 16-digit code
    if (code.length == 16 && RegExp(r'^\d{16}$').hasMatch(code)) {
      return true;
    }
    return false;
  }

  static Future<List<Transaction>> fetchTransactions() async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 1));
    return _transactions;
  }
}
