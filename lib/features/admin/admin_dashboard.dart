import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/property_service.dart';
import '../../services/persistence_service.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import 'firebase_auth_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  
  bool _isLoading = true;
  Map<String, int> _stats = {};
  List<AdminUser> _users = [];
  List<AdminProperty> _properties = [];
  List<AdminPayment> _payments = [];
  List<AdminPremiumListing> _premiumListings = [];
  String _premiumSortBy = 'expiryDate';
  
  // Search and filter controllers
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _propertySearchController = TextEditingController();
  final TextEditingController _paymentSearchController = TextEditingController();
  final TextEditingController _transactionSearchController = TextEditingController();
  
  // Filter states
  String _userFilter = 'all';
  String _propertyFilter = 'all';
  String _paymentFilter = 'all';
  String _transactionFilter = 'all';
  DateTime? _transactionStartDate;
  DateTime? _transactionEndDate;
  
  // Selected items for bulk actions
  Set<String> _selectedUsers = {};
  Set<String> _selectedProperties = {};
  Set<String> _selectedPayments = {};
  Set<String> _selectedTransactions = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userSearchController.dispose();
    _propertySearchController.dispose();
    _paymentSearchController.dispose();
    _transactionSearchController.dispose();
    super.dispose();
  }

  /// Refresh PropertyService to update homepage and other parts of the app
  Future<void> _refreshPropertyService() async {
    try {
      final propertyService = Provider.of<PropertyService>(context, listen: false);
      final persistenceService = Provider.of<PersistenceService>(context, listen: false);
      
      // Force refresh by clearing local cache and reinitializing
      await persistenceService.clearAllData();
      await propertyService.initialize(persistenceService: persistenceService);
      
      if (kDebugMode) {
        debugPrint('🔄 PropertyService refreshed after admin operation');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to refresh PropertyService: $e');
      }
    }
  }

  Future<void> _loadAdminData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all admin data in parallel
      final results = await Future.wait([
        _adminService.getDashboardStats(),
        _adminService.getUsers(),
        _adminService.getProperties(),
        _adminService.getPayments(),
        _adminService.getPremiumListings(sortBy: _premiumSortBy),
      ]);

      setState(() {
        _stats = results[0] as Map<String, int>;
        _users = results[1] as List<AdminUser>;
        _properties = results[2] as List<AdminProperty>;
        _payments = results[3] as List<AdminPayment>;
        _premiumListings = results[4] as List<AdminPremiumListing>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.errorLoadingAdminData ?? 'Error loading admin data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.actions ?? 'Actions'),
        content: Text('Are you sure you want to delete user "${user.name}"? This action cannot be undone and will delete all their data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.deleteUser(user.id);
        if (success) {
          // Refresh all admin data from Firebase
          await _loadAdminData();
          // Also refresh PropertyService to update homepage
          await _refreshPropertyService();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User "${user.name}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deactivateUser(AdminUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.actions ?? 'Actions'),
        content: Text('Are you sure you want to deactivate user "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.deactivateUser(user.id);
        if (success) {
          // Refresh all admin data from Firebase
          await _loadAdminData();
          // Also refresh PropertyService to update homepage
          await _refreshPropertyService();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User "${user.name}" deactivated successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleUserVerification(AdminUser user) async {
    try {
      final success = await _adminService.toggleUserVerification(user.id);
      if (success) {
        // Refresh all admin data from Firebase
        await _loadAdminData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} verification status updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update verification status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deactivateProperty(AdminProperty property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.actions ?? 'Actions'),
        content: Text('Are you sure you want to deactivate "${property.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.deactivateProperty(property.id);
        if (success) {
          // Refresh all admin data from Firebase
          await _loadAdminData();
          // Also refresh PropertyService to update homepage
          await _refreshPropertyService();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Property "${property.title}" deactivated successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate property'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProperty(AdminProperty property) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.actions ?? 'Actions'),
        content: Text('Are you sure you want to delete "${property.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.deleteProperty(property.id);
        if (success) {
          // Refresh all admin data from Firebase
          await _loadAdminData();
          // Also refresh PropertyService to update homepage
          await _refreshPropertyService();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Property "${property.title}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete property'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _extendPremiumListing(AdminPremiumListing listing) async {
    final daysController = TextEditingController(text: '7');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.actions ?? 'Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Extend premium listing for "${listing.propertyTitle}"'),
            const SizedBox(height: 16),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Days to extend',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final daysToExtend = int.tryParse(daysController.text) ?? 7;
        final success = await _adminService.extendPremiumListing(listing.id, daysToExtend);
        if (success) {
          await _loadAdminData(); // Reload data to get updated expiry dates
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Premium listing extended by $daysToExtend days'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to extend premium listing'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deactivatePremiumListing(AdminPremiumListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.actions ?? 'Actions'),
        content: Text('Are you sure you want to deactivate premium listing for "${listing.propertyTitle}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.deactivatePremiumListing(listing.id);
        if (success) {
          await _loadAdminData(); // Reload data to get updated status
          // Also refresh PropertyService to update homepage
          await _refreshPropertyService();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Premium listing deactivated'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to deactivate premium listing'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Bulk Actions
  Future<void> _bulkVerifyUsers() async {
    if (_selectedUsers.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Action'),
        content: Text('Verify ${_selectedUsers.length} selected users?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Verify All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      int successCount = 0;
      for (final userId in _selectedUsers) {
        try {
          final success = await _adminService.toggleUserVerification(userId);
          if (success) successCount++;
        } catch (e) {
          debugPrint('Error verifying user $userId: $e');
        }
      }
      
      setState(() {
        _selectedUsers.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully verified $successCount users'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadAdminData();
    }
  }

  Future<void> _bulkDeactivateProperties() async {
    if (_selectedProperties.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Action'),
        content: Text('Deactivate ${_selectedProperties.length} selected properties?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deactivate All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      int successCount = 0;
      for (final propertyId in _selectedProperties) {
        try {
          final success = await _adminService.deactivateProperty(propertyId);
          if (success) successCount++;
        } catch (e) {
          debugPrint('Error deactivating property $propertyId: $e');
        }
      }
      
      setState(() {
        _selectedProperties.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully deactivated $successCount properties'),
          backgroundColor: Colors.orange,
        ),
      );
      
      await _loadAdminData();
    }
  }

  // Search and Filter Methods
  List<AdminUser> _getFilteredUsers() {
    List<AdminUser> filtered = _users;
    
    // Apply search filter
    if (_userSearchController.text.isNotEmpty) {
      final searchTerm = _userSearchController.text.toLowerCase();
      filtered = filtered.where((user) => 
        user.name.toLowerCase().contains(searchTerm) ||
        user.email.toLowerCase().contains(searchTerm) ||
        user.phone.toLowerCase().contains(searchTerm)
      ).toList();
    }
    
    // Apply status filter
    switch (_userFilter) {
      case 'verified':
        filtered = filtered.where((user) => user.isVerified).toList();
        break;
      case 'unverified':
        filtered = filtered.where((user) => !user.isVerified).toList();
        break;
      case 'active':
        filtered = filtered.where((user) => user.isActive).toList();
        break;
      case 'inactive':
        filtered = filtered.where((user) => !user.isActive).toList();
        break;
    }
    
    return filtered;
  }

  List<AdminProperty> _getFilteredProperties() {
    List<AdminProperty> filtered = _properties;
    
    // Apply search filter
    if (_propertySearchController.text.isNotEmpty) {
      final searchTerm = _propertySearchController.text.toLowerCase();
      filtered = filtered.where((property) => 
        property.title.toLowerCase().contains(searchTerm) ||
        property.ownerName.toLowerCase().contains(searchTerm) ||
        property.city.toLowerCase().contains(searchTerm)
      ).toList();
    }
    
    // Apply status filter
    switch (_propertyFilter) {
      case 'active':
        filtered = filtered.where((property) => property.isActive).toList();
        break;
      case 'inactive':
        filtered = filtered.where((property) => !property.isActive).toList();
        break;
      case 'high_price':
        filtered = filtered.where((property) => property.price > 500000).toList();
        break;
      case 'low_price':
        filtered = filtered.where((property) => property.price < 100000).toList();
        break;
    }
    
    return filtered;
  }

  List<AdminPayment> _getFilteredPayments() {
    List<AdminPayment> filtered = _payments;
    
    // Apply search filter
    if (_paymentSearchController.text.isNotEmpty) {
      final searchTerm = _paymentSearchController.text.toLowerCase();
      filtered = filtered.where((payment) => 
        payment.userName.toLowerCase().contains(searchTerm) ||
        payment.userEmail.toLowerCase().contains(searchTerm) ||
        payment.type.toLowerCase().contains(searchTerm)
      ).toList();
    }
    
    // Apply status filter
    switch (_paymentFilter) {
      case 'completed':
        filtered = filtered.where((payment) => payment.status.toLowerCase() == 'completed').toList();
        break;
      case 'pending':
        filtered = filtered.where((payment) => payment.status.toLowerCase() == 'pending').toList();
        break;
      case 'failed':
        filtered = filtered.where((payment) => payment.status.toLowerCase() == 'failed').toList();
        break;
      case 'high_amount':
        filtered = filtered.where((payment) => payment.amount > 1000).toList();
        break;
    }
    
    return filtered;
  }

  // Transaction filtering methods
  List<AdminPayment> _getFilteredTransactions() {
    List<AdminPayment> filtered = _payments;
    
    // Apply search filter
    if (_transactionSearchController.text.isNotEmpty) {
      final searchTerm = _transactionSearchController.text.toLowerCase();
      filtered = filtered.where((transaction) => 
        transaction.userName.toLowerCase().contains(searchTerm) ||
        transaction.userEmail.toLowerCase().contains(searchTerm) ||
        transaction.type.toLowerCase().contains(searchTerm) ||
        (transaction.description?.toLowerCase().contains(searchTerm) ?? false)
      ).toList();
    }
    
    // Apply type filter
    switch (_transactionFilter) {
      case 'wallet_recharge':
        filtered = filtered.where((transaction) => transaction.type.toLowerCase().contains('recharge')).toList();
        break;
      case 'top_listing':
        filtered = filtered.where((transaction) => transaction.type.toLowerCase().contains('top listing')).toList();
        break;
      case 'completed':
        filtered = filtered.where((transaction) => transaction.status.toLowerCase() == 'completed').toList();
        break;
      case 'pending':
        filtered = filtered.where((transaction) => transaction.status.toLowerCase() == 'pending').toList();
        break;
      case 'failed':
        filtered = filtered.where((transaction) => transaction.status.toLowerCase() == 'failed').toList();
        break;
      case 'high_amount':
        filtered = filtered.where((transaction) => transaction.amount > 500).toList();
        break;
      case 'low_amount':
        filtered = filtered.where((transaction) => transaction.amount < 100).toList();
        break;
    }
    
    // Apply date filter
    if (_transactionStartDate != null) {
      filtered = filtered.where((transaction) => 
        transaction.createdAt.isAfter(_transactionStartDate!) || 
        transaction.createdAt.isAtSameMomentAs(_transactionStartDate!)
      ).toList();
    }
    
    if (_transactionEndDate != null) {
      filtered = filtered.where((transaction) => 
        transaction.createdAt.isBefore(_transactionEndDate!.add(const Duration(days: 1))) || 
        transaction.createdAt.isAtSameMomentAs(_transactionEndDate!)
      ).toList();
    }
    
    return filtered;
  }

  // Transaction analytics
  Map<String, double> _getTransactionAnalytics() {
    final filteredTransactions = _getFilteredTransactions();
    
    double totalSpent = 0;
    double totalEarned = 0;
    int walletRecharges = 0;
    int topListingPurchases = 0;
    
    for (final transaction in filteredTransactions) {
      if (transaction.type.toLowerCase().contains('recharge')) {
        totalEarned += transaction.amount;
        walletRecharges++;
      } else if (transaction.type.toLowerCase().contains('top listing')) {
        totalSpent += transaction.amount;
        topListingPurchases++;
      }
    }
    
    return {
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'netRevenue': totalEarned - totalSpent,
      'walletRecharges': walletRecharges.toDouble(),
      'topListingPurchases': topListingPurchases.toDouble(),
    };
  }

  // Bulk transaction actions
  Future<void> _bulkRefundTransactions() async {
    if (_selectedTransactions.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Refund'),
        content: Text('Refund ${_selectedTransactions.length} selected transactions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Refund All'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      int successCount = 0;
      for (final transactionId in _selectedTransactions) {
        try {
          // In a real app, you'd call a refund API
          await Future.delayed(const Duration(milliseconds: 100));
          successCount++;
        } catch (e) {
          debugPrint('Error refunding transaction $transactionId: $e');
        }
      }
      
      setState(() {
        _selectedTransactions.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully refunded $successCount transactions'),
          backgroundColor: Colors.orange,
        ),
      );
      
      await _loadAdminData();
    }
  }

  // Export functionality
  void _exportUsers() {
    final filteredUsers = _getFilteredUsers();
    final csvData = 'Name,Email,Phone,Verified,Active,Listings\n' +
        filteredUsers.map((user) => 
          '${user.name},${user.email},${user.phone},${user.isVerified ? "Yes" : "No"},${user.isActive ? "Yes" : "No"},${user.activeListings}/${user.totalListings}'
        ).join('\n');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${filteredUsers.length} users to CSV'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // In a real app, you'd copy to clipboard or save to file
            debugPrint('CSV Data:\n$csvData');
          },
        ),
      ),
    );
  }

  void _exportProperties() {
    final filteredProperties = _getFilteredProperties();
    final csvData = 'Title,Owner,Price,City,Status,Views,Active\n' +
        filteredProperties.map((property) => 
          '${property.title},${property.ownerName},${property.price},${property.city},${property.status},${property.views},${property.isActive ? "Yes" : "No"}'
        ).join('\n');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${filteredProperties.length} properties to CSV'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            debugPrint('CSV Data:\n$csvData');
          },
        ),
      ),
    );
  }

  void _exportTransactions() {
    final filteredTransactions = _getFilteredTransactions();
    final analytics = _getTransactionAnalytics();
    final csvData = 'User,Email,Type,Amount,Status,Date,Description\n' +
        filteredTransactions.map((transaction) => 
          '${transaction.userName},${transaction.userEmail},${transaction.type},${transaction.amount} ${transaction.currency},${transaction.status},${transaction.createdAt.toIso8601String().split('T')[0]},${transaction.description ?? ""}'
        ).join('\n') +
        '\n\nSUMMARY\nTotal Earned,${analytics['totalEarned']} LYD\nTotal Spent,${analytics['totalSpent']} LYD\nNet Revenue,${analytics['netRevenue']} LYD\nWallet Recharges,${analytics['walletRecharges']}\nTop Listing Purchases,${analytics['topListingPurchases']}';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${filteredTransactions.length} transactions to CSV'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            debugPrint('CSV Data:\n$csvData');
          },
        ),
      ),
    );
  }

  // Analytics and Insights
  void _showAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analytics & Insights'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnalyticsCard('Total Revenue', '${_stats['totalRevenue'] ?? 0} LYD', Colors.green),
              _buildAnalyticsCard('Active Users', '${_stats['totalUsers'] ?? 0}', Colors.blue),
              _buildAnalyticsCard('Premium Listings', '${_stats['activePremiumListings'] ?? 0}', Colors.purple),
              _buildAnalyticsCard('Avg. Property Price', '${(_stats['totalRevenue'] ?? 0) / (_stats['totalProperties'] ?? 1)} LYD', Colors.orange),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Check if user is admin
    if (authProvider.currentUser?.isAdmin != true) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n?.adminDashboard ?? 'Admin Dashboard'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/profile'),
          ),
        ),
        body: const Center(
          child: Text('Access denied. Admin privileges required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.adminDashboard ?? 'Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/profile'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalytics,
            tooltip: 'Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Export Data'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.people),
                        title: const Text('Export Users'),
                        onTap: () {
                          Navigator.pop(context);
                          _exportUsers();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.home),
                        title: const Text('Export Properties'),
                        onTap: () {
                          Navigator.pop(context);
                          _exportProperties();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.account_balance_wallet),
                        title: const Text('Export Transactions'),
                        onTap: () {
                          Navigator.pop(context);
                          _exportTransactions();
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Export',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminData,
            tooltip: 'Refresh',
          ),
          Consumer<LanguageService>(
            builder: (context, languageService, child) {
              return LanguageToggleButton(languageService: languageService);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAdminData,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Stats Cards
                    _buildStatsCards(l10n),
                    
                    // Tab Content - Fixed height to allow scrolling
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6, // 60% of screen height
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildUsersTab(l10n),
                          _buildPropertiesTab(l10n),
                          _buildPaymentsTab(l10n),
                          _buildPremiumListingsTab(l10n),
                          _buildTransactionsTab(l10n),
                          _buildFirebaseAuthTab(l10n),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(
            icon: const Icon(Icons.people),
            text: l10n?.users ?? 'Users',
          ),
          Tab(
            icon: const Icon(Icons.home),
            text: l10n?.properties ?? 'Properties',
          ),
          Tab(
            icon: const Icon(Icons.payment),
            text: l10n?.payments ?? 'Payments',
          ),
          Tab(
            icon: const Icon(Icons.star),
            text: l10n?.premiumListings ?? 'Premium Listings',
          ),
          Tab(
            icon: const Icon(Icons.account_balance_wallet),
            text: 'Transactions',
          ),
          Tab(
            icon: const Icon(Icons.security),
            text: 'Firebase Auth',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final crossAxisCount = isMobile ? 2 : 4;
          final childAspectRatio = isMobile ? 1.5 : 1.2;
          
          return GridView.count(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                icon: Icons.people,
                title: l10n?.totalUsers ?? 'Total Users',
                value: '${_stats['totalUsers'] ?? 0}',
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.home,
                title: l10n?.totalProperties ?? 'Total Properties',
                value: '${_stats['totalProperties'] ?? 0}',
                color: Colors.green,
              ),
              _buildStatCard(
                icon: Icons.payment,
                title: l10n?.totalPayments ?? 'Total Payments',
                value: '${_stats['totalPayments'] ?? 0}',
                color: Colors.orange,
              ),
              _buildStatCard(
                icon: Icons.star,
                title: l10n?.premiumListings ?? 'Premium Listings',
                value: '${_stats['activePremiumListings'] ?? 0}/${_stats['totalPremiumListings'] ?? 0}',
                color: Colors.purple,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(AppLocalizations? l10n) {
    final filteredUsers = _getFilteredUsers();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Column(
          children: [
            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  TextField(
                    controller: _userSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _userSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _userSearchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _userFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filter',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Users')),
                            DropdownMenuItem(value: 'verified', child: Text('Verified')),
                            DropdownMenuItem(value: 'unverified', child: Text('Unverified')),
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _userFilter = value ?? 'all';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedUsers.isNotEmpty) ...[
                        ElevatedButton.icon(
                          onPressed: _bulkVerifyUsers,
                          icon: const Icon(Icons.verified_user),
                          label: Text('Verify ${_selectedUsers.length}'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton.icon(
                        onPressed: _exportUsers,
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Users List
            Expanded(
              child: isMobile
                  ? ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: CheckboxListTile(
                            value: _selectedUsers.contains(user.id),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedUsers.add(user.id);
                                } else {
                                  _selectedUsers.remove(user.id);
                                }
                              });
                            },
                            title: Text(
                              user.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.email,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  user.phone,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  '${l10n?.listings ?? 'Listings'}: ${user.activeListings}/${user.totalListings}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            secondary: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  user.isVerified ? Icons.check_circle : Icons.cancel,
                                  color: user.isVerified ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  user.isActive ? Icons.check_circle : Icons.cancel,
                                  color: user.isActive ? Colors.green : Colors.red,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    user.isVerified ? Icons.verified_user : Icons.verified_user_outlined,
                                    color: user.isVerified ? Colors.green : Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => _toggleUserVerification(user),
                                  tooltip: user.isVerified ? 'Remove Verification' : 'Verify User',
                                ),
                                IconButton(
                                  icon: Icon(
                                    user.isActive ? Icons.person_off : Icons.person_add,
                                    color: user.isActive ? Colors.orange : Colors.green,
                                    size: 20,
                                  ),
                                  onPressed: () => user.isActive ? _deactivateUser(user) : null,
                                  tooltip: user.isActive ? 'Deactivate User' : 'User is inactive',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _deleteUser(user),
                                  tooltip: 'Delete User',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text(l10n?.name ?? 'Name')),
                          DataColumn(label: Text(l10n?.email ?? 'Email')),
                          DataColumn(label: Text(l10n?.phone ?? 'Phone')),
                          DataColumn(label: Text(l10n?.verified ?? 'Verified')),
                          DataColumn(label: Text(l10n?.active ?? 'Active')),
                          DataColumn(label: Text(l10n?.listings ?? 'Listings')),
                          DataColumn(label: Text(l10n?.actions ?? 'Actions')),
                        ],
                        rows: filteredUsers.map((user) {
                          return DataRow(
                            selected: _selectedUsers.contains(user.id),
                            onSelectChanged: (bool? selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedUsers.add(user.id);
                                } else {
                                  _selectedUsers.remove(user.id);
                                }
                              });
                            },
                            cells: [
                              DataCell(Text(user.name)),
                              DataCell(Text(user.email)),
                              DataCell(Text(user.phone)),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      user.isVerified ? Icons.check_circle : Icons.cancel,
                                      color: user.isVerified ? Colors.green : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(user.isVerified ? 'Yes' : 'No'),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      user.isActive ? Icons.check_circle : Icons.cancel,
                                      color: user.isActive ? Colors.green : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(user.isActive ? 'Yes' : 'No'),
                                  ],
                                ),
                              ),
                              DataCell(Text('${user.activeListings}/${user.totalListings}')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        user.isVerified ? Icons.verified_user : Icons.verified_user_outlined,
                                        color: user.isVerified ? Colors.green : Colors.grey,
                                        size: 16,
                                      ),
                                      onPressed: () => _toggleUserVerification(user),
                                      tooltip: user.isVerified ? 'Remove Verification' : 'Verify User',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        user.isActive ? Icons.person_off : Icons.person_add,
                                        color: user.isActive ? Colors.orange : Colors.green,
                                        size: 16,
                                      ),
                                      onPressed: () => user.isActive ? _deactivateUser(user) : null,
                                      tooltip: user.isActive ? 'Deactivate User' : 'User is inactive',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                      onPressed: () => _deleteUser(user),
                                      tooltip: 'Delete User',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPropertiesTab(AppLocalizations? l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          return ListView.builder(
            itemCount: _properties.length,
            itemBuilder: (context, index) {
              final property = _properties[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              property.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            property.isActive ? Icons.check_circle : Icons.cancel,
                            color: property.isActive ? Colors.green : Colors.red,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n?.owner ?? 'Owner'}: ${property.ownerName}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${l10n?.price ?? 'Price'}: ${property.price.toStringAsFixed(0)} LYD',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${l10n?.city ?? 'City'}: ${property.city}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${l10n?.status ?? 'Status'}: ${property.status}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${l10n?.views ?? 'Views'}: ${property.views}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Spacer(),
                          if (property.isActive)
                            IconButton(
                              icon: const Icon(Icons.pause_circle, color: Colors.orange, size: 20),
                              onPressed: () => _deactivateProperty(property),
                              tooltip: 'Deactivate',
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _deleteProperty(property),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return DataTable(
            columns: [
              DataColumn(label: Text(l10n?.title ?? 'Title')),
              DataColumn(label: Text(l10n?.owner ?? 'Owner')),
              DataColumn(label: Text(l10n?.price ?? 'Price')),
              DataColumn(label: Text(l10n?.city ?? 'City')),
              DataColumn(label: Text(l10n?.status ?? 'Status')),
              DataColumn(label: Text(l10n?.views ?? 'Views')),
              DataColumn(label: Text(l10n?.active ?? 'Active')),
              DataColumn(label: Text(l10n?.actions ?? 'Actions')),
            ],
            rows: _properties.map((property) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(Text(property.ownerName)),
                  DataCell(Text('${property.price.toStringAsFixed(0)} LYD')),
                  DataCell(Text(property.city)),
                  DataCell(Text(property.status)),
                  DataCell(Text('${property.views}')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          property.isActive ? Icons.check_circle : Icons.cancel,
                          color: property.isActive ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(property.isActive ? 'Yes' : 'No'),
                      ],
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (property.isActive)
                          IconButton(
                            icon: const Icon(Icons.pause_circle, color: Colors.orange),
                            onPressed: () => _deactivateProperty(property),
                            tooltip: 'Deactivate',
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProperty(property),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildPaymentsTab(AppLocalizations? l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          return ListView.builder(
            itemCount: _payments.length,
            itemBuilder: (context, index) {
              final payment = _payments[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              payment.userName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(payment.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              payment.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        payment.userEmail,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${l10n?.type ?? 'Type'}: ${payment.type}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${l10n?.amount ?? 'Amount'}: ${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            '${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      if (payment.description != null && payment.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          payment.description!,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return DataTable(
            columns: [
              DataColumn(label: Text(l10n?.user ?? 'User')),
              DataColumn(label: Text(l10n?.type ?? 'Type')),
              DataColumn(label: Text(l10n?.amount ?? 'Amount')),
              DataColumn(label: Text(l10n?.status ?? 'Status')),
              DataColumn(label: Text(l10n?.date ?? 'Date')),
              DataColumn(label: Text(l10n?.description ?? 'Description')),
            ],
            rows: _payments.map((payment) {
              return DataRow(
                cells: [
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          payment.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          payment.userEmail,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(payment.type)),
                  DataCell(Text('${payment.amount.toStringAsFixed(0)} ${payment.currency}')),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(payment.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        payment.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(Text('${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year}')),
                  DataCell(
                    Text(
                      payment.description ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildPremiumListingsTab(AppLocalizations? l10n) {
    return Column(
      children: [
        // Sort controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                l10n?.sortBy ?? 'Sort by:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _premiumSortBy,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _premiumSortBy = newValue;
                    });
                    _loadAdminData();
                  }
                },
                items: [
                  DropdownMenuItem(
                    value: 'expiryDate',
                    child: Text(l10n?.expiryDate ?? 'Expiry Date'),
                  ),
                  DropdownMenuItem(
                    value: 'purchaseDate',
                    child: Text(l10n?.purchaseDate ?? 'Purchase Date'),
                  ),
                  DropdownMenuItem(
                    value: 'packagePrice',
                    child: Text(l10n?.packagePrice ?? 'Package Price'),
                  ),
                  DropdownMenuItem(
                    value: 'views',
                    child: Text(l10n?.views ?? 'Views'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // DataTable
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              
              if (isMobile) {
                return ListView.builder(
                  itemCount: _premiumListings.length,
                  itemBuilder: (context, index) {
                    final listing = _premiumListings[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    listing.propertyTitle,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPremiumStatusColor(listing.status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    listing.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n?.owner ?? 'Owner'}: ${listing.ownerName}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '${l10n?.package ?? 'Package'}: ${listing.packageName}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '${l10n?.price ?? 'Price'}: ${listing.packagePrice.toStringAsFixed(0)} LYD',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${l10n?.expiryDate ?? 'Expiry'}: ${listing.expiryDate.day}/${listing.expiryDate.month}/${listing.expiryDate.year}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  '${l10n?.views ?? 'Views'}: ${listing.views}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const Spacer(),
                                if (listing.isActive) ...[
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: Colors.green, size: 20),
                                    onPressed: () => _extendPremiumListing(listing),
                                    tooltip: 'Extend',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.pause_circle, color: Colors.orange, size: 20),
                                    onPressed: () => _deactivatePremiumListing(listing),
                                    tooltip: 'Deactivate',
                                  ),
                                ] else ...[
                                  IconButton(
                                    icon: const Icon(Icons.play_circle, color: Colors.blue, size: 20),
                                    onPressed: () => _extendPremiumListing(listing),
                                    tooltip: 'Reactivate',
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              listing.isExpired 
                                  ? 'Expired' 
                                  : listing.isExpiringSoon 
                                      ? 'Expires Soon' 
                                      : '${listing.daysUntilExpiry} days left',
                              style: TextStyle(
                                fontSize: 11,
                                color: listing.isExpired 
                                    ? Colors.red 
                                    : listing.isExpiringSoon 
                                        ? Colors.orange 
                                        : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else {
                return DataTable(
                  columns: [
                    DataColumn(label: Text(l10n?.propertyTitle ?? 'Property')),
                    DataColumn(label: Text(l10n?.owner ?? 'Owner')),
                    DataColumn(label: Text(l10n?.package ?? 'Package')),
                    DataColumn(label: Text(l10n?.price ?? 'Price')),
                    DataColumn(label: Text(l10n?.expiryDate ?? 'Expiry')),
                    DataColumn(label: Text(l10n?.status ?? 'Status')),
                    DataColumn(label: Text(l10n?.views ?? 'Views')),
                    DataColumn(label: Text(l10n?.actions ?? 'Actions')),
                  ],
                  rows: _premiumListings.map((listing) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            listing.propertyTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(Text(listing.ownerName)),
                        DataCell(Text(listing.packageName)),
                        DataCell(Text('${listing.packagePrice.toStringAsFixed(0)} LYD')),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${listing.expiryDate.day}/${listing.expiryDate.month}/${listing.expiryDate.year}'),
                              Text(
                                listing.isExpired 
                                    ? 'Expired' 
                                    : listing.isExpiringSoon 
                                        ? 'Expires Soon' 
                                        : '${listing.daysUntilExpiry} days left',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: listing.isExpired 
                                      ? Colors.red 
                                      : listing.isExpiringSoon 
                                          ? Colors.orange 
                                          : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPremiumStatusColor(listing.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              listing.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text('${listing.views}')),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (listing.isActive) ...[
                                IconButton(
                                  icon: const Icon(Icons.add_circle, color: Colors.green),
                                  onPressed: () => _extendPremiumListing(listing),
                                  tooltip: 'Extend',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.pause_circle, color: Colors.orange),
                                  onPressed: () => _deactivatePremiumListing(listing),
                                  tooltip: 'Deactivate',
                                ),
                              ] else ...[
                                IconButton(
                                  icon: const Icon(Icons.play_circle, color: Colors.blue),
                                  onPressed: () => _extendPremiumListing(listing),
                                  tooltip: 'Reactivate',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPremiumStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Widget _buildTransactionsTab(AppLocalizations? l10n) {
    final filteredTransactions = _getFilteredTransactions();
    final analytics = _getTransactionAnalytics();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        
        return Column(
          children: [
            // Transaction Analytics Summary
            Container(
              padding: const EdgeInsets.all(8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Text(
                        'Transaction Summary',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Total Earned',
                              '${analytics['totalEarned']!.toStringAsFixed(0)} LYD',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Total Spent',
                              '${analytics['totalSpent']!.toStringAsFixed(0)} LYD',
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Net Revenue',
                              '${analytics['netRevenue']!.toStringAsFixed(0)} LYD',
                              analytics['netRevenue']! >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Transactions',
                              '${filteredTransactions.length}',
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Search and Filter Bar
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  TextField(
                    controller: _transactionSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _transactionSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _transactionSearchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _transactionFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filter',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Transactions')),
                            DropdownMenuItem(value: 'wallet_recharge', child: Text('Wallet Recharge')),
                            DropdownMenuItem(value: 'top_listing', child: Text('Top Listing')),
                            DropdownMenuItem(value: 'completed', child: Text('Completed')),
                            DropdownMenuItem(value: 'pending', child: Text('Pending')),
                            DropdownMenuItem(value: 'failed', child: Text('Failed')),
                            DropdownMenuItem(value: 'high_amount', child: Text('High Amount (>500)')),
                            DropdownMenuItem(value: 'low_amount', child: Text('Low Amount (<100)')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _transactionFilter = value ?? 'all';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final startDate = await showDatePicker(
                            context: context,
                            initialDate: _transactionStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (startDate != null) {
                            setState(() {
                              _transactionStartDate = startDate;
                            });
                          }
                        },
                        icon: const Icon(Icons.date_range),
                        label: Text(_transactionStartDate != null 
                            ? 'From: ${_transactionStartDate!.day}/${_transactionStartDate!.month}' 
                            : 'From Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final endDate = await showDatePicker(
                              context: context,
                              initialDate: _transactionEndDate ?? DateTime.now(),
                              firstDate: _transactionStartDate ?? DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (endDate != null) {
                              setState(() {
                                _transactionEndDate = endDate;
                              });
                            }
                          },
                          icon: const Icon(Icons.date_range),
                          label: Text(_transactionEndDate != null 
                              ? 'To: ${_transactionEndDate!.day}/${_transactionEndDate!.month}' 
                              : 'To Date'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_transactionStartDate != null || _transactionEndDate != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _transactionStartDate = null;
                              _transactionEndDate = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Dates'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        ),
                      const SizedBox(width: 8),
                      if (_selectedTransactions.isNotEmpty) ...[
                        ElevatedButton.icon(
                          onPressed: _bulkRefundTransactions,
                          icon: const Icon(Icons.refresh),
                          label: Text('Refund ${_selectedTransactions.length}'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton.icon(
                        onPressed: _exportTransactions,
                        icon: const Icon(Icons.download),
                        label: const Text('Export'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Transactions List
            Expanded(
              child: isMobile
                  ? ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: CheckboxListTile(
                            value: _selectedTransactions.contains(transaction.id),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedTransactions.add(transaction.id);
                                } else {
                                  _selectedTransactions.remove(transaction.id);
                                }
                              });
                            },
                            title: Text(
                              transaction.userName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction.userEmail,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  '${transaction.type} - ${transaction.amount.toStringAsFixed(0)} ${transaction.currency}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                if (transaction.description != null && transaction.description!.isNotEmpty)
                                  Text(
                                    transaction.description!,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                            secondary: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(transaction.status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    transaction.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Icon(
                                  transaction.type.toLowerCase().contains('recharge') 
                                      ? Icons.add_circle 
                                      : Icons.remove_circle,
                                  color: transaction.type.toLowerCase().contains('recharge') 
                                      ? Colors.green 
                                      : Colors.red,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text(l10n?.user ?? 'User')),
                          DataColumn(label: Text(l10n?.type ?? 'Type')),
                          DataColumn(label: Text(l10n?.amount ?? 'Amount')),
                          DataColumn(label: Text(l10n?.status ?? 'Status')),
                          DataColumn(label: Text(l10n?.date ?? 'Date')),
                          DataColumn(label: Text(l10n?.description ?? 'Description')),
                          DataColumn(label: Text(l10n?.actions ?? 'Actions')),
                        ],
                        rows: filteredTransactions.map((transaction) {
                          return DataRow(
                            selected: _selectedTransactions.contains(transaction.id),
                            onSelectChanged: (bool? selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedTransactions.add(transaction.id);
                                } else {
                                  _selectedTransactions.remove(transaction.id);
                                }
                              });
                            },
                            cells: [
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      transaction.userName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      transaction.userEmail,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      transaction.type.toLowerCase().contains('recharge') 
                                          ? Icons.add_circle 
                                          : Icons.remove_circle,
                                      color: transaction.type.toLowerCase().contains('recharge') 
                                          ? Colors.green 
                                          : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(transaction.type),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  '${transaction.amount.toStringAsFixed(0)} ${transaction.currency}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: transaction.type.toLowerCase().contains('recharge') 
                                        ? Colors.green 
                                        : Colors.red,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(transaction.status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    transaction.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text('${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}')),
                              DataCell(
                                Text(
                                  transaction.description ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.refresh, color: Colors.orange),
                                  onPressed: () {
                                    // Individual refund action
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Refund Transaction'),
                                        content: Text('Refund ${transaction.amount} ${transaction.currency} to ${transaction.userName}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Refunded ${transaction.amount} ${transaction.currency}'),
                                                  backgroundColor: Colors.orange,
                                                ),
                                              );
                                            },
                                            child: const Text('Refund'),
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  tooltip: 'Refund Transaction',
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFirebaseAuthTab(AppLocalizations? l10n) {
    return const FirebaseAuthManagementScreen();
  }
}