import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/property.dart';
import '../models/user_profile.dart';
import '../services/property_service.dart' as property_service;
import '../widgets/property_card.dart';
import '../l10n/app_localizations.dart';
import '../utils/number_formatter.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/dary_loading_indicator.dart';

class PublicUserProfileScreen extends StatefulWidget {
  final String userId;

  const PublicUserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<PublicUserProfileScreen> createState() => _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen> {
  UserProfile? _userProfile;
  List<Property> _userProperties = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  String? _coverImageUrl; // Task 6: Cover picture

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Load user profile from Firestore
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(widget.userId).get();

      if (!userDoc.exists) {
        setState(() {
          _hasError = true;
          _errorMessage = AppLocalizations.of(context)?.userNotFound ?? 'User not found';
          _isLoading = false;
        });
        return;
      }

      final userData = userDoc.data()!;
      final joinDate = _parseDate(userData['createdAt']) ?? DateTime.now();
      final updatedDate = _parseDate(userData['updatedAt']) ?? joinDate;
      
      _userProfile = UserProfile(
        id: userDoc.id,
        name: userData['name'] ?? 'Unknown User',
        email: userData['email'] ?? '',
        phone: userData['phone'],
        profileImageUrl: userData['profileImageUrl'],
        joinDate: joinDate,
        totalListings: (userData['totalListings'] as num?)?.toInt() ?? 0,
        activeListings: (userData['activeListings'] as num?)?.toInt() ?? 0,
        propertyLimit: (userData['propertyLimit'] as num?)?.toInt() ?? 5,
        createdAt: joinDate,
        updatedAt: updatedDate,
        isVerified: userData['isVerified'] ?? false,
        isAdmin: userData['isAdmin'] ?? false,
        isRealEstateOffice: userData['isRealEstateOffice'] ?? false,
      );
      
      // Task 6: Load cover image if it exists
      _coverImageUrl = userData['coverImageUrl'];

      // Load user properties
      final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
      _userProperties = await propertyService.getPropertiesByUser(widget.userId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load user profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _shareProfile() async {
    if (_userProfile == null) return;
    
    final l10n = AppLocalizations.of(context);
    final profileUrl = 'https://dary.ly/user/${_userProfile!.id}';
    
    final text = '${l10n?.shareProfileText(_userProfile!.name) ?? "Check out this profile on Dary: ${_userProfile!.name}"}\n'
        '${l10n?.viewMoreDetails ?? "View more details"}: $profileUrl';
    
    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        text,
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  // Helper function to parse date from Timestamp or String
  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.white,
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        },
        ),
        title: Text(
          _userProfile?.name ?? (AppLocalizations.of(context)?.profile ?? 'Profile'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF01352D),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareProfile,
            tooltip: AppLocalizations.of(context)?.share ?? 'Share',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: DaryLoadingIndicator(color: Color(0xFF01352D)))
          : _hasError
              ? _buildErrorState()
              : _userProfile == null
                  ? Center(child: Text(AppLocalizations.of(context)?.userNotFound ?? 'User not found'))
                  : RefreshIndicator(
                      onRefresh: _loadUserProfile,
                      color: const Color(0xFF01352D),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _buildHeaderSection(),
                            const SizedBox(height: 70),
                            _buildBasicInfoSection(),
                            const SizedBox(height: 24),
                            _buildStatsSection(),
                            const SizedBox(height: 32),
                            _buildPropertiesSection(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(fontSize: 16, color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF01352D), foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(context)?.goBack ?? 'Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover Image
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF01352D),
            image: _coverImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(_coverImageUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken),
                  )
                : null,
          ),
          child: _coverImageUrl == null
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
        
        // Gradient overlay
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

        // Profile Image overlapping
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ]),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: const Color(0xFF01352D),
                backgroundImage: _userProfile!.profileImageUrl != null ? NetworkImage(_userProfile!.profileImageUrl!) : null,
                child: _userProfile!.profileImageUrl == null
                    ? Icon(_userProfile!.isRealEstateOffice ? Icons.business : Icons.person, size: 55, color: Colors.white)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _userProfile!.name,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF01352D)),
              ),
              if (_userProfile!.isVerified) ...[
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: Colors.green, size: 24),
              ],
              if (_userProfile!.isRealEstateOffice) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF004D40).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    l10n?.office ?? 'OFFICE',
                    style: const TextStyle(color: Color(0xFF004D40), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${_userProfile!.id}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'monospace'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                l10n?.memberSince(formatDateWithEnglishNumbers(_userProfile!.joinDate, 'yMMM', Localizations.localeOf(context).languageCode)) ?? 
                    'Member since ${formatDateWithEnglishNumbers(_userProfile!.joinDate, 'yMMM', Localizations.localeOf(context).languageCode)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          if (_userProfile!.isRealEstateOffice) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.business, color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  Text(l10n?.realEstateOffice ?? 'Real Estate Office', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(l10n?.statTotalProperties ?? 'Total Properties', '${_userProperties.length}', Icons.home_outlined),
            Container(height: 30, width: 1, color: Colors.grey[100]),
            _buildStatItem(l10n?.statActiveListings ?? 'Active Listings', '${_userProperties.where((p) => p.isPublished && !p.isEffectivelyExpired).length}', Icons.check_circle_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF01352D).withValues(alpha: 0.7), size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF01352D))),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPropertiesSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n?.statAvailableProperties ?? 'Available Properties', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF01352D))),
              if (_userProperties.length > 5)
                Text(l10n?.totalCount(_userProperties.length) ?? '${_userProperties.length} total', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_userProperties.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.home_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(l10n?.noListingsYet ?? 'No listings yet', style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _userProperties.length,
            itemBuilder: (context, index) {
              final property = _userProperties[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PropertyCard(property: property),
              );
            },
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  // Pick/Upload removed as this is a public profile view for other users
  // (In a real app, logic for editing would stay in the private profile/settings only)
  Future<void> _pickProfileImage() async {}
  Future<void> _pickCoverImage() async {}
}
