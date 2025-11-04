import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/wallet_service.dart' as wallet_service;

class PropertyPackage {
  final String name;
  final String description;
  final int limit;
  final double price;

  PropertyPackage({
    required this.name,
    required this.description,
    required this.limit,
    required this.price,
  });
}

class PropertyLimitModal extends StatefulWidget {
  final int currentLimit;
  final int currentProperties;
  final int maxLimit;

  const PropertyLimitModal({
    super.key,
    required this.currentLimit,
    required this.currentProperties,
    this.maxLimit = 20,
  });

  @override
  State<PropertyLimitModal> createState() => _PropertyLimitModalState();
}

class _PropertyLimitModalState extends State<PropertyLimitModal> {
  // Package definitions
  final List<PropertyPackage> _packages = [
    PropertyPackage(
      name: 'Starter Package',
      description: '1-15 properties',
      limit: 15,
      price: 100.0,
    ),
    PropertyPackage(
      name: 'Professional Package',
      description: '50 properties',
      limit: 50,
      price: 300.0,
    ),
    PropertyPackage(
      name: 'Enterprise Package',
      description: '50+ properties',
      limit: 100,
      price: 600.0,
    ),
  ];

  PropertyPackage? _selectedPackage;

  @override
  void initState() {
    super.initState();
    // Select first package by default
    _selectedPackage = _packages[0];
  }

  @override
  Widget build(BuildContext context) {
    final selectedPackage = _selectedPackage!;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upgrade Your Plan',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a package to increase your property limit',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Limit',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${widget.currentProperties} / ${widget.currentLimit} properties',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Package Selection
                      Text(
                        'Select a Package',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),

                      // Package Cards
                      ...(_packages.map((package) {
                        final isSelected = _selectedPackage == package;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPackage = package;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.green[50] : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.green[400]! : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.green[100] : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                                      color: isSelected ? Colors.green[700] : Colors.grey[600],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          package.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? Colors.green[900] : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          package.description,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${NumberFormat('#,###').format(package.price)} LYD',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.green[700] : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList()),
                      const SizedBox(height: 16),

                      // Price Information
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[100]!, Colors.green[50]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Package:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  selectedPackage.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'New limit:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  '${selectedPackage.limit} properties',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[900],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Price:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[900],
                                  ),
                                ),
                                Text(
                                  '${NumberFormat('#,###').format(selectedPackage.price)} LYD',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _handlePurchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Purchase',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

  Future<void> _handlePurchase() async {
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a package')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final walletService = Provider.of<wallet_service.WalletService>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final selectedPackage = _selectedPackage!;
    final totalPrice = selectedPackage.price;
    final currentBalance = walletService.getCurrentBalance();

    // Check balance
    if (currentBalance < totalPrice) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. You need ${NumberFormat('#,###').format(totalPrice)} LYD but have ${NumberFormat('#,###').format(currentBalance)} LYD'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Deduct from wallet
      final success = await walletService.deductAmount(
        userId: currentUser.id,
        amount: totalPrice,
        description: 'Purchase ${selectedPackage.name} - ${selectedPackage.description}',
        metadata: {
          'packageName': selectedPackage.name,
          'oldLimit': widget.currentLimit,
          'newLimit': selectedPackage.limit,
        },
      );

      if (!success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update user property limit in Firestore to the package limit
      await _updatePropertyLimit(currentUser.id, selectedPackage.limit);

      if (!mounted) return;

      // Wait longer for Firestore to propagate
      await Future.delayed(const Duration(milliseconds: 1500));

      // Force a fresh read from Firestore with a new query
      final authProviderAfter = Provider.of<AuthProvider>(context, listen: false);
      
      // Manually refresh from Firestore with a new document read
      try {
        final firestore = FirebaseFirestore.instance;
        final userDoc = await firestore.collection('users').doc(currentUser.id).get();
        if (userDoc.exists) {
          final updatedLimit = userDoc.data()?['propertyLimit'] as int?;
          if (kDebugMode) {
            debugPrint('🔍 Fresh read from Firestore: propertyLimit = $updatedLimit');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error reading from Firestore: $e');
        }
      }
      
      // Now refresh the auth provider
      await authProviderAfter.refreshUser();

      if (!mounted) return;

      // Debug: Check if limit was updated
      final updatedUser = authProviderAfter.currentUser;
      if (kDebugMode && updatedUser != null) {
        debugPrint('🔍 After purchase - Updated user limit check:');
        debugPrint('   Property Limit: ${updatedUser.propertyLimit} (expected: ${selectedPackage.limit})');
        debugPrint('   Total Listings: ${updatedUser.totalListings}');
      }

      // Close modal and show success
      Navigator.of(context).pop(true); // Return true to indicate purchase was made
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully purchased ${selectedPackage.name}! New limit: ${selectedPackage.limit} properties'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updatePropertyLimit(String userId, int newLimit) async {
    try {
      if (kDebugMode) {
        debugPrint('🔧 Updating property limit for $userId: $newLimit');
      }
      
      final firestore = FirebaseFirestore.instance;
      final result = await firestore.collection('users').doc(userId).update({
        'propertyLimit': newLimit,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('✅ Successfully updated property limit to $newLimit');
      }
    } catch (e) {
      debugPrint('❌ Error updating property limit: $e');
      rethrow; // Re-throw so the modal knows the update failed
    }
  }
}

