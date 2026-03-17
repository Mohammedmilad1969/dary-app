import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../providers/auth_provider.dart';
import '../models/property.dart';
import '../features/chat/chat_service.dart';
import '../features/paywall/paywall_screens.dart';
import '../widgets/dary_loading_indicator.dart';
import '../models/user_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/property_service.dart' as property_service;

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late PageController _pageController;
  late PageController _fullScreenPageController;
  int _currentImageIndex = 0;
  bool _isFullScreen = false;
  bool _isCreatingConversation = false;
  bool _isFavorite = false;
  UserProfile? _sellerProfile;
  bool _isLoadingSeller = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fullScreenPageController = PageController();
    _trackView();
    _checkFavorite();
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.property.userId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        final l10n = AppLocalizations.of(context);
        setState(() {
          _sellerProfile = UserProfile(
            id: doc.id,
            name: data['name'] ?? (l10n?.unknownUser ?? 'Unknown User'),
            email: data['email'] ?? '',
            phone: data['phone'],
            profileImageUrl: data['profileImageUrl'],
            joinDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            totalListings: (data['totalListings'] as num?)?.toInt() ?? 0,
            activeListings: (data['activeListings'] as num?)?.toInt() ?? 0,
            propertyLimit: (data['propertyLimit'] as num?)?.toInt() ?? 5,
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isVerified: data['isVerified'] ?? false,
            isAdmin: data['isAdmin'] ?? false,
            isRealEstateOffice: data['isRealEstateOffice'] ?? false,
          );
          _isLoadingSeller = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingSeller = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSeller = false;
        });
      }
    }
  }

  Future<void> _checkFavorite() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) return;

      final propertyId = widget.property.id;
      final favoriteDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(propertyId)
          .get();

      if (mounted) {
        setState(() {
          _isFavorite = favoriteDoc.exists;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullScreenPageController.dispose();
    super.dispose();
  }

  void _trackView() {
    // Track view when property detail screen is opened (works for both logged-in and guest users)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
        
        // Ensure PropertyService is initialized
        if (propertyService.properties.isEmpty) {
          if (kDebugMode) {
            debugPrint('⚠️ PropertyService not initialized yet, initializing...');
          }
          // Initialize PropertyService for guest users
          propertyService.initialize();
        }
        
        propertyService.incrementViews(widget.property.id);
        if (kDebugMode) {
          debugPrint('👁️ View tracking initiated for property: ${widget.property.id}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error tracking view: $e');
        }
      }
    });
  }

  void _trackContactClick() {
    // Track contact click for analytics (works for both logged-in and guest users)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
        
        // Ensure PropertyService is initialized
        if (propertyService.properties.isEmpty) {
          if (kDebugMode) {
            debugPrint('⚠️ PropertyService not initialized yet, initializing...');
          }
          // Initialize PropertyService for guest users
          propertyService.initialize();
        }
        
        propertyService.trackContactClick(widget.property.id);
        if (kDebugMode) {
          debugPrint('📞 Contact click tracking initiated for property: ${widget.property.id}');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ Error tracking contact click: $e');
        }
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentImageIndex = index;
    });
  }

  void _openFullScreen(int initialIndex) {
    setState(() {
      _isFullScreen = true;
      _currentImageIndex = initialIndex;
    });
    _fullScreenPageController = PageController(initialPage: initialIndex);
  }

  void _closeFullScreen() {
    setState(() {
      _isFullScreen = false;
    });
  }

  Future<void> _contactSeller() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    final l10n = AppLocalizations.of(context);

    if (currentUser == null) {
      context.go('/login');
      return;
    }

    // Track contact click
    _trackContactClick();

    setState(() {
      _isCreatingConversation = true;
    });

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final conversation = await chatService.createConversation(
        propertyId: widget.property.id,
        buyerId: currentUser.id,
        sellerId: widget.property.userId,
        propertyTitle: widget.property.title,
        propertyImage: widget.property.imageUrls.isNotEmpty ? widget.property.imageUrls.first : null,
        sellerName: widget.property.agentName,
        buyerName: currentUser.name,
      );

      if (mounted && conversation != null) {
        if (kDebugMode) {
          debugPrint('✅ Conversation created successfully: ${conversation.id}');
        }
        context.go('/chat/${conversation.id}');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.failedToCreateConversation ?? 'Failed to create conversation. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (kDebugMode) {
          debugPrint('❌ Error creating conversation: $e');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.failedToStartConversation(e.toString()) ?? 'Failed to start conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingConversation = false;
        });
      }
    }
  }



  Future<void> _shareProperty() async {
    final l10n = AppLocalizations.of(context);
    // Create the property link using the app's custom scheme
    final propertyUrl = 'https://dary.ly/property/${widget.property.id}';
    
    final text = '${l10n?.sharePropertyText(widget.property.title, widget.property.city) ?? "Check out this property: ${widget.property.title} in ${widget.property.city}!"}\n'
        '${l10n?.price ?? "Price"}: ${widget.property.status == PropertyStatus.forRent ? "LYD ${widget.property.monthlyRent}/month" : "LYD ${widget.property.price}"}\n'
        '${widget.property.description}\n\n'
        '${l10n?.viewMoreDetails ?? "View more details"}: $propertyUrl';
    
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

  Future<void> _openWhatsApp() async {
    final l10n = AppLocalizations.of(context);
    final phoneNumber = widget.property.contactPhone;
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.noPhoneNumberAvailable ?? 'No phone number available')),
      );
      return;
    }
    
    final cleanedPhone = phoneNumber.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', '');
    
    final message = '${l10n?.whatsappMessageIntro ?? 'Hello! I am interested in this property:'}\n'
        '${widget.property.title}\n'
        '${l10n?.location ?? 'Location'}: ${widget.property.address.isNotEmpty ? "${widget.property.address}, " : ""}${widget.property.city}, ${widget.property.neighborhood}\n'
        '${l10n?.price ?? 'Price'}: ${widget.property.status == PropertyStatus.forRent ? "LYD ${widget.property.monthlyRent}/month" : "LYD ${widget.property.price}"}\n'
        '${l10n?.type ?? 'Type'}: ${widget.property.type.typeDisplayName}';
    
    String whatsappNumber;
    if (cleanedPhone.startsWith('+218')) {
      whatsappNumber = cleanedPhone.substring(1);
    } else if (cleanedPhone.startsWith('218')) {
      whatsappNumber = cleanedPhone;
    } else if (cleanedPhone.startsWith('09') || cleanedPhone.startsWith('9')) {
      whatsappNumber = '218${cleanedPhone.startsWith('09') ? cleanedPhone.substring(1) : cleanedPhone}';
    } else {
      whatsappNumber = cleanedPhone.startsWith('+') ? cleanedPhone.substring(1) : cleanedPhone;
    }
    
    final uri = Uri.parse('https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n?.whatsAppNotAvailable ?? 'Cannot open WhatsApp')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final l10n = AppLocalizations.of(context);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        context.go('/login');
        return;
      }

      final propertyId = widget.property.id;
      final favoritesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(propertyId);

      if (_isFavorite) {
        // Remove from favorites
        await favoritesRef.delete();
        // Decrement save count on property
        await FirebaseFirestore.instance.collection('properties').doc(propertyId).update({
          'save_count': FieldValue.increment(-1),
        });
      } else {
        // Add to favorites
        await favoritesRef.set({
          'propertyId': propertyId,
          'addedAt': FieldValue.serverTimestamp(),
        });
        // Increment save count on property
        await FirebaseFirestore.instance.collection('properties').doc(propertyId).update({
          'save_count': FieldValue.increment(1),
        });
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? (l10n?.addedToFavorites ?? 'Added to favorites') : (l10n?.removedFromFavorites ?? 'Removed from favorites')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _makePhoneCall() async {
    final l10n = AppLocalizations.of(context);
    final phoneNumber = widget.property.contactPhone;
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.noPhoneNumberAvailable ?? 'No phone number available')),
      );
      return;
    }
    
    final cleanedPhone = phoneNumber.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', '');
    final uri = Uri(scheme: 'tel', path: cleanedPhone);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n?.cannotMakePhoneCall ?? 'Cannot make phone call from this device')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // Action buttons bar: Call, WhatsApp, Share, Save
  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFF01352D).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF01352D).withValues(alpha: 0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF01352D).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Call Button
          Expanded(
            child: _buildActionButton(
              icon: Icons.call_rounded,
              label: l10n?.call ?? 'Call',
              color: Colors.green,
              onPressed: _makePhoneCall,
            ),
          ),
          const SizedBox(width: 10),
          // WhatsApp Button
          Expanded(
            child: _buildActionButton(
              icon: Icons.chat_rounded,
              label: l10n?.whatsApp ?? 'WhatsApp',
              color: const Color(0xFF25D366), // WhatsApp green
              onPressed: _openWhatsApp,
            ),
          ),
          const SizedBox(width: 10),
          // Share Button
          Expanded(
            child: _buildActionButton(
              icon: Icons.share_rounded,
              label: l10n?.share ?? 'Share',
              color: Colors.blue,
              onPressed: _shareProperty,
            ),
          ),
          const SizedBox(width: 10),
          // Save/Favorite Button
          Expanded(
            child: _buildActionButton(
              icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
              label: l10n?.save ?? 'Save',
              color: _isFavorite ? Colors.red : Colors.grey[600]!,
              onPressed: _toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }

  // Simple quick stat widget
  Widget _buildQuickStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  // Stat item for bottom stats
  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 22, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  // Simple action button
  Widget _buildSimpleActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary ? const Color(0xFF01352D) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
      onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrimary ? null : Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isPrimary ? Colors.white : Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n?.boostProperty ?? 'Boost Property',
          style: ThemeService.getDynamicStyle(
            context,
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          l10n?.boostPropertyDescription ?? 'Choose a premium package to boost your property visibility.',
          style: ThemeService.getDynamicStyle(
            context,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n?.cancel ?? 'Cancel',
              style: ThemeService.getDynamicStyle(
                context,
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/boost/${widget.property.id}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
            ),
            child: Text(
              l10n?.viewPackages ?? 'View Packages',
              style: ThemeService.getDynamicStyle(
                context,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.forSale:
        return const Color(0xFF01352D);
      case PropertyStatus.forRent:
        return const Color(0xFF01352D);
      case PropertyStatus.sold:
        return Colors.red;
      case PropertyStatus.rented:
        return Colors.orange;
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
            label,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF01352D).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF01352D)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF01352D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenImageViewer() {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _fullScreenPageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.property.imageUrls.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: Image.network(
                  widget.property.imageUrls[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: _closeFullScreen,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1} / ${widget.property.imageUrls.length}',
                style: ThemeService.getDynamicStyle(
                  context,
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (widget.property.imageUrls.length > 1) ...[
            Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentImageIndex > 0) {
                      _fullScreenPageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_currentImageIndex < widget.property.imageUrls.length - 1) {
                      _fullScreenPageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
            ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    if (authProvider.currentUser == null) {
                      context.go('/login');
                      return;
                    }
                    _toggleFavorite();
                  },
                ),
                ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareProperty,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Gallery - Edge to edge
                Hero(
                  tag: 'property_${widget.property.id}',
                  child: SizedBox(
                    height: 320,
                    child: widget.property.imageUrls.isNotEmpty
                        ? Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                onPageChanged: _onPageChanged,
                                itemCount: widget.property.imageUrls.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _openFullScreen(index),
                                    child: CachedNetworkImage(
                                      imageUrl: widget.property.imageUrls[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      fadeInDuration: const Duration(milliseconds: 500),
                                      fadeInCurve: Curves.easeIn,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: DaryLoadingIndicator(
                                            size: 40,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 64, color: Colors.grey),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Image counter
                              if (widget.property.imageUrls.length > 1)
                                Positioned(
                                  bottom: 32,
                                  right: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_currentImageIndex + 1}/${widget.property.imageUrls.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 14, decoration: TextDecoration.none),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.home, size: 64, color: Colors.grey),
                          ),
                  ),
                ),

                // Content
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                        ),
                      ),
                  transform: Matrix4.translationValues(0, -24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price & Title Card
                Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                            // Price
                              Text(
                                widget.property.getLocalizedPrice(context),
                                style: ThemeService.getDynamicStyle(
                                  context,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF01352D),
                                ),
                              ),
                            const SizedBox(height: 8),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(widget.property.status).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.property.status.getLocalizedName(context).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Title
                            Text(
                              widget.property.title,
                              style: ThemeService.getDynamicStyle(
                                context,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Property ID
                            SelectableText(
                              'ID: ${widget.property.id}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                                fontFamily: 'monospace',
                              ),
                                ),
                            const SizedBox(height: 8),
                            // Location
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                              child: Text(
                                    '${widget.property.neighborhood}, ${widget.property.city}',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Quick stats
                            Row(
                                  children: [
                                _buildQuickStat(Icons.bed_outlined, '${widget.property.bedrooms}'),
                                const SizedBox(width: 20),
                                _buildQuickStat(Icons.bathtub_outlined, '${widget.property.bathrooms}'),
                                const SizedBox(width: 20),
                                _buildQuickStat(Icons.square_foot_outlined, '${widget.property.sizeSqm} m²'),
                                  ],
                              ),
                            ],
                        ),
                        ),

                      _buildExpiryTimer(currentUser?.id == widget.property.userId),

                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                            Expanded(
                              child: _buildSimpleActionButton(
                                icon: Icons.phone_outlined,
                                label: l10n?.call ?? 'Call',
                                onPressed: () {
                                  if (authProvider.currentUser == null) {
                                    context.go('/login');
                                    return;
                                  }
                                  _makePhoneCall();
                                },
                                ),
                              ),
                            const SizedBox(width: 12),
                              Expanded(
                              child: _buildSimpleActionButton(
                                icon: Icons.chat_outlined,
                                label: l10n?.whatsApp ?? 'WhatsApp',
                                isPrimary: true,
                                onPressed: () {
                                  if (authProvider.currentUser == null) {
                                    context.go('/login');
                                    return;
                                  }
                                  _openWhatsApp();
                                },
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Location Section
                        _buildLocationSection(),
                        
                      // Property Details Card
                        Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        padding: const EdgeInsets.all(20),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                      Text(
                                l10n?.propertyDetails ?? 'Details',
                                style: ThemeService.getHeadingStyle(
                                  context,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                  ),
                            const SizedBox(height: 8),
                        _buildDetailRow(
                          icon: Icons.bed,
                          label: l10n?.bedrooms ?? 'Bedrooms',
                          value: widget.property.bedrooms.toString(),
                        ),
                        _buildDetailRow(
                          icon: Icons.bathtub,
                          label: l10n?.bathrooms ?? 'Bathrooms',
                          value: widget.property.bathrooms.toString(),
                        ),
                        _buildDetailRow(
                          icon: Icons.restaurant,
                          label: l10n?.kitchens ?? 'Kitchens',
                          value: widget.property.kitchens.toString(),
                        ),
                        if (widget.property.floors > 0)
                          _buildDetailRow(
                            icon: Icons.layers,
                            label: l10n?.floors ?? 'Floors',
                            value: widget.property.floors.toString(),
                          ),
                        if (widget.property.yearBuilt > 0)
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            label: l10n?.yearBuilt ?? 'Year Built',
                            value: widget.property.yearBuilt.toString(),
                          ),
                        _buildDetailRow(
                          icon: Icons.home_work,
                          label: l10n?.condition ?? 'Condition',
                          value: widget.property.condition.getLocalizedName(context),
                        ),
                        _buildDetailRow(
                          icon: Icons.square_foot,
                          label: l10n?.area ?? 'Area',
                          value: '${widget.property.sizeSqm} ${l10n?.sqmSuffix ?? "sqm"}',
                        ),
                        if (widget.property.status == PropertyStatus.forRent && widget.property.deposit > 0)
                          _buildDetailRow(
                            icon: Icons.security,
                            label: l10n?.securityDeposit ?? 'Security Deposit',
                            value: '${NumberFormat('#,###').format(widget.property.deposit)} LYD',
                        ),

                          ],
                        ),
                      ),

                      // Description Card
                            Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        padding: const EdgeInsets.all(20),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                          l10n?.description ?? 'Description',
                              style: ThemeService.getHeadingStyle(
                                context,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                          ),
                        ),
                            const SizedBox(height: 12),
                            Text(
                          widget.property.description,
                              style: ThemeService.getBodyStyle(
                                context,
                                fontSize: 15,
                                color: Colors.grey[700],
                              ).copyWith(height: 1.6),
                            ),
                          ],
                          ),
                        ),

                      // Features Card
                            Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        padding: const EdgeInsets.all(20),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                          l10n?.features ?? 'Features',
                              style: ThemeService.getHeadingStyle(
                                context,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                          ),
                        ),
                            const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (widget.property.hasParking)
                              _buildFeatureChip(l10n?.parking ?? 'Parking', Icons.car_rental),
                            if (widget.property.hasGarden)
                              _buildFeatureChip(l10n?.garden ?? 'Garden', Icons.grass),
                            if (widget.property.hasBalcony)
                              _buildFeatureChip(l10n?.balcony ?? 'Balcony', Icons.balcony),
                            if (widget.property.hasPool)
                              _buildFeatureChip(l10n?.pool ?? 'Pool', Icons.pool),
                            if (widget.property.hasSecurity)
                              _buildFeatureChip(l10n?.security ?? 'Security', Icons.security),
                            if (widget.property.hasPublicTransport)
                              _buildFeatureChip(l10n?.publicTransport ?? 'Public Transport', Icons.directions_bus),
                            if (widget.property.hasAC)
                              _buildFeatureChip(l10n?.airConditioning ?? 'Air Conditioning', Icons.ac_unit),
                            if (widget.property.hasHeating)
                              _buildFeatureChip(l10n?.heating ?? 'Heating', Icons.fireplace),
                            if (widget.property.hasGym)
                              _buildFeatureChip(l10n?.gym ?? 'Gym', Icons.fitness_center),
                            if (widget.property.hasElevator)
                              _buildFeatureChip(l10n?.elevator ?? 'Elevator', Icons.elevator),
                            if (widget.property.hasPetFriendly)
                              _buildFeatureChip(l10n?.petFriendly ?? 'Pet Friendly', Icons.pets),
                            if (widget.property.hasFurnished)
                              _buildFeatureChip(l10n?.furnished ?? 'Furnished', Icons.chair),
                            if (widget.property.hasWaterWell)
                              _buildFeatureChip(l10n?.waterWell ?? 'Water Well', Icons.water_drop),
                            if (widget.property.hasNearbySchools)
                              _buildFeatureChip(l10n?.nearbySchools ?? 'Nearby Schools', Icons.school),
                            if (widget.property.hasNearbyHospitals)
                              _buildFeatureChip(l10n?.nearbyHospitals ?? 'Nearby Hospitals', Icons.local_hospital),
                            if (widget.property.hasNearbyShopping)
                              _buildFeatureChip(l10n?.nearbyShopping ?? 'Nearby Shopping', Icons.shopping_cart),
                          ],
                        ),
                      ],
                    ),
                ),

                      // Seller Info Card
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF01352D).withValues(alpha: 0.1),
                            backgroundImage: _sellerProfile?.profileImageUrl != null
                                ? NetworkImage(_sellerProfile!.profileImageUrl!)
                                : null,
                            child: _sellerProfile?.profileImageUrl == null
                                ? const Icon(Icons.person, color: Color(0xFF01352D))
                                : null,
                          ),
                          title: Text(
                            _sellerProfile?.name ?? (widget.property.agentName.isNotEmpty
                                ? widget.property.agentName
                                : (l10n?.propertyOwner ?? 'Property Owner')),
                            style: ThemeService.getDynamicStyle(
                              context,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            l10n?.viewProfile ?? 'View profile',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                          onTap: () {
                            context.push('/user/${widget.property.userId}');
                          },
                        ),
                      ),

                      // Stats Row
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(Icons.visibility_outlined, '${widget.property.views}', l10n?.views ?? 'Views'),
                            Container(width: 1, height: 40, color: Colors.grey[200]),
                            _buildStatItem(Icons.calendar_today_outlined, 
                              '${widget.property.createdAt.day}/${widget.property.createdAt.month}/${widget.property.createdAt.year}', 
                              l10n?.listed ?? 'Listed'),
                          ],
                  ),
                ),

                      // Contact Button (for non-owners)
                if (currentUser != null && currentUser.id != widget.property.userId)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                        onPressed: _isCreatingConversation ? null : _contactSeller,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF01352D),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: _isCreatingConversation
                            ? const DaryLoadingIndicator(
                                size: 20,
                                strokeWidth: 2,
                                color: Colors.white,
                              )
                                  : Text(
                                      l10n?.messageSeller ?? 'Message Seller',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),

                      // Boost Button (for owners)
                if (currentUser != null && currentUser.id == widget.property.userId)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: SizedBox(
                            width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPremiumOptions(context),
                              icon: const Icon(Icons.rocket_launch, size: 20),
                                label: Text(
                                  widget.property.isBoosted && widget.property.isBoostActive 
                                      ? (l10n?.manageBoost ?? 'Manage Boost')
                                      : (l10n?.boostProperty ?? 'Boost Property'),
                                ),
                        style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[700],
                          foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                          ),
                                elevation: 0,
                        ),
                      ),
                    ),
                  ),

                      const SizedBox(height: 20),
                      
                      // Legal Disclaimer Card at bottom
                      _buildLegalDisclaimer(l10n),
                      
                      const SizedBox(height: 32),
                      ],
                    ),
                    ),
                    ],
                  ),
          ),
        ),
        if (_isFullScreen)
          _buildFullScreenImageViewer(),
      ],
    );
  }

  Widget _buildLegalDisclaimer(AppLocalizations? l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.gavel_rounded, color: Colors.amber[900], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n?.propertyLegalNoteAr ?? 'يرجى التحقق من جميع أوراق العقار. داري ليست مسؤولة عن أي خلافات أو مشاكل قانونية.',
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.propertyLegalNote ?? 'Please verify all property paperwork. Dary is not responsible for any legal discrepancies or issues.',
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryTimer(bool isOwner) {
    if (!isOwner) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    final now = DateTime.now();
    final expiryDate = widget.property.createdAt.add(const Duration(days: 60));
    final difference = expiryDate.difference(now);
    final daysLeft = difference.inDays;
    
    if (widget.property.isExpired || daysLeft <= 0) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    l10n?.listingExpired ?? 'Listing Expired',
                    style: ThemeService.getDynamicStyle(
                      context,
                      fontWeight: FontWeight.bold, 
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    l10n?.listingExpiredDesc ?? 'This property is no longer visible to the public.',
                    style: ThemeService.getDynamicStyle(context, fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                 final authProvider = Provider.of<AuthProvider>(context, listen: false);
                 final currentUser = authProvider.currentUser;
                 if (currentUser != null && !currentUser.canAddProperty) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const PaywallScreen(),
                    );
                    return;
                 }
                 
                 final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
                 final success = await propertyService.renewProperty(widget.property.id);
                 if (success) {
                   await authProvider.refreshUser();
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(l10n?.propertyRenewedSuccessfully ?? 'Property renewed successfully!'), backgroundColor: const Color(0xFF01352D)),
                     );
                     setState(() {}); // Refresh UI
                   }
                 }
              },
              child: Text(l10n?.renew ?? 'Renew', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF01352D).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF01352D).withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFF01352D), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.listingExpiry ?? 'Listing Expiry',
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF01352D),
                    fontSize: 14,
                  ),
                ),
                Text(
                  daysLeft == 0 
                      ? (l10n?.expiresToday ?? 'Expires today') 
                      : (l10n?.listingWillExpireIn('$daysLeft ${l10n.daysSuffix ?? "days"}') ?? 'Your listing will expire in $daysLeft days'),
                  style: ThemeService.getDynamicStyle(context, fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (daysLeft < 7)
            TextButton(
              onPressed: () async {
                 final authProvider = Provider.of<AuthProvider>(context, listen: false);
                 final currentUser = authProvider.currentUser;
                 if (currentUser != null && !currentUser.canAddProperty) {
                   showModalBottomSheet(
                     context: context,
                     isScrollControlled: true,
                     backgroundColor: Colors.transparent,
                     builder: (context) => const PaywallScreen(),
                   );
                   return;
                 }

                 final propertyService = Provider.of<property_service.PropertyService>(context, listen: false);
                 final success = await propertyService.renewProperty(widget.property.id);
                 if (success) {
                   await authProvider.refreshUser();
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(l10n?.propertyRenewedSuccessfully ?? 'Property renewed successfully!'), backgroundColor: const Color(0xFF01352D)),
                     );
                     setState(() {}); // Refresh UI
                   }
                 }
              },
              child: Text(l10n?.renewNow ?? 'Renew now', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // Location Section with heading, address, and map
  Widget _buildLocationSection() {
    final l10n = AppLocalizations.of(context);
    final neighborhoodQuery = '${widget.property.neighborhood}, ${widget.property.city}, Libya';
    final arabicQuery = _getArabicSearchQuery();
    final encodedQuery = Uri.encodeComponent(arabicQuery);
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
           Text(
            l10n?.location ?? 'Location',
            style: ThemeService.getHeadingStyle(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
         const SizedBox(height: 16),
         

        // Map preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: _buildLocationMap(neighborhoodQuery),
            ),
          ),
        
        const SizedBox(height: 12),
        
          // Open in Google Maps button
          InkWell(
            onTap: () async {
              final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedQuery');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.open_in_new, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  l10n?.openInGoogleMaps ?? 'Open in Google Maps',
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
          ),
        ),
      ],
      ),
    );
  }

  // Map widget
  Widget _buildLocationMap(String neighborhoodQuery) {
    final searchQuery = _getMapSearchQuery();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _buildMapContent(searchQuery),
    );
  }

  // Build the search query for the map (neighborhood, city, Libya) - English for OSM
  String _getMapSearchQuery() {
    final neighborhood = widget.property.neighborhood.trim().toLowerCase();
    final city = widget.property.city.trim();
    
    // Skip neighborhood if it's "other", empty, or generic
    final skipNeighborhood = neighborhood.isEmpty || 
        neighborhood == 'other' || 
        neighborhood == 'أخرى' ||
        neighborhood == 'اخرى' ||
        neighborhood == 'آخر' ||
        neighborhood == '-' ||
        neighborhood == 'n/a' ||
        neighborhood == 'na';
    
    if (!skipNeighborhood && city.isNotEmpty) {
      return '${widget.property.neighborhood.trim()}, $city, Libya';
    } else if (city.isNotEmpty) {
      return '$city, Libya';
    }
    return 'Tripoli, Libya';
  }
  
  // Build Arabic search query for Google Maps (more accurate for Libyan locations)
  String _getArabicSearchQuery() {
    final neighborhood = widget.property.neighborhood.trim().toLowerCase();
    final city = widget.property.city.trim().toLowerCase();
    
    // Map English city names to Arabic
    final arabicCities = {
      'tripoli': 'طرابلس',
      'benghazi': 'بنغازي',
      'misrata': 'مصراتة',
      'zawiya': 'الزاوية',
      'sabha': 'سبها',
      'sirte': 'سرت',
      'tobruk': 'طبرق',
      'zliten': 'زليتن',
      'khoms': 'الخمس',
      'derna': 'درنة',
      'gharyan': 'غريان',
      'sabratha': 'صبراتة',
      'ajdabiya': 'أجدابيا',
      'al bayda': 'البيضاء',
      'bani walid': 'بني وليد',
      'tarhuna': 'ترهونة',
      'yefren': 'يفرن',
      'nalut': 'نالوت',
      'ghat': 'غات',
      'ubari': 'أوباري',
      'murzuq': 'مرزق',
    };
    
    // Map English neighborhood names to Arabic
    final arabicNeighborhoods = {
      'janzour': 'جنزور',
      'ain zara': 'عين زارة',
      'tajoura': 'تاجوراء',
      'hay andalus': 'حي الأندلس',
      'andalus': 'الأندلس',
      'souq aljuma': 'سوق الجمعة',
      'abu salim': 'أبو سليم',
      'gargaresh': 'قرقارش',
      'ben ashour': 'بن عاشور',
      'fashloum': 'فشلوم',
      'dahmani': 'الدهماني',
      'salah aldin': 'صلاح الدين',
      'sarraj': 'السراج',
      'damascus': 'حي دمشق',
      'hadba': 'الهضبة',
      'gorji': 'قرجي',
      'fornaj': 'الفرناج',
      'old city': 'المدينة القديمة',
      'siyahiya': 'السياحية',
      'swani': 'السواني',
      'arada': 'العرادة',
      'hay alandalus': 'حي الأندلس',
      'zentata': 'زنتاتة',
      'sabri': 'الصابري',
      'fuwayhat': 'الفويهات',
      'salmani': 'السلماني',
      'benina': 'بنينا',
      'keesh': 'الكيش',
      'hawari': 'الهواري',
    };
    
    // Skip neighborhood if it's "other", empty, or generic
    final skipNeighborhood = neighborhood.isEmpty || 
        neighborhood == 'other' || 
        neighborhood == 'أخرى' ||
        neighborhood == 'اخرى' ||
        neighborhood == 'آخر' ||
        neighborhood == '-' ||
        neighborhood == 'n/a' ||
        neighborhood == 'na';
    
    // Get Arabic city name (pure Arabic, no English)
    String arabicCity = 'طرابلس'; // default
    // First check if city contains Arabic
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(widget.property.city)) {
      // Extract ONLY Arabic characters
      final arabicMatch = RegExp(r'[\u0600-\u06FF\s]+').allMatches(widget.property.city);
      if (arabicMatch.isNotEmpty) {
        arabicCity = arabicMatch.map((m) => m.group(0)).join(' ').trim();
      }
    }
    
    // If no Arabic found or empty, try to translate from English
    if (arabicCity.isEmpty || arabicCity == 'طرابلس') {
      for (final entry in arabicCities.entries) {
        if (city.contains(entry.key)) {
          arabicCity = entry.value;
          break;
        }
      }
    }
    
    // Get Arabic neighborhood name (pure Arabic, no English)
    String arabicNeighborhood = '';
    if (!skipNeighborhood) {
      // First check if neighborhood contains Arabic
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(widget.property.neighborhood)) {
        // Extract ONLY Arabic characters (remove everything else)
        final arabicMatch = RegExp(r'[\u0600-\u06FF\s]+').allMatches(widget.property.neighborhood);
        if (arabicMatch.isNotEmpty) {
          arabicNeighborhood = arabicMatch.map((m) => m.group(0)).join(' ').trim();
        }
      }
      
      // If no Arabic found, try to translate from English
      if (arabicNeighborhood.isEmpty) {
        for (final entry in arabicNeighborhoods.entries) {
          if (neighborhood.contains(entry.key)) {
            arabicNeighborhood = entry.value;
            break;
          }
        }
      }
    }
    
    // Build simple Arabic query: "الحي المدينة" (no commas, no "ليبيا")
    if (arabicNeighborhood.isNotEmpty) {
      return '$arabicNeighborhood $arabicCity';
    }
    return arabicCity;
  }

  // Build map content using search query
  Widget _buildMapContent(String searchQuery) {
    // Both web and mobile now use OpenStreetMap to resolve iframe and API key issues
    return _buildOpenStreetMapWithGeocoding(searchQuery);
  }
  
  // Cache for geocoding results
  static final Map<String, Map<String, double>> _geocodeCache = {};
  
  // Build OpenStreetMap with geocoding from search query
  Widget _buildOpenStreetMapWithGeocoding(String searchQuery) {
    return FutureBuilder<Map<String, double>>(
      future: _geocodeLocation(searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: DaryLoadingIndicator(
                color: Color(0xFF01352D),
              ),
            ),
          );
        }
        
        // Use geocoded coordinates or default to Tripoli
        final coords = snapshot.data ?? {'lat': 32.8872, 'lon': 13.1913};
        return _buildOpenStreetMapTiles(coords['lat']!, coords['lon']!);
      },
    );
  }
  
  // Geocode location using Nominatim API
  Future<Map<String, double>> _geocodeLocation(String searchQuery) async {
    // Check cache first
    if (_geocodeCache.containsKey(searchQuery)) {
      return _geocodeCache[searchQuery]!;
    }
    
    try {
      final encodedQuery = Uri.encodeComponent(searchQuery);
      final url = 'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&limit=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Dary Real Estate App'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final result = {
            'lat': double.parse(data[0]['lat']),
            'lon': double.parse(data[0]['lon']),
          };
          // Cache the result
          _geocodeCache[searchQuery] = result;
          return result;
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    
    // Default to Tripoli if geocoding fails
    return {'lat': 32.8872, 'lon': 13.1913};
  }
  
  // Build OpenStreetMap tiles with given coordinates
  Widget _buildOpenStreetMapTiles(double lat, double lon) {
    const zoom = 15; // Higher zoom for better neighborhood detail
    
    // Calculate tile coordinates
    final centerTileX = ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
    final latRad = lat * math.pi / 180.0;
    const n = 1 << zoom;
    final centerTileY = ((1.0 - (math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi)) / 2.0 * n).floor();
    
    // Calculate the pixel offset within the center tile for precise pin placement
    const tileSize = 256.0;
    final exactTileX = (lon + 180.0) / 360.0 * n;
    final exactTileY = (1.0 - (math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi)) / 2.0 * n;
    
    // Offset from center of center tile (in pixels, scaled to our grid)
    final offsetX = (exactTileX - centerTileX - 0.5) * tileSize / 3;
    final offsetY = (exactTileY - centerTileY - 0.5) * tileSize / 3;
    
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Map tiles - 3x3 grid
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.0,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final row = index ~/ 3 - 1;
              final col = index % 3 - 1;
              final tileX = centerTileX + col;
              final tileY = centerTileY + row;
              final url = 'https://tile.openstreetmap.org/$zoom/$tileX/$tileY.png';
              
              return Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[300]);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(color: Colors.grey[200]);
                },
              );
            },
          ),
          
          // Pin marker - positioned at the exact geocoded location
          Center(
            child: Transform.translate(
              offset: Offset(offsetX, offsetY - 24), // -24 to position pin tip at location
              child: Icon(
                Icons.location_on,
                color: Colors.red[700],
                size: 48,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
                    offset: const Offset(0, 4),
            ),
          ],
        ),
            ),
          ),
              
          // OpenStreetMap attribution
              Positioned(
            top: 8,
            left: 8,
                child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                      ),
                        child: Text(
                '© OpenStreetMap',
                          style: ThemeService.getDynamicStyle(
                            context,
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                  ),
                ),
              ),
            ],
      ),
    );
  }
  
  // Build Google Maps WebView for mobile platforms
  Widget _buildGoogleMapsWebView(String embedUrl) {
    // Create WebView controller
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF5F5F5))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('📍 Google Maps loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('✅ Google Maps loaded successfully');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));
    
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF01352D).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: WebViewWidget(controller: controller),
      ),
    );
  }
  
  // Styled map preview as fallback - looks like a real map
  Widget _buildStyledMapPreview() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[400]!,
            Colors.grey[350]!,
            Colors.green[100]!,
            Colors.grey[350]!,
            Colors.blue[100]!,
            Colors.grey[400]!,
          ],
          stops: const [0.0, 0.2, 0.35, 0.5, 0.7, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: MapPatternPainter(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 48,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.property.neighborhood,
                  style: ThemeService.getDynamicStyle(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Map pattern painter for styled map preview
class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    // Draw horizontal roads
    for (double y = 40; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    
    // Draw vertical roads
    for (double x = 40; x < size.width; x += 70) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}