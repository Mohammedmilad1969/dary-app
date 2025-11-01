import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../services/language_service.dart';
import '../widgets/language_toggle_button.dart';
import '../providers/auth_provider.dart';
import '../models/property.dart';
import '../features/chat/chat_service.dart';
import '../features/chat/chat_screen.dart';
import '../features/paywall/paywall_screens.dart';
import '../services/property_service.dart' as property_service;
import '../services/auth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fullScreenPageController = PageController();
    _trackView();
    _checkFavorite();
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

    if (currentUser == null) {
      _showLoginPrompt();
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
            const SnackBar(
              content: Text('Failed to create conversation. Please try again.'),
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
            content: Text('Failed to start conversation: $e'),
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

  void _showLoginPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Login Required',
          style: GoogleFonts.dmSerifDisplay(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Please log in to contact the seller.',
          style: GoogleFonts.dmSerifDisplay(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSerifDisplay(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Login',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareProperty() async {
    // Create the property link using the app's web URL
    const appUrl = 'https://mohammedmilad1969.github.io/dary-app';
    final propertyUrl = '$appUrl/property/${widget.property.id}';
    
    final text = 'Check out this property: ${widget.property.title} in ${widget.property.city}!\n'
        'Price: ${widget.property.status == PropertyStatus.forRent ? "LYD ${widget.property.monthlyRent}/month" : "LYD ${widget.property.price}"}\n'
        '${widget.property.description}\n\n'
        'View more details: $propertyUrl';
    
    try {
      await Share.share(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final phoneNumber = widget.property.contactPhone;
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
      );
      return;
    }
    
    final cleanedPhone = phoneNumber.replaceAll(' ', '').replaceAll('-', '').replaceAll('(', '').replaceAll(')', '');
    
    final message = 'Hello! I am interested in this property:\n'
        '${widget.property.title}\n'
        'Location: ${widget.property.address.isNotEmpty ? "${widget.property.address}, " : ""}${widget.property.city}, ${widget.property.neighborhood}\n'
        'Price: ${widget.property.status == PropertyStatus.forRent ? "LYD ${widget.property.monthlyRent}/month" : "LYD ${widget.property.price}"}\n'
        'Type: ${widget.property.type.typeDisplayName}';
    
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
            const SnackBar(content: Text('Cannot open WhatsApp')),
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
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        _showLoginPrompt();
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
      } else {
        // Add to favorites
        await favoritesRef.set({
          'propertyId': propertyId,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
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
    final phoneNumber = widget.property.contactPhone;
    
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available')),
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
            const SnackBar(content: Text('Cannot make phone call from this device')),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.dmSerifDisplay(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Boost Property',
          style: GoogleFonts.dmSerifDisplay(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Choose a premium package to boost your property visibility.',
          style: GoogleFonts.dmSerifDisplay(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSerifDisplay(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PaywallScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
            ),
            child: Text(
              'View Packages',
              style: GoogleFonts.dmSerifDisplay(
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
        return Colors.green;
      case PropertyStatus.forRent:
        return Colors.blue;
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.dmSerifDisplay(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.dmSerifDisplay(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
        gradient: LinearGradient(
          colors: [
            Colors.green.withOpacity(0.2),
            Colors.green.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSerifDisplay(
              color: Colors.green[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenImageViewer() {
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
                  color: Colors.black.withOpacity(0.5),
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
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1} / ${widget.property.imageUrls.length}',
                style: GoogleFonts.dmSerifDisplay(
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
                      color: Colors.black.withOpacity(0.5),
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
                      color: Colors.black.withOpacity(0.5),
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              l10n?.propertyDetails ?? 'Property Details',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.green,
            elevation: 2,
            foregroundColor: Colors.white,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green,
                    Colors.green[700]!,
                    Colors.green[800]!,
                  ],
                ),
              ),
            ),
            actions: [
              LanguageToggleButton(languageService: languageService),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: widget.property.imageUrls.isNotEmpty
                      ? Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              onPageChanged: _onPageChanged,
                              itemCount: widget.property.imageUrls.length,
                              padEnds: false,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => _openFullScreen(index),
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            widget.property.imageUrls[index],
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
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
                                          Positioned(
                                            top: 16,
                                            left: 16,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.zoom_in,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (widget.property.imageUrls.length > 1)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    widget.property.imageUrls.length,
                                    (index) => Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentImageIndex == index
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.property.imageUrls.length > 1) ...[
                              Positioned(
                                left: 16,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_currentImageIndex > 0) {
                                        _pageController.previousPage(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.chevron_left,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 16,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_currentImageIndex < widget.property.imageUrls.length - 1) {
                                        _pageController.nextPage(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.chevron_right,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.home,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                ),

                // Action Buttons Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.phone,
                          label: 'Call',
                          color: Colors.blue,
                          onPressed: () {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            if (authProvider.currentUser == null) {
                              _showLoginPrompt();
                              return;
                            }
                            _makePhoneCall();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.chat,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onPressed: () {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            if (authProvider.currentUser == null) {
                              _showLoginPrompt();
                              return;
                            }
                            _openWhatsApp();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.share,
                          label: 'Share',
                          color: Colors.purple,
                          onPressed: _shareProperty,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                          label: 'Save',
                          color: _isFavorite ? Colors.red : Colors.grey,
                          onPressed: () {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            if (authProvider.currentUser == null) {
                              _showLoginPrompt();
                              return;
                            }
                            _toggleFavorite();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.property.title,
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getStatusColor(widget.property.status),
                                    _getStatusColor(widget.property.status).withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getStatusColor(widget.property.status).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.property.status.statusDisplayName,
                                style: GoogleFonts.dmSerifDisplay(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.2),
                                    Colors.green.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.property.type.typeDisplayName,
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 12,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (widget.property.isFeatured) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.amber,
                                      Colors.orange,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'FEATURED',
                                      style: GoogleFonts.dmSerifDisplay(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (widget.property.isBoosted && widget.property.isBoostActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.purple,
                                      Colors.deepPurple,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.rocket_launch, color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'BOOSTED',
                                      style: GoogleFonts.dmSerifDisplay(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.1),
                                Colors.green.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.attach_money,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.property.displayPrice,
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.withOpacity(0.1),
                                Colors.green.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.green,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (widget.property.address.isNotEmpty)
                                      Text(
                                        widget.property.address,
                                        style: GoogleFonts.dmSerifDisplay(
                                          fontSize: 18,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    if (widget.property.address.isNotEmpty)
                                      const SizedBox(height: 4),
                                    Text(
                                      '${widget.property.city}, ${widget.property.neighborhood}',
                                      style: GoogleFonts.dmSerifDisplay(
                                        fontSize: widget.property.address.isNotEmpty ? 16 : 18,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          l10n?.propertyDetails ?? 'Property Details',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                          label: 'Kitchens',
                          value: widget.property.kitchens.toString(),
                        ),
                        if (widget.property.floors > 0)
                          _buildDetailRow(
                            icon: Icons.layers,
                            label: 'Floors',
                            value: widget.property.floors.toString(),
                          ),
                        if (widget.property.yearBuilt > 0)
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            label: 'Year Built',
                            value: widget.property.yearBuilt.toString(),
                          ),
                        _buildDetailRow(
                          icon: Icons.home_work,
                          label: 'Condition',
                          value: widget.property.condition.conditionDisplayName,
                        ),
                        _buildDetailRow(
                          icon: Icons.square_foot,
                          label: 'Area',
                          value: '${widget.property.sizeSqm} sqm',
                        ),
                        if (widget.property.status == PropertyStatus.forRent && widget.property.deposit > 0)
                          _buildDetailRow(
                            icon: Icons.security,
                            label: 'Security Deposit',
                            value: '${widget.property.deposit.toStringAsFixed(0)} LYD',
                        ),

                        const SizedBox(height: 16),

                        Text(
                          l10n?.description ?? 'Description',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.property.description,
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          l10n?.features ?? 'Features',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (widget.property.hasParking)
                              _buildFeatureChip('Parking', Icons.car_rental),
                            if (widget.property.hasGarden)
                              _buildFeatureChip('Garden', Icons.grass),
                            if (widget.property.hasBalcony)
                              _buildFeatureChip('Balcony', Icons.balcony),
                            if (widget.property.hasPool)
                              _buildFeatureChip('Pool', Icons.pool),
                            if (widget.property.hasSecurity)
                              _buildFeatureChip('Security', Icons.security),
                            if (widget.property.hasPublicTransport)
                              _buildFeatureChip('Public Transport', Icons.directions_bus),
                            if (widget.property.hasAC)
                              _buildFeatureChip('Air Conditioning', Icons.ac_unit),
                            if (widget.property.hasHeating)
                              _buildFeatureChip('Heating', Icons.fireplace),
                            if (widget.property.hasGym)
                              _buildFeatureChip('Gym', Icons.fitness_center),
                            if (widget.property.hasElevator)
                              _buildFeatureChip('Elevator', Icons.elevator),
                            if (widget.property.hasPetFriendly)
                              _buildFeatureChip('Pet Friendly', Icons.pets),
                            if (widget.property.hasFurnished)
                              _buildFeatureChip('Furnished', Icons.chair),
                            if (widget.property.hasNearbySchools)
                              _buildFeatureChip('Nearby Schools', Icons.school),
                            if (widget.property.hasNearbyHospitals)
                              _buildFeatureChip('Nearby Hospitals', Icons.local_hospital),
                            if (widget.property.hasNearbyShopping)
                              _buildFeatureChip('Nearby Shopping', Icons.shopping_cart),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (currentUser != null && currentUser.id != widget.property.userId)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: _isCreatingConversation ? null : _contactSeller,
                        icon: _isCreatingConversation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.message),
                        label: Text(l10n?.contactSeller ?? 'Contact Seller'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          textStyle: GoogleFonts.dmSerifDisplay(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (currentUser != null && currentUser.id == widget.property.userId)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _showPremiumOptions(context),
                        icon: const Icon(Icons.rocket_launch),
                        label: Text(widget.property.isBoosted && widget.property.isBoostActive 
                            ? 'Manage Premium' 
                            : 'Boost Property'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.property.isBoosted && widget.property.isBoostActive 
                              ? Colors.purple 
                              : Colors.amber[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          textStyle: GoogleFonts.dmSerifDisplay(fontSize: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.withOpacity(0.1),
                        Colors.grey.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.visibility, size: 16, color: Colors.green),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.property.views} ${l10n?.views ?? 'views'}',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 14,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.calendar_today, size: 16, color: Colors.green),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n?.listedOn ?? 'Listed on ${widget.property.createdAt.day}/${widget.property.createdAt.month}/${widget.property.createdAt.year}',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 14,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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
}