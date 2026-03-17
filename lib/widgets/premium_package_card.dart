import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/premium_package.dart';
import '../services/theme_service.dart';

class PremiumPackageCard extends StatelessWidget {
  final PremiumPackage package;
  final VoidCallback? onBuy;

  const PremiumPackageCard({
    super.key,
    required this.package,
    this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPopular = package.isPopular;

    // Cache styles locally to avoid repeated ThemeService.getDynamicStyle lookups
    final titleStyle = ThemeService.getDynamicStyle(
      context,
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: isPopular ? Colors.white : const Color(0xFF1E293B),
    );

    final durationStyle = ThemeService.getDynamicStyle(
      context,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: isPopular ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF64748B),
    );

    final priceStyle = ThemeService.getDynamicStyle(
      context,
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: isPopular ? Colors.white : const Color(0xFF01352D),
    );

    final currencyStyle = ThemeService.getDynamicStyle(
      context,
      fontSize: 14,
      color: isPopular ? Colors.white.withValues(alpha: 0.6) : Colors.grey[500],
    );

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isPopular
              ? const LinearGradient(
                  colors: [Color(0xFF01352D), Color(0xFF024035)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPopular ? null : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isPopular
                  ? const Color(0xFF01352D).withValues(alpha: 0.3)
                  : const Color(0xFF000000).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isPopular ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              if (isPopular)
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPopular ? Colors.white.withValues(alpha: 0.1) : const Color(0xFF01352D).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getPackageIcon(package.name),
                            color: isPopular ? Colors.white : const Color(0xFF01352D),
                            size: 24,
                          ),
                        ),
                        if (isPopular)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  l10n?.popular ?? 'MOST POPULAR',
                                  style: ThemeService.getDynamicStyle(
                                    context,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _getLocalizedPackageName(context, package.name),
                      style: titleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      PaywallService.getDurationText(package, l10n),
                      style: durationStyle,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${NumberFormat('#,###').format(package.price)} ${package.currency}',
                          style: priceStyle,
                        ),
                        if (package.credits == null || package.credits! == 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 4),
                            child: Text(
                              '/ ${PaywallService.getDurationText(package, l10n)}',
                              style: currencyStyle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: isPopular ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(height: 20),
                    ...package.features.take(3).map((feature) => _FeatureItem(
                          isPopular: isPopular,
                          text: _getLocalizedFeature(context, feature),
                        )),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: onBuy,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPopular ? Colors.white : const Color(0xFF01352D),
                          foregroundColor: isPopular ? const Color(0xFF01352D) : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n?.buyPackage(PaywallService.getDurationText(package, l10n)) ?? 'Select Package',
                          style: ThemeService.getDynamicStyle(
                            context,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  IconData _getPackageIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('1 day')) return Icons.bolt_rounded;
    if (lower.contains('3 days')) return Icons.auto_awesome_rounded;
    if (lower.contains('7 days')) return Icons.rocket_launch_rounded;
    if (lower.contains('30 days')) return Icons.workspace_premium_rounded;
    return Icons.star_rounded;
  }

  String _getLocalizedPackageName(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return name;

    final lowerName = name.toLowerCase();
    if (lowerName.contains('starter')) return l10n.starterPackage;
    if (lowerName.contains('standard')) return l10n.standardPackage;
    if (lowerName.contains('professional')) return l10n.professionalPackage;
    if (lowerName.contains('business')) return l10n.businessPackage;
    if (lowerName.contains('enterprise')) return l10n.enterprisePackage;
    if (lowerName.contains('plus')) return l10n.packagePlus;
    if (lowerName.contains('emerald')) return l10n.packageEmerald;
    if (lowerName.contains('premium')) return l10n.packagePremium;
    if (lowerName.contains('elite')) return l10n.packageElite;
    if (name.contains('Top Listing')) return l10n.topListing;

    return name;
  }

  String _getLocalizedFeature(BuildContext context, String feature) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return feature;

    // Match "N Property Posting Credits" pattern
    final creditsRegex = RegExp(r'^(\d+)\s+Property Posting Credits?$');
    final creditsMatch = creditsRegex.firstMatch(feature);
    if (creditsMatch != null) {
      final count = int.tryParse(creditsMatch.group(1) ?? '0') ?? 0;
      return l10n.featurePostingCredits(count);
    }

    // Persistent credits variations
    if (feature.contains('Persistent credits (no monthly loss)') ||
        feature.contains('no monthly loss')) {
      return l10n.featurePersistentCreditsLong;
    }
    if (feature == 'Persistent credits') return l10n.featurePersistentCredits;

    // Visibility
    if (feature.contains('Basic search visibility')) return l10n.featureBasicVisibility;
    if (feature.contains('Standard search visibility')) return l10n.featureStandardVisibility;
    if (feature.contains('Enhanced search visibility')) return l10n.featureEnhancedVisibility;
    if (feature.contains('Maximum search visibility')) return l10n.featureMaximumVisibility;

    // Support
    if (feature.contains('Email support')) return l10n.featureEmailSupport;
    if (feature.contains('Priority support')) return l10n.featurePrioritySupport;
    if (feature.contains('Dedicated account manager')) return l10n.featureDedicatedManager;

    // Legacy/Boost features
    if (feature.contains('Priority placement')) return l10n.prioritySearch;
    if (feature.contains('Featured badge')) return l10n.featuredBadge;
    if (feature.contains('Increased visibility')) return l10n.increasedVisibility;
    if (feature.contains('24-hour boost')) return l10n.hourBoost24;
    if (feature.contains('Enhanced analytics')) return l10n.packageAnalytics;
    if (feature.contains('Analytics dashboard')) return l10n.analyticsDashboardTitle;
    if (feature.contains('Premium support')) return l10n.premiumSupportTitle;

    return feature;
  }
}

class _FeatureItem extends StatelessWidget {
  final bool isPopular;
  final String text;

  const _FeatureItem({
    required this.isPopular,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: isPopular ? Colors.amber : const Color(0xFF22C55E),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: ThemeService.getDynamicStyle(
                context,
                fontSize: 14,
                color: isPopular ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
