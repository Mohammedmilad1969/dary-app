import 'package:flutter/material.dart';
import 'package:dary/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/premium_package.dart';
import '../../widgets/premium_package_card.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../services/wallet_service.dart' as wallet_service;
import '../../models/user_profile.dart';
import '../../widgets/listing_selection_dialog.dart';
import '../../models/property.dart';
import '../../services/paywall_service.dart' as paywall_service;
import '../../providers/auth_provider.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isPurchasing = false;

  Future<void> _handlePurchase(String packageId, String packageName) async {
    setState(() {
      _isPurchasing = true;
    });

    try {
      // Check if user has sufficient balance before attempting purchase
      final package = PaywallService.getPackageById(packageId);
      if (package != null) {
        final currentBalance = wallet_service.WalletService().currentWallet?.balance ?? 0.0;
        if (currentBalance < package.price) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Insufficient balance. You need ${package.price} ${package.currency} but only have $currentBalance ${package.currency}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Recharge',
                textColor: Colors.white,
              onPressed: () {
                // Navigate to wallet screen for recharge
                context.go('/wallet');
              },
              ),
            ),
          );
          return;
        }
      }

      // Get current user ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to purchase packages'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show property selection dialog
      _showListingSelectionDialog(packageName, packageId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing purchase: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPurchasing = false;
      });
    }
  }

  void _showListingSelectionDialog(String packageName, String packageId) {
    final userListings = ProfileService.userListings
        .where((listing) => listing.isActive && ProfileService.canBoostListing(listing.id))
        .toList();

    if (userListings.isEmpty) {
      // Check if there are active listings but all are boosted
      final activeListings = ProfileService.userListings.where((listing) => listing.isActive).toList();
      if (activeListings.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All your active listings are currently boosted. Wait for boost to expire before boosting again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active listings found. Please create a listing first.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ListingSelectionDialog(
          listings: userListings,
          packageName: packageName,
          onListingSelected: (String listingId) {
            _handleListingBoost(listingId, packageName, packageId);
          },
        );
      },
    );
  }

  Future<void> _handleListingBoost(String listingId, String packageName, String packageId) async {
    try {
      // Find the selected listing
      final listing = ProfileService.userListings.firstWhere(
        (l) => l.id == listingId,
      );

      // Get current user ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to purchase packages'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Purchase package with proper parameters using PaywallService
      final paywallService = paywall_service.PaywallService();
      final success = await paywallService.purchasePackage(
        userId: currentUser.id,
        packageId: packageId,
        propertyId: listingId,
      );

      if (success) {
        // Show success message with updated balance
        final newBalance = wallet_service.WalletService().currentWallet?.balance ?? 0.0;
        final currency = 'LYD';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${listing.title} is now boosted with $packageName! Remaining balance: $newBalance $currency'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View Wallet',
              textColor: Colors.white,
              onPressed: () {
                context.go('/wallet');
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase failed. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing purchase: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final packages = PaywallService.packages;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.upgradeToPremiumTitle ?? 'Upgrade to Premium'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
        actions: [
          LanguageToggleButton(languageService: languageService),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.star,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Boost Your Listings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.getMoreVisibility ?? 'Get more visibility with our Top Listing packages',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l10n?.limitedTimeOffer ?? '✨ Limited Time Offer',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Packages Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.chooseYourPackage ?? 'Choose Your Package',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.selectPerfectDuration ?? 'Select the perfect duration for your listing promotion',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Package Cards
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: packages.length,
                    itemBuilder: (context, index) {
                      final package = packages[index];
                      return PremiumPackageCard(
                        package: package,
                        onBuy: _isPurchasing
                            ? null
                            : () => _handlePurchase(
                                  package.id,
                                  '${package.name} - ${PaywallService.getDurationText(package.duration)}',
                                ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Benefits Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.whyChooseTopListing ?? 'Why Choose Top Listing?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBenefitItem(
                    Icons.visibility,
                    'Increased Visibility',
                    'Your listing appears at the top of search results',
                  ),
                  _buildBenefitItem(
                    Icons.star,
                    'Featured Badge',
                    'Stand out with a premium featured badge',
                  ),
                  _buildBenefitItem(
                    Icons.analytics,
                    'Analytics Dashboard',
                    'Track views, clicks, and engagement metrics',
                  ),
                  _buildBenefitItem(
                    Icons.support_agent,
                    'Premium Support',
                    'Get priority customer support',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_membership,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            Text(
              'Choose Your Plan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Select the perfect plan for you',
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

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subscription'),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.settings_applications,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 24),
            Text(
              'Manage Subscription',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Update or cancel your subscription',
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
