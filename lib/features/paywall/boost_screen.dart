import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/premium_package.dart';
import '../../widgets/premium_package_card.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../services/wallet_service.dart' as wallet_service;
import '../../services/paywall_service.dart' as paywall_service;
import '../../services/property_service.dart' as property_service;
import '../../providers/auth_provider.dart';
import '../../widgets/success_popup.dart';
import '../../services/theme_service.dart';
import '../../widgets/dary_loading_indicator.dart';
import '../../widgets/listing_selection_dialog.dart';
import '../../models/user_profile.dart';

class BoostScreen extends StatefulWidget {
  final String? propertyId;

  const BoostScreen({super.key, this.propertyId});

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  bool _isPurchasing = false;
  String? _selectedPropertyId;

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.propertyId;
  }

  Future<void> _handlePurchase(PremiumPackage package) async {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    // If no property selected, show selection dialog
    if (_selectedPropertyId == null) {
      final userProperties = ProfileService.userListings.where((p) => 
        !p.isDeleted && 
        !p.isBoostActive
      ).toList();
      
      if (userProperties.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.noActiveListingsToBoost ?? 'No active listings to boost'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (context) => ListingSelectionDialog(
          listings: userProperties,
          packageName: package.name,
          onListingSelected: (propertyId) {
            setState(() {
              _selectedPropertyId = propertyId;
            });
          },
        ),
      );

      // If still null, user cancelled selection
      if (_selectedPropertyId == null) return;
    }

    setState(() {
      _isPurchasing = true;
    });

    try {
      // Check balance
      final currentBalance = wallet_service.WalletService().currentWallet?.balance ?? 0.0;
      if (currentBalance < package.price) {
        _showInsufficientBalance(package, currentBalance);
        return;
      }

      final success = await paywall_service.PaywallService().purchasePackage(
        userId: currentUser.id,
        packageId: package.id,
        propertyId: _selectedPropertyId!,
      );

      if (success) {
        if (!mounted) return;
        
        await SuccessPopup.show(
          context,
          title: l10n?.boostApplied ?? 'Boost Applied!',
          subtitle: l10n?.boostSuccessSubtitle(
            package.name,
            package.durationDays,
          ) ?? 'Your listing has been boosted with ${package.name} for ${package.durationDays} days.',
          buttonText: l10n?.awesome ?? 'Awesome!',
          primaryColor: const Color(0xFF01352D),
        );

        if (mounted) context.pop();
      } else {
        final error = paywall_service.PaywallService().errorMessage;
        _showError(error ?? l10n?.purchaseFailed ?? 'Purchase failed');
      }
    } catch (e) {
      _showError(l10n?.errorProcessingPurchase(e.toString()) ?? 'Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  void _showInsufficientBalance(PremiumPackage package, double balance) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.insufficientBalance(
            package.price.toStringAsFixed(0),
            package.currency,
            balance.toStringAsFixed(0),
            package.currency,
          ) ?? 'Insufficient balance',
        ),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: l10n?.insufficientBalanceAction ?? 'Top up',
          textColor: Colors.white,
          onPressed: () => context.push('/wallet'),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final packages = PaywallService.boostPackages;

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
              // Header
              SliverAppBar(
                expandedHeight: 220,
                toolbarHeight: 80,
                pinned: true,
                backgroundColor: const Color(0xFF01352D),
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: LanguageToggleButton(languageService: languageService),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF01352D), Color(0xFF025C4E)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              l10n?.boostYourAd ?? 'Boost Your Ad',
                              style: ThemeService.getDynamicStyle(
                                context,
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n?.boostDescription ?? 'Get maximum visibility and reach more buyers instantly',
                              style: ThemeService.getDynamicStyle(
                                context,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Packages
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Text(
                    l10n?.chooseBoostPackage ?? 'Choose your Boost Package',
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final package = packages[index];
                    return PremiumPackageCard(
                      package: package,
                      onBuy: _isPurchasing ? null : () => _handlePurchase(package),
                    );
                  },
                  childCount: packages.length,
                ),
              ),

              // Benefits
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                          l10n?.whyChooseTopListing ?? 'Why Boost your Listing?',
                          style: ThemeService.getDynamicStyle(
                            context,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _BenefitRow(
                          icon: Icons.trending_up_rounded,
                          title: l10n?.increasedVisibilityTitle ?? 'Top of Search',
                          desc: l10n?.increasedVisibilityDesc ?? 'Your ad will appear at the top of search results',
                        ),
                        _BenefitRow(
                          icon: Icons.verified_user_rounded,
                          title: l10n?.featuredBadgeTitle ?? 'Featured Badge',
                          desc: l10n?.featuredBadgeDesc ?? 'Stand out with a special premium badge',
                        ),
                        _BenefitRow(
                          icon: Icons.ads_click_rounded,
                          title: l10n?.boostYourListings ?? '10x More Clicks',
                          desc: l10n?.analyticsDashboardDesc ?? 'Boosted ads receive significantly more engagement',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _BenefitRow({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF01352D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF01352D), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ThemeService.getDynamicStyle(context, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  desc,
                  style: ThemeService.getDynamicStyle(context, color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
