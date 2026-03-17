import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/property_service.dart';
import '../../services/persistence_service.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import 'firebase_auth_management_screen.dart';
import '../../widgets/dary_loading_indicator.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
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
  final TextEditingController _transactionSearchController = TextEditingController();
  
  // Filter states
  String _userFilter = 'all';
  String _propertyFilter = 'all';
  String _transactionFilter = 'all';
  DateTime? _transactionStartDate;
  DateTime? _transactionEndDate;
  
  // Selected items for bulk actions
  final Set<String> _selectedUsers = {};
  final Set<String> _selectedProperties = {};
  final Set<String> _selectedPayments = {};
  final Set<String> _selectedTransactions = {};

  // Tab names for display
  final List<Map<String, dynamic>> _tabs = [
    {'icon': Icons.people_rounded, 'label': 'Users'},
    {'icon': Icons.home_work_rounded, 'label': 'Properties'},
    {'icon': Icons.toll_rounded, 'label': 'Points'},
    {'icon': Icons.diamond_rounded, 'label': 'Premium'},
    {'icon': Icons.receipt_long_rounded, 'label': 'Transactions'},
    {'icon': Icons.security_rounded, 'label': 'Firebase'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadAdminData();
    
    _userSearchController.addListener(() => setState(() {}));
    _propertySearchController.addListener(() => setState(() {}));
    _transactionSearchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _userSearchController.dispose();
    _propertySearchController.dispose();
    _transactionSearchController.dispose();
    super.dispose();
  }

  Future<void> _refreshPropertyService() async {
    try {
      final propertyService = Provider.of<PropertyService>(context, listen: false);
      final persistenceService = Provider.of<PersistenceService>(context, listen: false);
      await persistenceService.clearAllData();
      await propertyService.initialize(persistenceService: persistenceService);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to refresh PropertyService: $e');
    }
  }

  Future<void> _loadAdminData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _adminService.getDashboardStats(),
        _adminService.getUsers(),
        _adminService.getProperties(),
        _adminService.getPayments(),
        _adminService.getPremiumListings(sortBy: _premiumSortBy),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, int>;
        _users = results[1] as List<AdminUser>;
        _properties = results[2] as List<AdminProperty>;
        _payments = results[3] as List<AdminPayment>;
        _premiumListings = results[4] as List<AdminPremiumListing>;
      });
      
      _animationController.forward(from: 0);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error loading admin data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadAdminData,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filter methods
  List<AdminUser> _getFilteredUsers() {
    final searchTerm = _userSearchController.text.toLowerCase();
    return _users.where((user) {
      final matchesSearch = searchTerm.isEmpty ||
          user.id.toLowerCase().contains(searchTerm) ||
          user.name.toLowerCase().contains(searchTerm) ||
          user.email.toLowerCase().contains(searchTerm) ||
          user.phone.toLowerCase().contains(searchTerm);
      
      final matchesFilter = _userFilter == 'all' ||
          (_userFilter == 'verified' && user.isVerified) ||
          (_userFilter == 'unverified' && !user.isVerified) ||
          (_userFilter == 'active' && user.isActive) ||
          (_userFilter == 'inactive' && !user.isActive) ||
          (_userFilter == 'office' && user.isRealEstateOffice);
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  List<AdminProperty> _getFilteredProperties() {
    final searchTerm = _propertySearchController.text.toLowerCase();
    return _properties.where((property) {
      final matchesSearch = searchTerm.isEmpty ||
          property.id.toLowerCase().contains(searchTerm) ||
          property.title.toLowerCase().contains(searchTerm) ||
          property.ownerName.toLowerCase().contains(searchTerm) ||
          property.city.toLowerCase().contains(searchTerm);
      
      final matchesFilter = _propertyFilter == 'all' ||
          (_propertyFilter == 'active' && property.isActive) ||
          (_propertyFilter == 'inactive' && !property.isActive) ||
          (_propertyFilter == 'boosted' && property.isBoosted) ||
          (_propertyFilter == 'expired' && property.isExpired);
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  List<AdminPayment> _getFilteredTransactions() {
    final searchTerm = _transactionSearchController.text.toLowerCase();
    return _payments.where((transaction) {
      final matchesSearch = searchTerm.isEmpty ||
          transaction.id.toLowerCase().contains(searchTerm) ||
          transaction.userId.toLowerCase().contains(searchTerm) ||
          transaction.userName.toLowerCase().contains(searchTerm) ||
          transaction.userEmail.toLowerCase().contains(searchTerm) ||
          (transaction.description?.toLowerCase().contains(searchTerm) ?? false);
      
      final matchesFilter = _transactionFilter == 'all' ||
          (_transactionFilter == 'wallet_recharge' && transaction.type == 'wallet_recharge') ||
          (_transactionFilter == 'top_listing' && transaction.type == 'top_listing_purchase') ||
          (_transactionFilter == 'pending' && transaction.status == 'pending') ||
          (_transactionFilter == 'completed' && transaction.status == 'completed');
      
      bool matchesDate = true;
      if (_transactionStartDate != null) {
        matchesDate = matchesDate && transaction.createdAt.isAfter(_transactionStartDate!);
      }
      if (_transactionEndDate != null) {
        matchesDate = matchesDate && transaction.createdAt.isBefore(_transactionEndDate!.add(const Duration(days: 1)));
      }
      
      return matchesSearch && matchesFilter && matchesDate;
    }).toList();
  }

  Map<String, dynamic> _getTransactionAnalytics() {
    final filtered = _getFilteredTransactions();
    double totalEarned = 0;
    double totalSpent = 0;
    int walletRecharges = 0;
    int topListingPurchases = 0;
    
    for (final transaction in filtered) {
      if (transaction.type == 'wallet_recharge') {
        totalEarned += transaction.amount;
        walletRecharges++;
      } else if (transaction.type == 'top_listing_purchase' || transaction.type == 'purchase') {
        totalSpent += transaction.amount;
        topListingPurchases++;
      }
    }
    
    return {
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'netRevenue': totalEarned - totalSpent,
      'walletRecharges': walletRecharges,
      'topListingPurchases': topListingPurchases,
    };
  }

  // Action methods
  Future<void> _deleteUser(AdminUser user) async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete User',
      message: 'Are you sure you want to delete "${user.name}"? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.deleteUser(user.id);
        if (success) {
          await _loadAdminData();
          await _refreshPropertyService();
          _showSuccessSnackBar('User "${user.name}" deleted successfully');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to delete user');
      }
    }
  }

  Future<void> _deactivateUser(AdminUser user) async {
    final confirmed = await _showConfirmDialog(
      title: 'Deactivate User',
      message: 'Are you sure you want to deactivate "${user.name}"?',
      confirmText: 'Deactivate',
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.deactivateUser(user.id);
        if (success) {
          await _loadAdminData();
          await _refreshPropertyService();
          _showSuccessSnackBar('User "${user.name}" deactivated');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to deactivate user');
      }
    }
  }

  Future<void> _toggleUserVerification(AdminUser user) async {
    try {
      final success = await _adminService.toggleUserVerification(user.id);
      if (success) {
        await _loadAdminData();
        _showSuccessSnackBar('${user.name} verification updated');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update verification');
    }
  }

  Future<void> _toggleRealEstateOfficeStatus(AdminUser user) async {
    final confirmed = await _showConfirmDialog(
      title: user.isRealEstateOffice ? 'Remove Office Status' : 'Activate as Office',
      message: user.isRealEstateOffice
          ? 'Remove office status from "${user.name}"?'
          : 'Activate "${user.name}" as a real estate office?',
      confirmText: user.isRealEstateOffice ? 'Remove' : 'Activate',
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.toggleRealEstateOfficeStatus(user.id);
        if (success) {
          await _loadAdminData();
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.currentUser?.id == user.id) {
            await authProvider.refreshUser();
          }
          _showSuccessSnackBar('Office status updated');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to update office status');
      }
    }
  }

  Future<void> _toggleAdminStatus(AdminUser user) async {
    final confirmed = await _showConfirmDialog(
      title: user.isAdmin ? 'Remove Admin Status' : 'Make Admin',
      message: user.isAdmin
          ? 'Remove admin privileges from "${user.name}"?'
          : 'Grant admin privileges to "${user.name}"? They will have full access to the admin dashboard.',
      confirmText: user.isAdmin ? 'Remove' : 'Make Admin',
      isDestructive: user.isAdmin,
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.toggleAdminStatus(user.id);
        if (success) {
          await _loadAdminData();
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.currentUser?.id == user.id) {
            await authProvider.refreshUser();
          }
          _showSuccessSnackBar(user.isAdmin ? 'Admin status removed' : '${user.name} is now an admin');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to update admin status');
      }
    }
  }

  Future<void> _deactivateProperty(AdminProperty property) async {
    final confirmed = await _showConfirmDialog(
      title: 'Deactivate Property',
      message: 'Are you sure you want to deactivate "${property.title}"?',
      confirmText: 'Deactivate',
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.deactivateProperty(property.id);
        if (success) {
          await _loadAdminData();
          await _refreshPropertyService();
          _showSuccessSnackBar('Property deactivated');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to deactivate property');
      }
    }
  }

  Future<void> _deleteProperty(AdminProperty property) async {
    final confirmed = await _showConfirmDialog(
      title: 'Delete Property',
      message: 'Are you sure you want to delete "${property.title}"? This action cannot be undone.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.deleteProperty(property.id);
        if (success) {
          await _loadAdminData();
          await _refreshPropertyService();
          _showSuccessSnackBar('Property deleted');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to delete property');
      }
    }
  }

  Future<void> _renewProperty(AdminProperty property) async {
    final confirmed = await _showConfirmDialog(
      title: 'Renew Property',
      message: 'Are you sure you want to renew "${property.title}"? This will reset the creation date and make it published for another 60 days.',
      confirmText: 'Renew',
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.renewProperty(property.id);
        if (success) {
          await _loadAdminData();
          await _refreshPropertyService();
          _showSuccessSnackBar('Property renewed successfully');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to renew property');
      }
    }
  }

  Future<void> _extendPremiumListing(AdminPremiumListing listing) async {
    final daysController = TextEditingController(text: '7');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Extend Premium', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Extend "${listing.propertyTitle}" premium by:'),
            const SizedBox(height: 16),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Days',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF01352D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Extend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final days = int.tryParse(daysController.text) ?? 7;
        final success = await _adminService.extendPremiumListing(listing.id, days);
        if (success) {
          await _loadAdminData();
          _showSuccessSnackBar('Extended by $days days');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to extend listing');
      }
    }
  }

  Future<void> _cancelPremiumListing(AdminPremiumListing listing) async {
    final confirmed = await _showConfirmDialog(
      title: 'Cancel Premium',
      message: 'Cancel premium for "${listing.propertyTitle}"?',
      confirmText: 'Cancel Premium',
      isDestructive: true,
    );

    if (confirmed == true) {
      try {
        final success = await _adminService.deactivatePremiumListing(listing.id);
        if (success) {
          await _loadAdminData();
          await _refreshPropertyService();
          _showSuccessSnackBar('Premium cancelled');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to cancel premium');
      }
    }
  }

  // Bulk actions
  Future<void> _bulkVerifyUsers() async {
    if (_selectedUsers.isEmpty) return;
    
    final confirmed = await _showConfirmDialog(
      title: 'Verify Users',
      message: 'Verify ${_selectedUsers.length} selected users?',
      confirmText: 'Verify All',
    );

    if (confirmed == true) {
      for (final userId in _selectedUsers) {
        await _adminService.toggleUserVerification(userId);
      }
      _selectedUsers.clear();
      await _loadAdminData();
      _showSuccessSnackBar('Users verified');
    }
  }

  Future<void> _bulkDeactivateProperties() async {
    if (_selectedProperties.isEmpty) return;
    
    final confirmed = await _showConfirmDialog(
      title: 'Deactivate Properties',
      message: 'Deactivate ${_selectedProperties.length} selected properties?',
      confirmText: 'Deactivate All',
    );

    if (confirmed == true) {
      for (final propertyId in _selectedProperties) {
        await _adminService.deactivateProperty(propertyId);
      }
      _selectedProperties.clear();
      await _loadAdminData();
      await _refreshPropertyService();
      _showSuccessSnackBar('Properties deactivated');
    }
  }

  // Helper methods
  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : const Color(0xFF01352D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _exportUsers() {
    final filteredUsers = _getFilteredUsers();
    final csvData = 'ID,Name,Email,Phone,Verified,Active,Listings\n${filteredUsers.map((user) => 
          '${user.id},${user.name},${user.email},${user.phone},${user.isVerified},${user.isActive},${user.totalListings}'
        ).join('\n')}';
    
    _showSuccessSnackBar('Exported ${filteredUsers.length} users');
    if (kDebugMode) debugPrint('CSV Data:\n$csvData');
  }

  void _exportProperties() {
    final filteredProperties = _getFilteredProperties();
    final csvData = 'ID,Title,Owner,Price,City,Status,Views,Active\n${filteredProperties.map((property) => 
          '${property.id},${property.title},${property.ownerName},${property.price},${property.city},${property.status},${property.views},${property.isActive}'
        ).join('\n')}';
    
    _showSuccessSnackBar('Exported ${filteredProperties.length} properties');
    if (kDebugMode) debugPrint('CSV Data:\n$csvData');
  }

  void _exportTransactions() {
    final filteredTransactions = _getFilteredTransactions();
    final csvData = 'ID,User,Type,Amount,Status,Date\n${filteredTransactions.map((t) => 
          '${t.id},${t.userName},${t.type},${t.amount},${t.status},${t.createdAt.toIso8601String().split('T')[0]}'
        ).join('\n')}';
    
    _showSuccessSnackBar('Exported ${filteredTransactions.length} transactions');
    if (kDebugMode) debugPrint('CSV Data:\n$csvData');
  }

  Future<void> _showAddVouchersDialog() async {
    int selectedAmount = 20;
    final codesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Vouchers', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Amount:', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [20, 50, 100, 300, 600, 1000].map((amount) {
                    final isSelected = selectedAmount == amount;
                    return ChoiceChip(
                      label: Text('$amount LYD'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => selectedAmount = amount);
                      },
                      selectedColor: const Color(0xFF01352D),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text('Paste Codes (one per line):', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: codesController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Paste your voucher codes here...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF01352D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Vouchers', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && codesController.text.isNotEmpty) {
      try {
        setState(() => _isLoading = true);
        
        final codes = codesController.text
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .toList();
            
        final count = await _adminService.importVouchers(
          amount: selectedAmount,
          codes: codes,
        );
        
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        _showSuccessSnackBar('Successfully added $count vouchers');
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        _showErrorSnackBar('Failed to add vouchers');
      }
    }
  }

  Future<void> _adjustPointsDialog(AdminUser user) async {
    final amountController = TextEditingController(text: '5');
    bool isAdding = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFf7971e).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.toll_rounded, color: Color(0xFFf7971e), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Adjust Points', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(user.name, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFf7971e).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFf7971e).withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.toll_rounded, color: Color(0xFFf7971e), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Current: ${user.postingCredits} pts',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFf7971e)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Add / Deduct toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => isAdding = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isAdding ? Colors.green : Colors.grey[100],
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_rounded, color: isAdding ? Colors.white : Colors.grey, size: 18),
                            const SizedBox(width: 6),
                            Text('Add', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isAdding ? Colors.white : Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => isAdding = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !isAdding ? Colors.red : Colors.grey[100],
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.remove_circle_rounded, color: !isAdding ? Colors.white : Colors.grey, size: 18),
                            const SizedBox(width: 6),
                            Text('Deduct', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: !isAdding ? Colors.white : Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0',
                  labelText: 'Amount',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF01352D), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 8),
              // Quick amount chips
              Wrap(
                spacing: 8,
                children: [1, 5, 10, 25, 50, 100].map((v) => ActionChip(
                  label: Text('$v', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12)),
                  onPressed: () => amountController.text = '$v',
                  backgroundColor: Colors.grey[100],
                  padding: EdgeInsets.zero,
                )).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAdding ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(isAdding ? Icons.add_rounded : Icons.remove_rounded, size: 18),
              label: Text(isAdding ? 'Add Points' : 'Deduct Points', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final amount = int.tryParse(amountController.text) ?? 0;
      if (amount <= 0) return;
      final delta = isAdding ? amount : -amount;
      try {
        final success = await _adminService.adjustUserPostingCredits(user.id, delta);
        if (success) {
          await _loadAdminData();
          _showSuccessSnackBar(isAdding
              ? 'Added $amount points to ${user.name}'
              : 'Deducted $amount points from ${user.name}');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to adjust points');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    if (authProvider.currentUser?.isAdmin != true) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF01352D), Color(0xFF024035)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 80, color: Colors.white24),
                const SizedBox(height: 24),
                Text(
                  'Access Denied',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin privileges required',
                  style: GoogleFonts.inter(color: Colors.white60),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF01352D),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? _buildLoadingState()
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildStatsSection()),
                SliverToBoxAdapter(child: _buildQuickActions()),
                SliverToBoxAdapter(child: _buildTabSection()),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF01352D), Color(0xFF024035)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const DaryLoadingIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading Dashboard...',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF01352D),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: Colors.white),
        ),
        onPressed: () => context.go('/profile'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadAdminData,
        ),
        Consumer<LanguageService>(
          builder: (context, languageService, child) {
            return LanguageToggleButton(languageService: languageService);
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF01352D), Color(0xFF024035), Color(0xFF015F4D)],
            ),
          ),
          child: Stack(
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
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Dashboard',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your platform',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Overview',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildStatCard(
                icon: Icons.people_rounded,
                label: 'Total Users',
                value: '${_stats['totalUsers'] ?? 0}',
                gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              _buildStatCard(
                icon: Icons.home_work_rounded,
                label: 'Properties',
                value: '${_stats['totalProperties'] ?? 0}',
                gradient: const [Color(0xFF11998e), Color(0xFF38ef7d)],
              ),
              _buildStatCard(
                icon: Icons.toll_rounded,
                label: 'Points Issued',
                value: '${_stats['totalPointsIssued'] ?? 0}',
                gradient: const [Color(0xFFf7971e), Color(0xFFffd200)],
              ),
              _buildStatCard(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Revenue (LYD)',
                value: '${_stats['totalRevenue'] ?? 0}',
                gradient: const [Color(0xFF43e97b), Color(0xFF38f9d7)],
              ),
              _buildStatCard(
                icon: Icons.diamond_rounded,
                label: 'Boosted',
                value: '${_stats['activePremiumListings'] ?? 0}',
                gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
              ),
              _buildStatCard(
                icon: Icons.receipt_long_rounded,
                label: 'Transactions',
                value: '${_stats['totalPayments'] ?? 0}',
                gradient: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _animationController.value),
          child: Opacity(
            opacity: _animationController.value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
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

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickActionChip(
                  icon: Icons.toll_rounded,
                  label: 'Points',
                  onTap: () => _tabController.animateTo(2),
                ),
                const SizedBox(width: 8),
                _buildQuickActionChip(
                  icon: Icons.download_rounded,
                  label: 'Export All',
                  onTap: () {
                    _exportUsers();
                    _exportProperties();
                    _exportTransactions();
                  },
                ),
                const SizedBox(width: 8),
                _buildQuickActionChip(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  onTap: _showAnalytics,
                ),
                const SizedBox(width: 8),
                _buildQuickActionChip(
                  icon: Icons.add_card_rounded,
                  label: 'Add Vouchers',
                  onTap: _showAddVouchersDialog,
                ),
                const SizedBox(width: 8),
                _buildQuickActionChip(
                  icon: Icons.security_rounded,
                  label: 'Firebase Auth',
                  onTap: () => _tabController.animateTo(5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF01352D)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalytics() {
    final analytics = _getTransactionAnalytics();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.analytics_rounded, color: Color(0xFF01352D)),
                  const SizedBox(width: 12),
                  Text(
                    'Analytics & Insights',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildAnalyticsTile('Total Revenue', '${analytics['totalEarned']?.toStringAsFixed(0) ?? 0} LYD', Colors.green),
                  _buildAnalyticsTile('Total Spent', '${analytics['totalSpent']?.toStringAsFixed(0) ?? 0} LYD', Colors.orange),
                  _buildAnalyticsTile('Net Revenue', '${analytics['netRevenue']?.toStringAsFixed(0) ?? 0} LYD', Colors.blue),
                  _buildAnalyticsTile('Wallet Recharges', '${analytics['walletRecharges'] ?? 0}', Colors.purple),
                  _buildAnalyticsTile('Premium Purchases', '${analytics['topListingPurchases'] ?? 0}', Colors.pink),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTile(String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Custom tab bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = _tabController.index == index;
                return GestureDetector(
                  onTap: () => setState(() => _tabController.animateTo(index)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF01352D) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _tabs[index]['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _tabs[index]['label'],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          // Tab content
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersTab(),
                _buildPropertiesTab(),
                _buildPointsTab(),
                _buildPremiumTab(),
                _buildTransactionsTab(),
                _buildFirebaseTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    final filteredUsers = _getFilteredUsers();
    
    return Column(
      children: [
        // Search and filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _userSearchController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by ID, name, email...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  suffixIcon: _userSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _userSearchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              // Filter chips and count
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF01352D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredUsers.length} users',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF01352D),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildFilterChip('All', _userFilter == 'all', () => setState(() => _userFilter = 'all')),
                  _buildFilterChip('Verified', _userFilter == 'verified', () => setState(() => _userFilter = 'verified')),
                  _buildFilterChip('Office', _userFilter == 'office', () => setState(() => _userFilter = 'office')),
                ],
              ),
            ],
          ),
        ),
        // Users list
        Expanded(
          child: filteredUsers.isEmpty
              ? _buildEmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No users found',
                  subtitle: 'Try adjusting your search or filter',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF01352D) : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(AdminUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showUserDetails(user),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: user.isRealEstateOffice
                              ? [const Color(0xFF01352D), const Color(0xFF024035)]
                              : [Colors.blue[400]!, Colors.blue[600]!],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user.isVerified)
                                const Icon(Icons.verified_rounded, size: 18, color: Colors.blue),
                              if (user.isAdmin)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Admin',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ),
                              if (user.isRealEstateOffice)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF01352D).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Office',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF01352D),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            user.email,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            'ID: ${user.id}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons
                Row(
                  children: [
                    _buildActionButton(
                      icon: user.isAdmin ? Icons.admin_panel_settings : Icons.admin_panel_settings_outlined,
                      color: user.isAdmin ? Colors.purple : Colors.grey,
                      onTap: () => _toggleAdminStatus(user),
                    ),
                    _buildActionButton(
                      icon: user.isVerified ? Icons.verified_user_rounded : Icons.verified_user_outlined,
                      color: user.isVerified ? Colors.blue : Colors.grey,
                      onTap: () => _toggleUserVerification(user),
                    ),
                    _buildActionButton(
                      icon: user.isRealEstateOffice ? Icons.business_rounded : Icons.business_outlined,
                      color: user.isRealEstateOffice ? const Color(0xFF01352D) : Colors.grey,
                      onTap: () => _toggleRealEstateOfficeStatus(user),
                    ),
                    _buildActionButton(
                      icon: Icons.block_rounded,
                      color: Colors.orange,
                      onTap: () => _deactivateUser(user),
                    ),
                    _buildActionButton(
                      icon: Icons.delete_rounded,
                      color: Colors.red,
                      onTap: () => _deleteUser(user),
                    ),
                    const Spacer(),
                    // Points badge + adjust button
                    GestureDetector(
                      onTap: () => _adjustPointsDialog(user),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFf7971e), Color(0xFFffd200)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFf7971e).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.toll_rounded, size: 13, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${user.postingCredits} pts',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  void _showUserDetails(AdminUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: user.isRealEstateOffice
                                    ? [const Color(0xFF01352D), const Color(0xFF024035)]
                                    : [Colors.blue[400]!, Colors.blue[600]!],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user.name,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user.email,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            'ID: ${user.id}',
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow('Phone', user.phone),
                    _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
                    _buildDetailRow('Verified', user.isVerified ? 'Yes' : 'No'),
                    _buildDetailRow('Admin', user.isAdmin ? 'Yes' : 'No'),
                    _buildDetailRow('Office', user.isRealEstateOffice ? 'Yes' : 'No'),
                    _buildDetailRow('Listings', '${user.activeListings}/${user.totalListings}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsTab() {
    // Sort users by postingCredits descending
    final sorted = List<AdminUser>.from(_users)
      ..sort((a, b) => b.postingCredits.compareTo(a.postingCredits));

    if (sorted.isEmpty) {
      return _buildEmptyState(
        icon: Icons.toll_outlined,
        title: 'No users found',
        subtitle: 'Users will appear here once loaded',
      );
    }

    final totalPoints = sorted.fold(0, (sum, u) => sum + u.postingCredits);

    return Column(
      children: [
        // Summary banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFf7971e), Color(0xFFffd200)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFf7971e).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.toll_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalPoints',
                    style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    'Total Points in Circulation',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Users list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final user = sorted[index];
              final rankColor = index == 0
                  ? const Color(0xFFffd700)
                  : index == 1
                      ? const Color(0xFFc0c0c0)
                      : index == 2
                          ? const Color(0xFFcd7f32)
                          : Colors.grey[300]!;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[100]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: rankColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: rankColor, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '#${index + 1}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: rankColor == Colors.grey[300] ? Colors.grey[600]! : rankColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: user.isRealEstateOffice
                              ? [const Color(0xFF01352D), const Color(0xFF024035)]
                              : [Colors.blue[400]!, Colors.blue[600]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.email,
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Points display
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${user.postingCredits}',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFf7971e),
                          ),
                        ),
                        Text(
                          'points',
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Adjust button
                    InkWell(
                      onTap: () => _adjustPointsDialog(user),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFf7971e).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFFf7971e)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPropertiesTab() {
    final filteredProperties = _getFilteredProperties();
    
    return Column(
      children: [
        // Search and filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _propertySearchController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by ID, title, owner, city...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  suffixIcon: _propertySearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _propertySearchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF01352D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredProperties.length} properties',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF01352D),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildFilterChip('All', _propertyFilter == 'all', () => setState(() => _propertyFilter = 'all')),
                  _buildFilterChip('Active', _propertyFilter == 'active', () => setState(() => _propertyFilter = 'active')),
                  _buildFilterChip('Boosted', _propertyFilter == 'boosted', () => setState(() => _propertyFilter = 'boosted')),
                  _buildFilterChip('Expired', _propertyFilter == 'expired', () => setState(() => _propertyFilter = 'expired')),
                ],
              ),
            ],
          ),
        ),
        // Properties list
        Expanded(
          child: filteredProperties.isEmpty
              ? _buildEmptyState(
                  icon: Icons.home_work_outlined,
                  title: 'No properties found',
                  subtitle: 'Try adjusting your search or filter',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredProperties.length,
                  itemBuilder: (context, index) {
                    final property = filteredProperties[index];
                    return _buildPropertyCard(property);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(AdminProperty property) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: property.isBoosted ? Colors.amber[400]! : Colors.grey[200]!,
          width: property.isBoosted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: property.isBoosted 
                ? Colors.amber.withValues(alpha: 0.2) 
                : Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (property.isBoosted)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.amber, Colors.orange],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.diamond_rounded, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'BOOSTED',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: Text(
                              property.title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.ownerName,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            property.city,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        'ID: ${property.id}',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${property.price.toStringAsFixed(0)} LYD',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF01352D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.visibility_rounded, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          '${property.views}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: property.isExpired 
                            ? Colors.red.withValues(alpha: 0.1)
                            : (property.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        property.isExpired ? 'Expired' : (property.isActive ? 'Active' : 'Inactive'),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: property.isExpired 
                              ? Colors.red 
                              : (property.isActive ? Colors.green : Colors.orange),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionButton(
                  icon: property.isActive ? Icons.pause_circle_rounded : Icons.play_circle_rounded,
                  color: property.isActive ? Colors.orange : Colors.green,
                  onTap: () => _deactivateProperty(property),
                ),
                _buildActionButton(
                  icon: Icons.delete_rounded,
                  color: Colors.red,
                  onTap: () => _deleteProperty(property),
                ),
                if (property.isExpired || !property.isActive || !property.isPublished)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildActionButton(
                      icon: Icons.refresh_rounded,
                      color: Colors.blue,
                      onTap: () => _renewProperty(property),
                    ),
                  ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // View property
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text('View', style: GoogleFonts.inter(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF01352D),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTab() {
    return Column(
      children: [
        // Sort options
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_premiumListings.length} premium',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Sort by:',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(width: 8),
              _buildFilterChip('Expiry', _premiumSortBy == 'expiryDate', () {
                setState(() => _premiumSortBy = 'expiryDate');
                _loadAdminData();
              }),
              _buildFilterChip('Package', _premiumSortBy == 'packageName', () {
                setState(() => _premiumSortBy = 'packageName');
                _loadAdminData();
              }),
            ],
          ),
        ),
        // Premium listings
        Expanded(
          child: _premiumListings.isEmpty
              ? _buildEmptyState(
                  icon: Icons.diamond_outlined,
                  title: 'No premium listings',
                  subtitle: 'Premium listings will appear here',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _premiumListings.length,
                  itemBuilder: (context, index) {
                    final listing = _premiumListings[index];
                    return _buildPremiumCard(listing);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPremiumCard(AdminPremiumListing listing) {
    final now = DateTime.now();
    final isExpired = listing.expiryDate.isBefore(now);
    final difference = listing.expiryDate.difference(now);
    // Calculate days remaining - round up so <24 hours shows as 1 day, not 0
    final daysRemaining = isExpired ? 0 : (difference.inHours / 24).ceil();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isExpired 
              ? [Colors.grey[100]!, Colors.grey[200]!]
              : [Colors.purple[50]!, Colors.pink[50]!],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired ? Colors.grey[300]! : Colors.purple.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isExpired
                          ? [Colors.grey, Colors.grey[600]!]
                          : [Colors.purple, Colors.pink],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    listing.packageName,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isExpired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'EXPIRED',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  )
                else
                  Text(
                    daysRemaining == 0 
                        ? (difference.inHours > 0 ? '${difference.inHours}h left' : '< 1h left')
                        : daysRemaining == 1 
                            ? '1 day left'
                            : '$daysRemaining days left',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: daysRemaining <= 3 ? Colors.orange : Colors.green,
                    ),
                  ),
                const Spacer(),
                Text(
                  '${listing.packagePrice.toStringAsFixed(0)} LYD',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              listing.propertyTitle,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  listing.ownerName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(listing.expiryDate),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _extendPremiumListing(listing),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: Text('Extend', style: GoogleFonts.inter(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.purple,
                      side: const BorderSide(color: Colors.purple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelPremiumListing(listing),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text('Cancel', style: GoogleFonts.inter(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildTransactionsTab() {
    final filteredTransactions = _getFilteredTransactions();
    final analytics = _getTransactionAnalytics();
    
    return Column(
      children: [
        // Search and analytics
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _transactionSearchController,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                  suffixIcon: _transactionSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _transactionSearchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              // Quick stats
              Row(
                children: [
                  _buildMiniStat('Revenue', '${analytics['totalEarned']?.toStringAsFixed(0) ?? 0}', Colors.green),
                  const SizedBox(width: 8),
                  _buildMiniStat('Spent', '${analytics['totalSpent']?.toStringAsFixed(0) ?? 0}', Colors.orange),
                  const SizedBox(width: 8),
                  _buildMiniStat('Net', '${analytics['netRevenue']?.toStringAsFixed(0) ?? 0}', Colors.blue),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', _transactionFilter == 'all', () => setState(() => _transactionFilter = 'all')),
                    _buildFilterChip('Recharge', _transactionFilter == 'wallet_recharge', () => setState(() => _transactionFilter = 'wallet_recharge')),
                    _buildFilterChip('Purchase', _transactionFilter == 'top_listing', () => setState(() => _transactionFilter = 'top_listing')),
                    _buildFilterChip('Completed', _transactionFilter == 'completed', () => setState(() => _transactionFilter = 'completed')),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Transactions list
        Expanded(
          child: filteredTransactions.isEmpty
              ? _buildEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions found',
                  subtitle: 'Transactions will appear here',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = filteredTransactions[index];
                    return _buildTransactionCard(transaction);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '$value LYD',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(AdminPayment transaction) {
    final isCredit = transaction.type == 'wallet_recharge' || transaction.type == 'credit';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isCredit ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 20,
                color: isCredit ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.userName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    transaction.description ?? transaction.type.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(transaction.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}${transaction.amount.toStringAsFixed(0)} LYD',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isCredit ? Colors.green : Colors.orange,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: transaction.status == 'completed' 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: transaction.status == 'completed' ? Colors.green : Colors.amber[700],
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

  Widget _buildFirebaseTab() {
    return const FirebaseAuthManagementScreen();
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 48, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
