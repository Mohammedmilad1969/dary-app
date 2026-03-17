import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/text_input_formatters.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_profile.dart';
import '../../models/property.dart';
import '../../widgets/user_listing_card.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../providers/auth_provider.dart';
import 'package:dary/services/theme_service.dart';
// Removed obsolete import
import '../../services/property_service.dart' as property_service;
import '../../utils/number_formatter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import './favorites_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../paywall/paywall_screens.dart';
import '../../services/notification_service.dart';
import '../../widgets/notification_popup.dart';
import '../../widgets/dary_loading_indicator.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isGoogleUser = authProvider.currentUser?.isGoogleUser ?? false;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n?.deleteAccountTitle ?? 'Delete Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.deleteAccountConfirmation ??
                'Are you sure you want to delete your account? This action cannot be undone. All your properties and data will be permanently removed.',
          ),
          if (isGoogleUser)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                l10n?.googleReauthDeletion ?? 
                'Since you signed in with Google, you will be asked to re-authenticate with Google to confirm deletion.',
                style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.blue[800],
                    fontSize: 13),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  l10n?.enterPasswordToConfirm ?? 'Please enter your password to confirm:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: l10n?.passwordHint ?? 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop();
                },
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!isGoogleUser && _passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n?.pleaseEnterPassword ?? 'Please enter your password')),
                    );
                    return;
                  }

                  setState(() => _isLoading = true);

                  final success = await authProvider.deleteAccount(
                    password: isGoogleUser ? null : _passwordController.text,
                  );

                  if (success) {
                    if (mounted) {
                      Navigator.of(context).pop();
                      Future.delayed(Duration.zero, () {
                        AppRouter.router.go('/');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n?.accountDeletedSuccessfully ?? 'Your account has been successfully deleted.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      });
                    }
                  } else {
                    setState(() => _isLoading = false);
                    if (mounted) {
                      final error = authProvider.errorMessage ?? l10n?.errorOccurred ?? 'An error occurred';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(l10n?.delete ?? 'Delete'),
        ),
      ],
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppLocalizations? get l10n => AppLocalizations.of(context);
  bool _showAllListings = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedListingIds = {};
  bool _isResendingEmail = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserProperties();
        _refreshUserProfile();
        _checkExpiringProperties();
      }
    });
  }

  Future<void> _checkExpiringProperties() async {
    // Wait for auth to be ready
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final expiring = await notificationService.checkExpiringProperties(authProvider.currentUser!.id);
      
      if (expiring.isNotEmpty && mounted) {
        _showExpiryAlert(expiring);
      }
    }
  }

  void _showExpiryAlert(List<Property> expiring) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)?.listingsExpiringSoon ?? 'Listings Expiring Soon!',
                style: ThemeService.getDynamicStyle(context, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              AppLocalizations.of(context)?.listingsExpiryWarning ?? 'The following properties are about to expire. Please renew them to keep them visible to public.',
              style: ThemeService.getDynamicStyle(context, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            ...expiring.take(3).map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.home_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
            if (expiring.length > 3)
              Text(
                AppLocalizations.of(context)?.andMoreCount(expiring.length - 3) ?? '...and ${expiring.length - 3} more', 
                style: ThemeService.getDynamicStyle(context, fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)?.later ?? 'Later', 
              style: ThemeService.getDynamicStyle(context, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => _renewAllExpiringFromProfile(ctx, expiring),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF01352D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context)?.renewAll(expiring.length) ?? 'Renew All (${expiring.length})'),
          ),
        ],
      ),
    );
  }

  Future<void> _renewAllExpiringFromProfile(BuildContext dialogCtx, List<Property> expiring) async {
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    // Check current points
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final currentPoints = (userDoc.data()?['postingCredits'] as num?)?.toInt() ?? 0;
    final needed = expiring.length;

    if (currentPoints < needed) {
      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.notEnoughPointsToRenew(currentPoints, needed) ??
                  'Not enough points. You have $currentPoints pts but need $needed pts.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: l10n?.buyPoints ?? 'Buy Points',
              textColor: Colors.white,
              onPressed: () => context.go('/paywall'),
            ),
          ),
        );
      }
      return;
    }

    if (dialogCtx.mounted) Navigator.pop(dialogCtx);

    final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
    int renewedCount = 0;
    for (final property in expiring) {
      final success = await propertyService.renewProperty(property.id);
      if (success) renewedCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.renewedSuccessfully(renewedCount) ?? '$renewedCount properties renewed successfully!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      _loadUserProperties();
      _refreshUserProfile();
    }
  }

  void _showNotificationsPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.1),
      builder: (context) => const Stack(
        children: [
          Positioned(
            top: 80,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: NotificationPopup(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadgeButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 22),
            onPressed: onTap,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: ThemeService.getDynamicStyle(
                  context,
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
  
  String _formatMemberSince(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return formatDateWithEnglishNumbers(date, 'yMMM', locale);
  }

  Future<void> _refreshUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Refresh user profile from Firestore to get latest office status
    await authProvider.refreshUser();
    
    // Refresh verification status from Firebase
    if (authProvider.sessionToken != null) {
      await authProvider.checkEmailVerification(authProvider.sessionToken!);
      
      // Sync with notification system
      if (mounted && authProvider.currentUser != null) {
        await Provider.of<NotificationService>(context, listen: false)
            .checkVerificationStatus(authProvider.currentUser!, context);
      }
    }

    if (mounted) {
      setState(() {});
    }
  }


  Future<void> _loadUserProperties() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser != null) {
      final propertyService = property_service.PropertyService();
      await propertyService.enforceSlotLimits(currentUser.id);
      await authProvider.refreshUser(); // Refresh user data to get updated totalListings after deduction
      await ProfileService.loadUserProperties(currentUser.id);
      if (mounted) {
        setState(() {});
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Check authentication
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    final user = authProvider.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          title: Text(
            l10n?.profile ?? 'Profile',
            style: ThemeService.getHeadingStyle(
              context,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF01352D),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            LanguageToggleButton(languageService: languageService),
          ],
        ),
        body: const Center(
          child: DaryLoadingIndicator(),
        ),
      );
    }

    final activeListings = ProfileService.activeListings;
    final totalListings = user.totalListings;
    final activeCount = ProfileService.activeListings.length;
    final visibleListings = ProfileService.userListings.where((l) => !l.isDeleted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern Gradient App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF01352D),
                    Color(0xFF024035),
                    Color(0xFF015F4D),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n?.profile ?? 'Profile',
                                style: ThemeService.getDynamicStyle(
                                  context,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                                const Spacer(),
                                Consumer<NotificationService>(
                                  builder: (context, notificationService, _) {
                                    return _buildHeaderBadgeButton(
                                      icon: Icons.notifications_rounded,
                                      onTap: () => _showNotificationsPopup(context),
                                      badgeCount: notificationService.unreadCount,
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                LanguageToggleButton(languageService: languageService),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () async {
                await _refreshUserProfile();
                await _loadUserProperties();
              },
              child: Column(
              children: [
                // Verification Warning Banner
                if (!user.isVerified)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_unread_rounded, color: Colors.red.shade700, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.pleaseVerifyEmail ?? 'Verify Your Email',
                                style: ThemeService.getDynamicStyle(
                                  context,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n?.verificationEmailSentDesc ?? 'A verification link was sent to your email. Please verify it to access all features.',
                                style: ThemeService.getDynamicStyle(
                                  context,
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _isResendingEmail ? null : () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final token = authProvider.sessionToken;
                            if (token != null) {
                              setState(() => _isResendingEmail = true);
                              try {
                                await authProvider.sendEmailVerification();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n?.verificationEmailSent ?? 'Verification email sent!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  final errorMsg = e.toString().contains('Too many attempts')
                                    ? 'Too many attempts. Please try again later.'
                                    : e.toString();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(errorMsg),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isResendingEmail = false);
                                }
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade900,
                            backgroundColor: Colors.red.shade100,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isResendingEmail 
                            ? const DaryLoadingIndicator(size: 16, strokeWidth: 2, color: Color(0xFF991B1B))
                            : Text(l10n?.resend ?? 'Resend'),
                        ),
                      ],
                    ),
                  ),

                // Premium Profile Header with Cover Image
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Cover Image Container
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF01352D),
                        image: user.coverImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(user.coverImageUrl!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withValues(alpha: 0.2),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                      ),
                      child: user.coverImageUrl == null
                          ? Center(
                              child: Opacity(
                                opacity: 0.1,
                                child: Image.asset(
                                  'assets/images/darylogo2.png',
                                  width: 150,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.home, size: 80, color: Colors.white),
                                ),
                              ),
                            )
                          : null,
                    ),
                    
                    // Gradient overlay for better text readability
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Edit Cover Button (visible for owner)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                l10n?.editCover ?? 'Edit Cover',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Profile Content overlapping cover
                    Positioned(
                      bottom: -60,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          // Profile Image with white border
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: const Color(0xFF01352D),
                                  child: user.profileImageUrl != null
                                      ? ClipOval(
                                          child: Image.network(
                                            user.profileImageUrl!,
                                            width: 110,
                                            height: 110,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => 
                                                const Icon(Icons.person, size: 55, color: Colors.white),
                                          ),
                                        )
                                      : const Icon(Icons.person, size: 55, color: Colors.white),
                                ),
                              ),
                              if (user.isVerified)
                                Positioned(
                                  bottom: 5,
                                  right: 5,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.verified, color: Colors.green, size: 24),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 70),
                
                // Name and Basic Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF01352D),
                            ),
                          ),
                          if (user.isVerified) ...[
                            const SizedBox(width: 8),
                            const Tooltip(
                              message: 'Verified Account',
                              child: Icon(Icons.verified, color: Colors.green, size: 22),
                            ),
                          ] else ...[
                            const SizedBox(width: 8),
                            const Tooltip(
                              message: 'Unverified Account',
                              child: Icon(Icons.error_outline, color: Colors.red, size: 22),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n?.idLabel ?? "ID"}: ${user.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            l10n?.memberSince(_formatMemberSince(user.joinDate, context)) ?? 'Member since ${_formatMemberSince(user.joinDate, context)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: Colors.blue, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                l10n?.verifiedSeller ?? 'Verified Seller',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // Stats Row Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          l10n?.statActiveListings ?? 'Active Listings',
                          '$activeCount',
                          Icons.check_circle,
                        ),
                        Container(height: 30, width: 1, color: Colors.grey[200]),
                        _buildStatItem(
                          'Credits',
                          '${user.postingCredits}',
                          Icons.account_balance_wallet_outlined,
                        ),
                      ],
                    ),
                  ),
                ),


                const SizedBox(height: 24),

                // Property Slots Status Section
                // Posting Credits Section
                _buildPostingCreditsSection(user, authProvider),
                
                const SizedBox(height: 24),
                
                // Active Listings Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.myListings ?? 'My Listings',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (totalListings > 0)
                                Text(
                                  l10n?.propertiesCount(ProfileService.userListings.where((l) => !l.isDeleted).length) ?? '${ProfileService.userListings.where((l) => !l.isDeleted).length} properties',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          if (totalListings > 0)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isSelectionMode = !_isSelectionMode;
                                  if (!_isSelectionMode) {
                                    _selectedListingIds.clear();
                                  }
                                });
                              },
                              icon: Icon(
                                _isSelectionMode ? Icons.close : Icons.select_all_rounded,
                                size: 18,
                                color: _isSelectionMode ? Colors.red : const Color(0xFF01352D),
                              ),
                              label: Text(
                                _isSelectionMode ? (l10n?.cancel ?? 'Cancel') : (l10n?.select ?? 'Select'),
                                style: TextStyle(
                                  color: _isSelectionMode ? Colors.red : const Color(0xFF01352D),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      if (_isSelectionMode && _selectedListingIds.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF01352D).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF01352D).withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n?.selectedCount(_selectedListingIds.length) ?? '${_selectedListingIds.length} Selected',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF01352D),
                                ),
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        if (_selectedListingIds.length == visibleListings.length) {
                                          _selectedListingIds.clear();
                                        } else {
                                          _selectedListingIds.addAll(visibleListings.map((l) => l.id));
                                        }
                                      });
                                    },
                                    child: Text(
                                      _selectedListingIds.length == visibleListings.length 
                                          ? (l10n?.deselectAll ?? 'Deselect All') 
                                          : (l10n?.selectAll ?? 'Select All'),
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF01352D)),
                                    ),
                                  ),
                                    IconButton(
                                      icon: const Icon(Icons.unarchive_outlined, color: Color(0xFF01352D)),
                                      onPressed: () => _showBulkPublishDialog(),
                                      tooltip: 'Publish Selected (Uses Credits)',
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.archive_outlined, color: Colors.orange),
                                    onPressed: () => _showBulkUnpublishDialog(),
                                    tooltip: 'Unpublish Selected',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _showBulkDeleteDialog(),
                                    tooltip: l10n?.deleteSelected ?? 'Delete Selected',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      
                      if (totalListings == 0)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.home_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n?.noListingsYet ?? 'No listings yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        (() {
                          final displayCount = _showAllListings ? visibleListings.length : (visibleListings.length > 3 ? 3 : visibleListings.length);
                          
                          return Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayCount,
                                itemBuilder: (context, index) {
                                  final listing = visibleListings[index];
                                  final isSelected = _selectedListingIds.contains(listing.id);
                                  
                                  return Row(
                                    children: [
                                      if (_isSelectionMode)
                                        Checkbox(
                                          value: isSelected,
                                          activeColor: const Color(0xFF01352D),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedListingIds.add(listing.id);
                                              } else {
                                                _selectedListingIds.remove(listing.id);
                                              }
                                            });
                                          },
                                        ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: _isSelectionMode ? () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedListingIds.remove(listing.id);
                                              } else {
                                                _selectedListingIds.add(listing.id);
                                              }
                                            });
                                          } : null,
                                          child: UserListingCard(
                                            listing: listing,
                                            onUpdated: () {
                                              _loadUserProperties();
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              // Show More / Show Less button
                              if (visibleListings.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _showAllListings = !_showAllListings;
                                        });
                                      },
                                      icon: Icon(
                                        _showAllListings ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        color: const Color(0xFF01352D),
                                      ),
                                      label: Text(
                                        _showAllListings 
                                            ? (l10n?.showLess ?? 'Show Less') 
                                            : (l10n?.showMoreCount(visibleListings.length - 3) ?? 'Show More (${visibleListings.length - 3} more)'),
                                        style: const TextStyle(
                                          color: Color(0xFF01352D),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        side: const BorderSide(color: Color(0xFF01352D)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        })(),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Account Management Section - Clean list style
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.accountManagement ?? 'Account Management',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Clean list container
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildListTile(
                              icon: Icons.person_outline,
                              title: l10n?.editProfile ?? 'Edit Profile',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildListTile(
                              icon: Icons.favorite_border,
                              title: l10n?.myFavorites ?? 'My Favorites',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const FavoritesScreen(),
                                  ),
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildListTile(
                              icon: Icons.notifications_none,
                              title: l10n?.notificationSettings ?? 'Notifications',
                              onTap: () => context.go('/notification-settings'),
                            ),
                            _buildDivider(),
                            _buildListTile(
                              icon: Icons.analytics_outlined,
                              title: l10n?.viewAnalytics ?? 'View Analytics',
                              onTap: () => context.go('/analytics'),
                            ),
                            _buildDivider(),
                            _buildListTile(
                              icon: FontAwesomeIcons.whatsapp,
                              title: l10n?.becomeRealEstateOffice ?? 'Become a Real Estate Office',
                              iconColor: const Color(0xFF25D366),
                              onTap: () async {
                                final l10nLocal = AppLocalizations.of(context);
                                const phone = '218911322666'; // Primary support number
                                final String messageText = l10nLocal?.realEstateOfficeRequestMessage(user.name, user.id) ?? 
                                    'مرحباً، أود ترقية حسابي إلى مكتب عقاري.\nالاسم: ${user.name}\nرقم الحساب: ${user.id}';
                                final message = Uri.encodeComponent(messageText);
                                final uri = Uri.parse('https://wa.me/$phone?text=$message');
                                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                              },
                            ),
                            if (user.isRealEstateOffice) ...[
                              _buildDivider(),
                              _buildListTile(
                                icon: Icons.business_outlined,
                                title: l10n?.officeDashboard ?? 'Office Dashboard',
                                onTap: () => context.go('/office-dashboard'),
                              ),
                            ],
                            if (user.isAdmin) ...[
                              _buildDivider(),
                              _buildListTile(
                                icon: Icons.admin_panel_settings_outlined,
                                title: l10n?.adminDashboard ?? 'Admin Dashboard',
                                iconColor: Colors.red,
                                onTap: () => context.go('/admin'),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Upgrade Section
                      Text(
                        l10n?.upgrade ?? 'Upgrade',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildDivider(),
                            _buildListTile(
                              icon: Icons.rocket_launch_outlined,
                              title: l10n?.boostListing ?? 'Boost Listing',
                              onTap: () => context.push('/boost'),
                            ),
                            _buildDivider(),
                            _buildListTile(
                              icon: Icons.star_outline,
                              title: l10n?.buyCredits ?? 'Buy Points',
                              onTap: () => context.push('/paywall'),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Information Section
                      Text(
                        l10n?.information ?? 'Information',
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildListTile(
                              icon: Icons.info_outline,
                              title: l10n?.aboutUs ?? 'About Us',
                              onTap: () {
                                _showEnhancedInfoSheet(
                                  context, 
                                  title: l10n?.aboutUs ?? 'About Us',
                                  icon: Icons.info_rounded,
                                  sections: [
                                    {
                                      'title': l10n?.whoWeAreTitle ?? 'Who We Are',
                                      'content': l10n?.whoWeAreContent ?? 'Dary is the ultimate Libyan digital real estate companion. We’ve built more than just an app; we’ve created a seamless marketplace where property dreams become reality. From high-end villas to cozy apartments, we bridge the gap between Libyan homeowners and seekers.',
                                    },
                                    {
                                      'title': l10n?.ourMissionTitle ?? 'Our Mission',
                                      'content': l10n?.ourMissionContent ?? 'To revolutionize the Libyan real estate market through transparency, technology, and trust. We empower users with detailed insights, high-quality media, and direct communication channels.',
                                    },
                                    {
                                      'title': l10n?.whyDaryTitle ?? 'Why Dary?',
                                      'content': l10n?.whyDaryContent ?? '• Verified Listings\n• Secure Direct Contact\n• Advanced Filtering\n• Real-time Analytics\n• Specialized Office Dashboards',
                                    },
                                  ],
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildListTile(
                              icon: Icons.description_outlined,
                              title: l10n?.termsAndConditions ?? 'Terms & Conditions',
                              onTap: () {
                                _showEnhancedInfoSheet(
                                  context, 
                                  title: l10n?.termsAndConditions ?? 'Terms & Conditions',
                                  icon: Icons.description_rounded,
                                  sections: [
                                    {
                                      'title': l10n?.userAgreementTitle ?? '1. User Agreement',
                                      'content': l10n?.userAgreementContent ?? 'By accessing Dary, you agree to provide authentic information. Users are responsible for all activity under their accounts.',
                                    },
                                    {
                                      'title': l10n?.listingAuthenticityTitle ?? '2. Listing Authenticity',
                                      'content': l10n?.listingAuthenticityContent ?? 'All properties must be genuine. False advertising, misleading prices, or duplicate listings are strictly prohibited and will lead to account suspension.',
                                    },
                                    {
                                      'title': l10n?.communicationTitle ?? '3. Communication',
                                      'content': l10n?.communicationContent ?? 'Dary facilitates connection but is not responsible for external agreements between users. Always exercise caution and verify property details in person.',
                                    },
                                    {
                                      'title': l10n?.paymentServicesTitle ?? '4. Payment Services',
                                      'content': l10n?.paymentServicesContent ?? 'Premium features and wallet recharges are final. Payments are handled via secure third-party integration (Ma\'amalat).',
                                    },
                                  ],
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildListTile(
                              icon: Icons.shield_outlined,
                              title: l10n?.privacyPolicy ?? 'Privacy Policy',
                              onTap: () {
                                final locale = Localizations.localeOf(context).languageCode;
                                final isArabic = locale == 'ar';
                                final now = DateTime.now();
                                final date = isArabic ? 'يناير 2026' : 'January 2026';
                                
                                _showEnhancedInfoSheet(
                                  context, 
                                  title: l10n?.privacyPolicy ?? 'Privacy Policy',
                                  icon: Icons.shield_rounded,
                                  sections: isArabic ? _arabicPrivacySections(date) : _englishPrivacySections(date),
                                );
                              },
                            ),
                            _buildDivider(),
                            _buildListTile(
                              icon: Icons.headset_mic_outlined,
                              title: l10n?.contactUs ?? 'Contact Us',
                              onTap: () {
                                _showContactDialog(context);
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Danger Zone
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildListTile(
                              icon: Icons.logout_rounded,
                              title: l10n?.logout ?? 'Logout',
                              onTap: () => _showLogoutDialog(context),
                            ),
                            _buildDivider(),
                            _buildListTile(
                              icon: Icons.delete_outline,
                              title: l10n?.deleteAccount ?? 'Delete Account',
                              iconColor: Colors.red,
                              textColor: Colors.red,
                              onTap: () => _showDeleteAccountDialog(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF01352D).withValues(alpha: 0.7),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: ThemeService.getDynamicStyle(
            context,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF01352D),
          ),
        ),
        Text(
          label,
          style: ThemeService.getDynamicStyle(
            context,
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  // Clean list tile style like reference image
  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? Colors.grey[700],
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: ThemeService.getDynamicStyle(
                  context,
                  fontSize: 16,
                  color: textColor ?? Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 54,
      color: Colors.grey[200],
    );
  }
  
  void _showEnhancedInfoSheet(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Map<String, String>> sections,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Back Arrow Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF01352D),
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF01352D).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF01352D),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF01352D),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    ...sections.map((section) => Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildContactSectionLabel(section['title']!),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              section['content']!,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, String>> _englishPrivacySections(String date) => [
    {
      'title': 'Last Updated',
      'content': date,
    },
    {
      'title': '1. Data Collection',
      'content': 'We collect your name, email, phone number, and device logs to provide a personalized real estate experience.',
    },
    {
      'title': '2. Financial Security',
      'content': 'Payment transactions are handled securely via Ma\'amalat. We do not store your sensitive credit card data on our servers.',
    },
    {
      'title': '3. Information Usage',
      'content': 'Your data is used to process property listings, facilitate chat between users, and prevent fraudulent activity.',
    },
  ];

  List<Map<String, String>> _arabicPrivacySections(String date) => [
    {
      'title': 'آخر تحديث',
      'content': date,
    },
    {
      'title': '1. جمع البيانات',
      'content': 'نقوم بجمع اسمك وبريدك الإلكتروني ورقم هاتفك وسجلات الجهاز لتقديم تجربة عقارية مخصصة.',
    },
    {
      'title': '2. الأمان المالي',
      'content': 'يتم التعامل مع معاملات الدفع بشكل آمن عبر شركة معاملات. نحن لا نخزن بيانات بطاقتك الائتمانية الحساسة على خوادمنا.',
    },
    {
      'title': '3. استخدام المعلومات',
      'content': 'تُستخدم بياناتك لمعالجة قوائم العقارات، وتسهيل الدردشة بين المستخدمين، ومنع أي نشاط احتيالي.',
    },
  ];
  
  void _showContactDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAF9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Back Arrow Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF01352D),
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF01352D).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.headset_mic_rounded,
                      color: Color(0xFF01352D),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                   Text(
                    l10n?.getInTouch ?? 'Get in Touch',
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF01352D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.reachOutHelp ?? 'We\'re here to help you with any questions',
                    textAlign: TextAlign.center,
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Contact Items
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildContactItem(
                      icon: Icons.email_rounded,
                      title: l10n?.emailSupport ?? 'Email Support',
                      subtitle: 'support@dary.ly',
                      description: l10n?.response24h ?? 'Response within 24 hours',
                      color: const Color(0xFF01352D),
                      onTap: () async {
                        final uri = Uri.parse('mailto:support@dary.ly?subject=Dary%20Support%20Request');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone Section
                    _buildContactSectionLabel(l10n?.callUs ?? 'Call Us'),
                    const SizedBox(height: 8),
                    _buildContactItem(
                      icon: Icons.phone_in_talk_rounded,
                      title: l10n?.lineCount(1) ?? 'Line 1',
                      subtitle: '091 1322666',
                      color: const Color(0xFF01352D),
                      onTap: () async {
                        final uri = Uri.parse('tel:0911322666');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      icon: Icons.phone_in_talk_rounded,
                      title: l10n?.lineCount(2) ?? 'Line 2',
                      subtitle: '092 1322666',
                      color: const Color(0xFF01352D),
                      onTap: () async {
                        final uri = Uri.parse('tel:0921322666');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      },
                    ),
                    const SizedBox(height: 16),

                    // WhatsApp Section
                    _buildContactSectionLabel(l10n?.whatsAppChat ?? 'WhatsApp Chat'),
                    const SizedBox(height: 8),
                    _buildContactItem(
                      icon: FontAwesomeIcons.whatsapp,
                      title: l10n?.supportDeskCount(1) ?? 'Support Desk 1',
                      subtitle: '091 1322666',
                      color: const Color(0xFF25D366),
                      onTap: () async {
                        const phone = '218911322666';
                        final message = Uri.encodeComponent('Hi Dary Support, I need assistance.');
                        final uri = Uri.parse('https://wa.me/$phone?text=$message');
                        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      icon: FontAwesomeIcons.whatsapp,
                      title: l10n?.supportDeskCount(2) ?? 'Support Desk 2',
                      subtitle: '092 1322666',
                      color: const Color(0xFF25D366),
                      onTap: () async {
                        const phone = '218921322666';
                        final message = Uri.encodeComponent('Hi Dary Support, I need assistance.');
                        final uri = Uri.parse('https://wa.me/$phone?text=$message');
                        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: ThemeService.getDynamicStyle(
          context,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: ThemeService.getDynamicStyle(
                          context,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: ThemeService.getDynamicStyle(
                          context,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: ThemeService.getDynamicStyle(
                            context,
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ThemeService.getHeadingStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: ThemeService.getBodyStyle(
                        context,
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPropertyLimitModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaywallScreen(),
    ).then((_) => _loadUserProperties());
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      context.go('/');
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n?.logout ?? 'Logout'),
          content: Text(l10n?.areYouSureLogout ?? 'Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
              child: Text(
                l10n?.logout ?? 'Logout',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => const _DeleteAccountDialog(),
    );
  }


  String _englishPrivacyPolicy(String date) => '''
Last updated: $date

Thank you for using Dary (“we”, “our”, or “us”). We respect your privacy and are committed to protecting your personal information.

1. Information We Collect
We collect the following information when you use our app:
• Personal Information: Your name, email address, phone number, and login credentials.
• Payment Information: Transaction information. (Payments are processed securely via Ma'amalat).
• Usage Data: Device information, IP address, and activity logs.

2. How We Use Your Information
We use your information to:
• Provide and improve our services.
• Manage your account and process payments.
• Communicate with you about your account and updates.
• Ensure security and prevent fraud.

2.1 Payment Information
We use Ma’amalat to handle payments. When you make a payment, you are redirected to their secure page.
• Your information is handled directly by Ma’amalat. We do not store your sensitive payment data.
• All transactions are conducted over a secure (HTTPS) connection.

3. Data Sharing
We do not sell your personal information. We may share data with trusted service providers who help us operate the app (payment processors, analytics).

4. Security
We implement appropriate technical measures to protect your personal data.

5. Your Rights
You may have the right to access, correct, or delete your personal data. Contact us at support@dary.ly.

6. Changes to This Policy
We may update this policy from time to time.
''';

  String _arabicPrivacyPolicy(String date) => '''
آخر تحديث: $date

شكرًا لاستخدامك تطبيق Dary (“نحن” أو “لنا”). نحن نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية.

1. المعلومات التي نجمعها
نقوم بجمع المعلومات التالية عند استخدامك للتطبيق:
• المعلومات الشخصية: الاسم، البريد الإلكتروني، رقم الهاتف، وبيانات تسجيل الدخول.
• معلومات الدفع: معلومات المعاملات (تتم المعالجة بأمان عبر معاملات).
• بيانات الاستخدام: معلومات الجهاز، عنوان IP، وسجلات النشاط.

2. كيفية استخدامنا لمعلوماتك
• تقديم خدماتنا وتحسينها.
• إدارة حسابك ومعالجة المدفوعات.
• التواصل معك بشأن حسابك والتحديثات.
• ضمان الأمان ومنع الاحتيال.

2.1 معلومات الدفع
نستخدم شركة معاملات لمعالجة المدفوعات. عند الدفع، يتم توجيهك إلى صفحتهم الآمنة.
• يتم التعامل مع بياناتك مباشرة من قبل شركة معاملات، ولا نخزن بيانات الدفع الحساسة.
• جميع العمليات تتم عبر اتصال آمن (HTTPS).

3. مشاركة البيانات
نحن لا نبيع معلوماتك الشخصية. قد نشارك البيانات مع شركاء موثوقين (معالجي الدفع، التحليلات).

4. الأمان
نطبق التدابير المناسبة لحماية بياناتك من الوصول غير المصرح به.

5. حقوقك
لديك الحق في الوصول إلى بياناتك أو تصحيحها أو حذفها. تواصل معنا على support@dary.ly.

6. التغييرات على السياسة
قد نقوم بتحديث هذه السياسة من وقت لآخر.
''';
  Future<void> _showBulkDeleteDialog() async {
    final count = _selectedListingIds.length;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppLocalizations.of(context)?.deletePropertiesCountTitle(count) ?? 'Delete $count Properties?', 
          style: ThemeService.getDynamicStyle(context, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.of(context)?.deletePropertiesConfirmation(count) ?? 'Are you sure you want to delete the selected $count properties? This action cannot be undone and these slots will remain used (burned).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)?.cancel ?? 'Cancel', 
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(AppLocalizations.of(context)?.deleteAll ?? 'Delete All'),
          ),
        ],
      ),
    );

    if (proceed == true && mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: DaryLoadingIndicator(color: Color(0xFF01352D))),
      );

      final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
      int successCount = 0;
      
      for (final id in _selectedListingIds) {
        final success = await propertyService.deleteProperty(id);
        if (success) successCount++;
      }

      if (mounted) {
        Navigator.pop(context); // Close loading indicator
        
        setState(() {
          _isSelectionMode = false;
          _selectedListingIds.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.deletePropertiesSuccessCount(successCount, count) ?? 'Successfully deleted $successCount out of $count properties',
            ),
            backgroundColor: successCount == count ? Colors.green : Colors.orange,
          ),
        );

        _loadUserProperties();
      }
    }
  }

  Future<void> _showBulkUnpublishDialog() async {
    final count = _selectedListingIds.length;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n?.unpublishPropertiesTitle(count) ?? 'Unpublish $count Properties?', 
          style: ThemeService.getDynamicStyle(context, fontWeight: FontWeight.bold),
        ),
        content: Text(l10n?.unpublishConfirmMessage ?? 'Are you sure you want to unpublish the selected properties? they will disappear from public search.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF01352D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n?.unpublishAll ?? 'Unpublish All'),
          ),
        ],
      ),
    );

    if (proceed == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: DaryLoadingIndicator(color: Color(0xFF01352D))),
      );

      final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
      int successCount = 0;
      
      for (final id in _selectedListingIds) {
        final success = await propertyService.unpublishProperty(id);
        if (success) successCount++;
      }

      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _isSelectionMode = false;
          _selectedListingIds.clear();
        });
        _loadUserProperties();
      }
    }
  }

  Future<void> _showBulkPublishDialog() async {
    final count = _selectedListingIds.length;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshUser();
    final user = authProvider.currentUser;
    if (user == null) return;

    final selectedProperties = ProfileService.userListings
        .where((l) => _selectedListingIds.contains(l.id))
        .toList();

    // Check if user has enough credits
    if (user.postingCredits < count) {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const PaywallScreen(),
        );
      }
      return;
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n?.publishPropertiesTitle(count) ?? 'Publish $count Properties?', 
          style: ThemeService.getDynamicStyle(context, fontWeight: FontWeight.bold),
        ),
        content: Text(l10n?.publishUseSomeSlotsMessage(count) ?? 'This will use $count of your available credits. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF01352D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(l10n?.publishAll ?? 'Publish All'),
          ),
        ],
      ),
    );

    if (proceed == true && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: DaryLoadingIndicator(color: Color(0xFF01352D))),
      );

      final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
      int successCount = 0;
      
      for (final id in _selectedListingIds) {
        final success = await propertyService.publishProperty(id);
        if (success) successCount++;
      }

      if (mounted) {
        Navigator.pop(context);
        await authProvider.refreshUser();
        setState(() {
          _isSelectionMode = false;
          _selectedListingIds.clear();
        });
        _loadUserProperties();
      }
    }
  }

  Widget _buildPostingCreditsSection(UserProfile user, AuthProvider authProvider) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF01352D),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n?.postingCreditsTitle ?? 'Points',
                style: ThemeService.getDynamicStyle(
                  context,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF01352D), Color(0xFF024035)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF01352D).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.totalBalance ?? 'Total Balance',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user.postingCredits} ${l10n?.creditsLabel ?? 'Points'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/paywall'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF01352D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: Text(
                    l10n?.buyNow ?? 'Buy More',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.postingCreditFooter ?? 'Each property listing consumes 1 posting credit.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _resetFreeTierSlots(String userId) async {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAr = languageService.isArabic;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAr ? 'إعادة تعيين الخانات المجانية' : 'Reset Free Slots'),
        content: Text(isAr 
          ? 'هل تريد إعادة تعيين الخانات المجانية الثلاث مقابل 30 دينار ليبي؟ سيؤدي هذا إلى مسح الخانات المستهلكة حتى تتمكن من استخدامها مرة أخرى.'
          : 'Do you want to reset your 3 free slots for 30 LYD? This will clear burned slots so you can use them again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text(isAr ? 'إلغاء' : 'Cancel')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(isAr ? 'إعادة تعيين (30 د.ل)' : 'Reset (30 LYD)')
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final propertyService = property_service.PropertyService();
      final success = await propertyService.resetFreeTierSlots(userId);
      if (success) {
        await authProvider.refreshUser();
        if (mounted) {
          setState(() {});
          _loadUserProperties();
        }
      }
    }
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isLoading = false;
  XFile? _selectedImage;
  Uint8List? _webImage;
  String? _profileImageUrl;
  
  XFile? _selectedCoverImage;
  Uint8List? _webCoverImage;
  String? _coverImageUrl;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    _nameController = TextEditingController(text: currentUser?.name ?? '');
    _phoneController = TextEditingController(text: currentUser?.phone ?? '');
    _profileImageUrl = currentUser?.profileImageUrl;
    _coverImageUrl = currentUser?.coverImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool isCover = false}) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isCover ? 1920 : 800,
        maxHeight: isCover ? 1080 : 800,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            if (isCover) {
              _selectedCoverImage = image;
              _webCoverImage = bytes;
            } else {
              _selectedImage = image;
              _webImage = bytes;
            }
          });
        } else {
          setState(() {
            if (isCover) {
              _selectedCoverImage = image;
            } else {
              _selectedImage = image;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.errorPickingImage(e.toString()) ?? 'Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadAndSaveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      if (userId == null) return;
      
      final supabase = Supabase.instance.client;
      const bucketName = 'property-images';
      
      String? profileUrl = _profileImageUrl;
      String? coverUrl = _coverImageUrl;
      
      // Upload profile image if selected
      if (_selectedImage != null) {
        final extension = _selectedImage!.name.split('.').last;
        final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        
        if (kIsWeb) {
          final imageBytes = _webImage ?? await _selectedImage!.readAsBytes();
          await supabase.storage.from(bucketName).uploadBinary(fileName, imageBytes);
        } else {
          await supabase.storage.from(bucketName).upload(fileName, File(_selectedImage!.path));
        }
        profileUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);
      }

      // Upload cover image if selected
      if (_selectedCoverImage != null) {
        final extension = _selectedCoverImage!.name.split('.').last;
        final fileName = 'cover_${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
        
        if (kIsWeb) {
          final imageBytes = _webCoverImage ?? await _selectedCoverImage!.readAsBytes();
          await supabase.storage.from(bucketName).uploadBinary(fileName, imageBytes);
        } else {
          await supabase.storage.from(bucketName).upload(fileName, File(_selectedCoverImage!.path));
        }
        coverUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);
      }
      
      // Update profile
      final success = await authProvider.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        profileImageUrl: profileUrl,
        coverImageUrl: coverUrl,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.profileUpdatedSuccess ?? 'Profile updated successfully!'),
              backgroundColor: const Color(0xFF01352D),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.profileUpdateFail ?? 'Failed to update profile. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.errorUpdatingProfile(e.toString()) ?? 'Error updating profile: $e')),
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


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(child: Text(l10n?.noUserFound ?? 'No user found')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Modern Gradient App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF01352D),
                    Color(0xFF024035),
                    Color(0xFF015F4D),
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                background: Stack(
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
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n?.editProfile ?? 'Edit Profile',
                                      style: ThemeService.getDynamicStyle(
                                        context,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                      Text(
                                      l10n?.updatePersonalInfo ?? 'Update your personal information',
                                      style: ThemeService.getDynamicStyle(
                                        context,
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              LanguageToggleButton(languageService: languageService),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Header Image Section (Cover + Profile)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Cover Image
                    GestureDetector(
                      onTap: () => _pickImage(isCover: true),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          image: (_selectedCoverImage != null)
                              ? (kIsWeb 
                                  ? DecorationImage(image: MemoryImage(_webCoverImage!), fit: BoxFit.cover)
                                  : DecorationImage(image: FileImage(File(_selectedCoverImage!.path)), fit: BoxFit.cover))
                              : (_coverImageUrl != null
                                  ? DecorationImage(image: NetworkImage(_coverImageUrl!), fit: BoxFit.cover)
                                  : null),
                        ),
                        child: (_selectedCoverImage == null && _coverImageUrl == null)
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    Text(l10n?.tapToAddCover ?? 'Tap to add cover photo', style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              )
                            : Stack(
                                children: [
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                          const SizedBox(width: 4),
                                          Text(l10n?.changeCover ?? 'Change Cover', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // Profile Image
                    Positioned(
                      bottom: -50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _pickImage(isCover: false),
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  color: Colors.grey[200],
                                  image: (_selectedImage != null)
                                      ? (kIsWeb 
                                          ? DecorationImage(image: MemoryImage(_webImage!), fit: BoxFit.cover)
                                          : DecorationImage(image: FileImage(File(_selectedImage!.path)), fit: BoxFit.cover))
                                      : (_profileImageUrl != null
                                          ? DecorationImage(image: NetworkImage(_profileImageUrl!), fit: BoxFit.cover)
                                          : null),
                                ),
                                child: (_selectedImage == null && _profileImageUrl == null)
                                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF01352D),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // Form Section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Field
                        _buildInputField(
                          label: l10n?.fullName ?? 'Full Name',
                          hint: l10n?.enterFullName ?? 'Enter your full name',
                          controller: _nameController,
                          icon: Icons.person_outline,
                          formatters: [BasicTextFormatter()],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return l10n?.pleaseEnterName ?? 'Please enter your name';
                            if (value.trim().length < 2) return l10n?.nameTooShort ?? 'Name must be at least 2 characters';
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Email Field (Read-only)
                        _buildInputField(
                          label: l10n?.emailAddress ?? 'Email Address',
                          hint: 'Email',
                          initialValue: currentUser.email,
                          icon: Icons.email_outlined,
                          readOnly: true,
                          fillColor: Colors.grey[100],
                          textColor: Colors.grey[600],
                          suffix: const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Text(
                            l10n?.emailChangeInfo ?? 'This email is linked to your account and cannot be changed.',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Phone Field
                        _buildInputField(
                          label: l10n?.phoneNumber ?? 'Phone Number',
                          hint: l10n?.enterPhoneNumber ?? 'Enter your phone number',
                          controller: _phoneController,
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          formatters: [PhoneNumberFormatter()],
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (value.length < 8) return l10n?.phoneTooShort ?? 'Phone number is too short';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 48),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: Colors.grey[300]!),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text(
                                  l10n?.cancel ?? 'Cancel',
                                  style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _uploadAndSaveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF01352D),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: DaryLoadingIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        l10n?.saveChanges ?? 'Save Changes',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    TextEditingController? controller,
    String? initialValue,
    required IconData icon,
    bool readOnly = false,
    Color? fillColor,
    Color? textColor,
    Widget? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          readOnly: readOnly,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          validator: validator,
          style: TextStyle(color: textColor ?? Colors.black87, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF01352D), size: 22),
            suffixIcon: suffix,
            filled: true,
            fillColor: fillColor ?? Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF01352D), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.settings ?? 'Settings'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.settings,
              size: 64,
              color: Color(0xFF01352D),
            ),
            const SizedBox(height: 24),
            Text(
              l10n?.settings ?? 'Settings',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.customizeExperience ?? 'Customize your experience',
              style: const TextStyle(
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
