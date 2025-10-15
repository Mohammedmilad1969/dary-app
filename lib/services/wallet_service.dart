import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/wallet.dart' as wallet_models;
import '../services/persistence_service.dart';
import 'package:provider/provider.dart';

/// Firebase-based Wallet Service
/// 
/// Handles wallet operations with Firestore including balance management
/// and transaction history with real-time updates.
class WalletService extends ChangeNotifier {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  wallet_models.Wallet? _currentWallet;
  List<wallet_models.Transaction> _transactions = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<DocumentSnapshot>? _walletSubscription;
  StreamSubscription<QuerySnapshot>? _transactionsSubscription;

  wallet_models.Wallet? get currentWallet => _currentWallet;
  List<wallet_models.Transaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isLoading = loading;
      notifyListeners();
    });
  }

  void _setErrorMessage(String? message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _errorMessage = message;
      notifyListeners();
    });
  }

  /// Initialize wallet service for a user
  Future<void> initialize(String userId, {PersistenceService? persistenceService}) async {
    try {
      _setLoading(true);
      _setErrorMessage(null);

      // Get persistence service from parameter or create default
      final persistence = persistenceService ?? PersistenceService();

      // Load cached wallet data first
      final cachedBalance = await persistence.loadWalletBalance(userId);
      final cachedTransactions = await persistence.loadWalletTransactions(userId);
      
      if (cachedBalance > 0 || cachedTransactions.isNotEmpty) {
        _currentWallet = wallet_models.Wallet(
          userId: userId,
          balance: cachedBalance,
          currency: 'LYD',
          transactions: cachedTransactions,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        );
        _transactions = cachedTransactions;
        notifyListeners();
        
        if (kDebugMode) {
          debugPrint('💰 WalletService: Loaded cached wallet data - Balance: $cachedBalance LYD, Transactions: ${cachedTransactions.length}');
        }
      }

      // Cancel previous subscriptions to avoid memory leaks and duplicate listeners
      await _walletSubscription?.cancel();
      await _transactionsSubscription?.cancel();

      // Start listening to wallet document
      _walletSubscription = _firestore
          .collection('wallet')
          .doc(userId)
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data()!;
            _currentWallet = wallet_models.Wallet.fromFirestore(snapshot.id, data);
            
            // Cache the updated balance
            persistence.cacheWalletBalance(userId, _currentWallet!.balance);
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
            });
            
            if (kDebugMode) {
              debugPrint('💰 Wallet updated: ${_currentWallet!.balance} LYD');
            }
          } else {
            // Create wallet if it doesn't exist
            _createWallet(userId);
          }
        },
        onError: (error) {
          _setErrorMessage('Failed to load wallet: $error');
          if (kDebugMode) {
            debugPrint('❌ Wallet stream error: $error');
          }
        },
      );

      // Start listening to transactions
      _transactionsSubscription = _firestore
          .collection('wallet')
          .doc(userId)
          .collection('transactions')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          _transactions = snapshot.docs.map((doc) {
            final data = doc.data();
            return wallet_models.Transaction.fromFirestore(doc.id, data);
          }).toList();
          
          // Cache the updated transactions
          persistence.cacheWalletTransactions(userId, _transactions);
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
          
          if (kDebugMode) {
            debugPrint('📊 Transactions updated: ${_transactions.length} transactions');
          }
        },
        onError: (error) {
          if (kDebugMode) {
            debugPrint('❌ Transactions stream error: $error');
          }
        },
      );

      if (kDebugMode) {
        debugPrint('💰 WalletService initialized for user: $userId');
      }
    } catch (e) {
      _setErrorMessage('Failed to initialize WalletService: $e');
      if (kDebugMode) {
        debugPrint('❌ WalletService initialization error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new wallet for a user
  Future<void> _createWallet(String userId) async {
    try {
      await _firestore.collection('wallet').doc(userId).set({
        'balance': 0.0,
        'currency': 'LYD',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      if (kDebugMode) {
        debugPrint('💰 Created new wallet for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating wallet: $e');
      }
    }
  }

  /// Add a transaction to the wallet
  Future<bool> addTransaction({
    required String userId,
    required double amount,
    required wallet_models.TransactionType type,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate userId
      if (userId.isEmpty) {
        _setErrorMessage('User ID cannot be empty');
        if (kDebugMode) {
          debugPrint('❌ User ID is empty');
        }
        return false;
      }

      final transactionData = {
        'amount': amount,
        'type': type.name,
        'description': description,
        'metadata': metadata ?? {},
        'createdAt': Timestamp.now(),
      };

      // Ensure wallet document exists before updating
      final walletDoc = _firestore.collection('wallet').doc(userId);
      final walletSnapshot = await walletDoc.get();
      
      double currentBalance = 0.0;
      if (walletSnapshot.exists) {
        currentBalance = (walletSnapshot.data()?['balance'] ?? 0.0).toDouble();
      } else {
        // Create wallet if it doesn't exist
        await walletDoc.set({
          'balance': 0.0,
          'currency': 'LYD',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        if (kDebugMode) {
          debugPrint('💰 Created wallet document for user: $userId');
        }
      }

      // Add transaction to subcollection
      await walletDoc
          .collection('transactions')
          .add(transactionData);

      // Calculate new balance manually
      final newBalance = currentBalance + amount;
      
      // Update wallet balance
      await walletDoc.update({
        'balance': newBalance,
        'updatedAt': Timestamp.now(),
      });

      if (kDebugMode) {
        debugPrint('💰 Transaction added: $amount LYD - $description');
        debugPrint('💰 Updated wallet balance: $currentBalance + $amount = $newBalance LYD for user: $userId');
      }

      return true;
    } catch (e) {
      _setErrorMessage('Failed to add transaction: $e');
      if (kDebugMode) {
        debugPrint('❌ Error adding transaction: $e');
      }
      return false;
    }
  }

  /// Recharge wallet with a code
  Future<bool> rechargeWallet(String userId, String code) async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Attempting recharge for user: $userId with code: $code');
      }
      
      // Validate recharge code format (16 digits)
      if (code.length != 16 || !RegExp(r'^\d{16}$').hasMatch(code)) {
        _setErrorMessage('Invalid recharge code format');
        if (kDebugMode) {
          debugPrint('❌ Invalid code format: length=${code.length}, isNumeric=${RegExp(r'^\d{16}$').hasMatch(code)}');
        }
        return false;
      }

      // Simulate recharge amount (in real app, this would validate with payment provider)
      const double rechargeAmount = 25.0;

      if (kDebugMode) {
        debugPrint('💰 Adding recharge transaction: $rechargeAmount LYD');
      }

      // Add recharge transaction
      final success = await addTransaction(
        userId: userId,
        amount: rechargeAmount,
        type: wallet_models.TransactionType.recharge,
        description: 'Wallet Recharge',
        metadata: {'code': code, 'provider': 'mock'},
      );

      if (success) {
        if (kDebugMode) {
          debugPrint('💰 Wallet recharged: $rechargeAmount LYD for user: $userId');
        }
        // Force refresh the wallet data
        await initialize(userId);
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to add recharge transaction');
        }
      }

      return success;
    } catch (e) {
      _setErrorMessage('Failed to recharge wallet: $e');
      if (kDebugMode) {
        debugPrint('❌ Error recharging wallet: $e');
      }
      return false;
    }
  }

  /// Deduct amount from wallet (for purchases)
  Future<bool> deductAmount({
    required String userId,
    required double amount,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Check if user has sufficient balance
      if (_currentWallet != null && _currentWallet!.balance < amount) {
        _setErrorMessage('Insufficient balance');
        return false;
      }

      // Add deduction transaction
      final success = await addTransaction(
        userId: userId,
        amount: -amount, // Negative amount for deduction
        type: wallet_models.TransactionType.purchase,
        description: description,
        metadata: metadata,
      );

      if (success) {
        if (kDebugMode) {
          debugPrint('💰 Amount deducted: $amount LYD - $description');
        }
      }

      return success;
    } catch (e) {
      _setErrorMessage('Failed to deduct amount: $e');
      if (kDebugMode) {
        debugPrint('❌ Error deducting amount: $e');
      }
      return false;
    }
  }

  /// Get wallet balance
  double getCurrentBalance() {
    return _currentWallet?.balance ?? 0.0;
  }

  /// Get transactions for a specific period
  List<wallet_models.Transaction> getTransactionsForPeriod({
    DateTime? startDate,
    DateTime? endDate,
    wallet_models.TransactionType? type,
  }) {
    List<wallet_models.Transaction> filteredTransactions = _transactions;

    if (startDate != null) {
      filteredTransactions = filteredTransactions
          .where((t) => t.createdAt.isAfter(startDate))
          .toList();
    }

    if (endDate != null) {
      filteredTransactions = filteredTransactions
          .where((t) => t.createdAt.isBefore(endDate))
          .toList();
    }

    if (type != null) {
      filteredTransactions = filteredTransactions
          .where((t) => t.type == type)
          .toList();
    }

    return filteredTransactions;
  }

  /// Get total spent amount
  double getTotalSpent() {
    return _transactions
        .where((t) => t.amount < 0)
        .fold(0.0, (total, t) => total + t.amount.abs());
  }

  /// Get total earned amount
  double getTotalEarned() {
    return _transactions
        .where((t) => t.amount > 0)
        .fold(0.0, (total, t) => total + t.amount);
  }

  /// Transfer funds between users (future feature)
  Future<bool> transferFunds({
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String description,
  }) async {
    try {
      // Check if sender has sufficient balance
      if (_currentWallet != null && _currentWallet!.balance < amount) {
        _setErrorMessage('Insufficient balance for transfer');
        return false;
      }

      // Use batch write for atomic operation
      final batch = _firestore.batch();

      // Deduct from sender
      batch.update(
        _firestore.collection('wallet').doc(fromUserId),
        {
          'balance': FieldValue.increment(-amount),
          'updatedAt': Timestamp.now(),
        },
      );

      // Add to receiver
      batch.update(
        _firestore.collection('wallet').doc(toUserId),
        {
          'balance': FieldValue.increment(amount),
          'updatedAt': Timestamp.now(),
        },
      );

      // Add transaction records
      final transactionData = {
        'amount': -amount,
        'type': wallet_models.TransactionType.purchase.name, // Use purchase instead of transfer
        'description': 'Transfer to $toUserId: $description',
        'metadata': {'toUserId': toUserId},
        'createdAt': Timestamp.now(),
      };

      batch.set(
        _firestore
            .collection('wallet')
            .doc(fromUserId)
            .collection('transactions')
            .doc(),
        transactionData,
      );

      batch.set(
        _firestore
            .collection('wallet')
            .doc(toUserId)
            .collection('transactions')
            .doc(),
        {
          ...transactionData,
          'amount': amount,
          'description': 'Transfer from $fromUserId: $description',
          'metadata': {'fromUserId': fromUserId},
        },
      );

      await batch.commit();

      if (kDebugMode) {
        debugPrint('💰 Transfer completed: $amount LYD from $fromUserId to $toUserId');
      }

      return true;
    } catch (e) {
      _setErrorMessage('Failed to transfer funds: $e');
      if (kDebugMode) {
        debugPrint('❌ Error transferring funds: $e');
      }
      return false;
    }
  }

  /// Mock payment with card (placeholder for MomaLat/Stripe integration)
  Future<bool> payWithCard(
    double amount, {
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
  }) async {
    try {
      _setLoading(true);
      _setErrorMessage(null);

      // Simulate payment processing delay
      await Future.delayed(const Duration(milliseconds: 200));

      // Mock validation - accept any card for demo
      if (cardNumber.length >= 16 && cvv.length >= 3) {
        // Check if we have a valid user ID
        final userId = _currentWallet?.userId ?? '';
        if (userId.isEmpty) {
          if (kDebugMode) {
            debugPrint('❌ No user ID available for card payment');
          }
          return false;
        }
        
        // Add funds to wallet
        final success = await addTransaction(
          userId: userId,
          amount: amount,
          type: wallet_models.TransactionType.deposit,
          description: 'Card Payment - $cardholderName',
        );

        if (success) {
          if (kDebugMode) {
            debugPrint('💳 Card payment successful: $amount LYD');
          }
          // Force refresh the wallet data
          await initialize(_currentWallet?.userId ?? '');
          return true;
        }
      }

      if (kDebugMode) {
        debugPrint('❌ Card payment failed: Invalid card details');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Card payment error: $e');
      }
      _setErrorMessage('Payment failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    _walletSubscription?.cancel();
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}
