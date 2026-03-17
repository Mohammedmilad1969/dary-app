import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../services/user_preferences_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingItem> _getItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      OnboardingItem(
        title: l10n?.onboardingTitle1 ?? 'Find Your Dream Home',
        description: l10n?.onboardingDesc1 ?? 'Explore thousands of premium properties in the best locations across Libya.',
        image: 'assets/images/onboarding_house.png',
      ),
      OnboardingItem(
        title: l10n?.onboardingTitle2 ?? 'Smart Search & Filters',
        description: l10n?.onboardingDesc2 ?? 'Use our advanced search engine to find exactly what you need with just a few taps.',
        image: 'assets/images/onboarding_search.png',
      ),
      OnboardingItem(
        title: l10n?.onboardingTitle3 ?? 'Secure & Direct Contact',
        description: l10n?.onboardingDesc3 ?? 'Connect directly with sellers and agents through our secure messaging system.',
        image: 'assets/images/onboarding_secure.png',
      ),
    ];
  }

  void _onFinish() async {
    final userPrefs = UserPreferencesService();
    await userPrefs.setHasSeenOnboarding(true);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context);
    final items = _getItems(context);

    return Scaffold(
      backgroundColor: const Color(0xFF01352D),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF025141).withValues(alpha: 0.5),
                    const Color(0xFF01352D).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                height: size.height * 0.22,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.asset(
                                    item.image,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 60),
                              Text(
                                item.title,
                                style: Localizations.localeOf(context).languageCode == 'ar'
                                    ? GoogleFonts.cairo(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      )
                                    : GoogleFonts.outfit(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                      ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                item.description,
                                style: Localizations.localeOf(context).languageCode == 'ar'
                                    ? GoogleFonts.cairo(
                                        fontSize: 15,
                                        color: Colors.white70,
                                        height: 1.5,
                                      )
                                    : GoogleFonts.inter(
                                        fontSize: 16,
                                        color: Colors.white70,
                                        height: 1.6,
                                      ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Area
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    // Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        items.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? Colors.white : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _onFinish,
                            child: Text(
                              l10n?.skip ?? 'Skip',
                              style: Localizations.localeOf(context).languageCode == 'ar'
                                  ? GoogleFonts.cairo(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    )
                                  : GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                            ),
                        ),
                        SizedBox(
                          height: 60,
                          width: 140,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage < items.length - 1) {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _onFinish();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF01352D),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ).copyWith(
                              overlayColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.05)),
                            ),
                            child: Text(
                              _currentPage == items.length - 1 
                                  ? (l10n?.start ?? 'Start') 
                                  : (l10n?.next ?? 'Next'),
                              style: Localizations.localeOf(context).languageCode == 'ar'
                                  ? GoogleFonts.cairo(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    )
                                  : GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final String image;

  OnboardingItem({
    required this.title,
    required this.description,
    required this.image,
  });
}
