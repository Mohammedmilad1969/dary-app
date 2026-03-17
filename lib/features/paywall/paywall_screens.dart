import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/premium_package.dart';
import '../../widgets/premium_package_card.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../services/wallet_service.dart' as wallet_service;
import '../../services/paywall_service.dart' as paywall_service;
import '../../providers/auth_provider.dart';
import '../../widgets/success_popup.dart';
import '../../services/theme_service.dart';
import '../../widgets/dary_loading_indicator.dart';
import '../../models/user_profile.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isPurchasing = false;

  Future<void> _handlePurchase(String packageId, String packageName) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isPurchasing = true;
    });

    try {
      // Check if user has sufficient balance before attempting purchase
      // Use the model's PaywallService which contains the static packages used in the UI
      final packageDetails = PaywallService.getPackageById(packageId);
      
      if (packageDetails != null) {
        final currentBalance = wallet_service.WalletService().currentWallet?.balance ?? 0.0;
        if (currentBalance < packageDetails.price) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.insufficientBalance(
                  packageDetails.price.toStringAsFixed(0),
                  packageDetails.currency,
                  currentBalance.toStringAsFixed(0),
                  packageDetails.currency,
                ) ??
                'Insufficient balance',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: l10n?.insufficientBalanceAction ?? 'Top up',
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

        // Direct Purchase for credits
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.currentUser;
        
        if (currentUser == null) return;

        final success = await paywall_service.PaywallService().purchasePackage(
          userId: currentUser.id,
          packageId: packageId,
          propertyId: '', // No specific property for credit purchase
        );

        if (success) {
          // Refresh user profile to get new credit balance
          await authProvider.refreshUser();
          
          // Also refresh listings to ensure boost info/points are synced
          await ProfileService.loadUserProperties(currentUser.id);

          if (!mounted) return;
          
          await SuccessPopup.show(
            context,
            title: l10n?.purchaseSuccess ?? 'Purchase Successful!',
            subtitle: l10n?.purchaseSuccessSubtitle(
              packageDetails.credits ?? 0,
              authProvider.currentUser?.postingCredits ?? 0,
            ) ?? 'You have received ${packageDetails.credits ?? 0} posting points.\nRemaining balance: ${authProvider.currentUser?.postingCredits ?? 0} points',
            buttonText: l10n?.awesome ?? 'Awesome!',
            primaryColor: const Color(0xFF01352D),
          );

          if (mounted) setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.purchaseFailed ?? 'Purchase failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        debugPrint('❌ Package details not found for ID: $packageId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.errorProcessingPurchase('Package not found') ?? 'Package details not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error in _handlePurchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.errorProcessingPurchase(e.toString()) ?? 'Error processing purchase: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final packages = PaywallService.packages;

    // Cache common styles locally
    final headerTitleStyle = ThemeService.getDynamicStyle(
      context,
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.1,
    );

    final headerDescStyle = ThemeService.getDynamicStyle(
      context,
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: 14,
      fontWeight: FontWeight.normal,
    );

    final sectionTitleStyle = ThemeService.getDynamicStyle(
      context,
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF1E293B),
    );

    final sectionDescStyle = ThemeService.getDynamicStyle(
      context,
      fontSize: 14,
      color: const Color(0xFF64748B),
    );

    return Container(
      color: const Color(0xFF01352D),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium Header
              SliverAppBar(
                expandedHeight: 220,
                toolbarHeight: 130, // Definitively taller to push items lower
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFF01352D),
                stretch: true,
                leading: Container(
                  margin: const EdgeInsets.only(top: 55, left: 16), // Definitively more top margin
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/profile');
                      }
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    padding: EdgeInsets.zero,
                    tooltip: 'Back',
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: LanguageToggleButton(languageService: languageService),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Simple Gradient (Less expensive than 3-color stretch)
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF01352D), Color(0xFF015F4D)],
                          ),
                        ),
                      ),
                      // Fewer decorative elements to reduce overdraw
                      Positioned(
                        right: -30,
                        top: -30,
                        child: RepaintBoundary(
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.03),
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              l10n?.upgradeToPremiumTitle ?? 'Upgrade to Premium',
                              style: headerTitleStyle,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n?.getMoreVisibility ?? 'Get more visibility with our Top Listing packages',
                              style: headerDescStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Packages Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: RepaintBoundary(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.chooseYourPackage ?? 'Choose Your Package',
                          style: sectionTitleStyle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n?.selectPerfectDuration ?? 'Select the perfect duration for your listing promotion',
                          style: sectionDescStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Vertical Package List
              if (packages.isEmpty)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: DaryLoadingIndicator(color: Color(0xFF01352D), strokeWidth: 3),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final package = packages[index];
                      return PremiumPackageCard(
                        package: package,
                        onBuy: _isPurchasing
                            ? null
                            : () => _handlePurchase(
                                  package.id,
                                  '${package.name} - ${PaywallService.getDurationText(package, l10n)}',
                                ),
                      );
                    },
                    childCount: packages.length,
                  ),
                ),

              // Why Boost Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                  child: RepaintBoundary(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.whyChooseTopListing ?? 'Why Choose Top Listing?',
                            style: ThemeService.getDynamicStyle(
                              context,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _BenefitItem(
                            icon: Icons.home_work_rounded,
                            title: l10n?.increasedVisibilityTitle ?? 'List Your Properties',
                            description: l10n?.increasedVisibilityDesc ?? 'Each point lets you post one property listing',
                            color: Colors.blue,
                          ),
                          _BenefitItem(
                            icon: Icons.all_inclusive_rounded,
                            title: l10n?.persistentCredits ?? 'Points Never Expire',
                            description: l10n?.oneTimePurchase ?? 'One-time purchase — no monthly fees',
                            color: Colors.amber,
                          ),
                          _BenefitItem(
                            icon: Icons.analytics_rounded,
                            title: l10n?.analyticsDashboardTitle ?? 'Track Performance',
                            description: l10n?.analyticsDashboardDesc ?? 'Track views, clicks, and engagement metrics',
                            color: Colors.green,
                          ),
                          _BenefitItem(
                            icon: Icons.support_agent_rounded,
                            title: l10n?.premiumSupportTitle ?? 'Premium Support',
                            description: l10n?.premiumSupportDesc ?? 'Get priority customer support',
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Extra Bottom Spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 48),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                title,
                style: ThemeService.getDynamicStyle(
                  context,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: ThemeService.getDynamicStyle(
                  context,
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ]),
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
              color: Color(0xFF01352D),
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
              color: Color(0xFF01352D),
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
