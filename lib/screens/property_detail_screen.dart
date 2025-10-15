import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/language_service.dart';
import '../widgets/language_toggle_button.dart';
import '../providers/auth_provider.dart';
import '../models/property.dart';
import '../features/chat/chat_service.dart';
import '../features/chat/chat_screen.dart';
import '../features/chat/chat_models.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({
    super.key,
    required this.property,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final ChatService _chatService = ChatService();
  bool _isCreatingConversation = false;
  late PageController _pageController;
  late PageController _fullScreenPageController;
  Timer? _autoPlayTimer;
  int _currentImageIndex = 0;
  bool _isFullScreen = false;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fullScreenPageController = PageController();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullScreenPageController.dispose();
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    if (widget.property.imageUrls.length > 1) {
      _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (_pageController.hasClients) {
          setState(() {
            _currentImageIndex = (_currentImageIndex + 1) % widget.property.imageUrls.length;
          });
          _pageController.animateToPage(
            _currentImageIndex,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
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
    _fullScreenPageController.animateToPage(
      initialIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _closeFullScreen() {
    setState(() {
      _isFullScreen = false;
      _isZoomed = false;
    });
  }

  void _toggleZoom() {
    setState(() {
      _isZoomed = !_isZoomed;
    });
  }

  Future<void> _contactSeller() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.pleaseLoginFirst ?? 'Please login first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Don't allow users to contact themselves
    if (currentUser.email == widget.property.contactEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.cannotContactYourself ?? 'You cannot contact yourself'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingConversation = true;
    });

    try {
      // Check if conversation already exists
      final existingConversations = await _chatService.fetchConversations();
      final existingConversation = existingConversations.firstWhere(
        (conv) => conv.propertyId == widget.property.id && 
                  (conv.buyerId == currentUser.id || conv.sellerId == currentUser.id),
        orElse: () => Conversation(
          id: '',
          propertyId: '',
          propertyTitle: '',
          buyerId: '',
          buyerName: '',
          sellerId: '',
          sellerName: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existingConversation.id.isNotEmpty) {
        // Navigate to existing conversation
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: existingConversation.id,
              propertyTitle: widget.property.title,
              propertyImage: widget.property.imageUrls.isNotEmpty 
                  ? widget.property.imageUrls.first 
                  : null,
            ),
          ),
        );
      } else {
        // Create new conversation
        final newConversation = await _chatService.createConversation(
          propertyId: widget.property.id,
          buyerId: currentUser.id,
          sellerId: widget.property.contactEmail,
        );

        if (newConversation != null) {
          // Navigate to new conversation
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: newConversation.id,
                propertyTitle: widget.property.title,
                propertyImage: widget.property.imageUrls.isNotEmpty 
                    ? widget.property.imageUrls.first 
                    : null,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.errorCreatingConversation ?? 'Error creating conversation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.errorContactingSeller ?? 'Error contacting seller'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCreatingConversation = false;
      });
    }
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
          appBar: AppBar(
            title: Text(l10n?.propertyDetails ?? 'Property Details'),
            centerTitle: true,
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            actions: [
              LanguageToggleButton(languageService: languageService),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Images Slider
                Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.grey[300],
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
                                           // Tap to expand indicator
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
                            // Image indicators
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
                            // Navigation arrows
                            if (widget.property.imageUrls.length > 1) ...[
                              // Previous arrow
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
                              // Next arrow
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
                              // Auto-play pause/play button
                              Positioned(
                                top: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () {
                                    if (_autoPlayTimer?.isActive == true) {
                                      _stopAutoPlay();
                                    } else {
                                      _startAutoPlay();
                                    }
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _autoPlayTimer?.isActive == true
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 20,
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

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.property.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(widget.property.status),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              widget.property.status.statusDisplayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Type and Featured badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.property.type.typeDisplayName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.indigo[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (widget.property.isFeatured) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'FEATURED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.rocket_launch, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'BOOSTED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
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

                      // Price
                      Text(
                        widget.property.displayPrice,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[700],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Location
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${widget.property.city}, ${widget.property.neighborhood}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Property Details
                      Text(
                        l10n?.propertyDetails ?? 'Property Details',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                        icon: Icons.square_foot,
                        label: 'Area',
                        value: '${widget.property.sizeSqm} sqm',
                      ),
                      _buildDetailRow(
                        icon: Icons.calendar_today,
                        label: 'Year Built',
                        value: widget.property.yearBuilt.toString(),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        l10n?.description ?? 'Description',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.property.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Features
                      Text(
                        l10n?.features ?? 'Features',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
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
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Contact Seller Button
                      if (currentUser != null && currentUser.id != widget.property.userId)
                        Center(
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
                              textStyle: const TextStyle(fontSize: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Additional Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.property.views} ${l10n?.views ?? 'views'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            l10n?.listedOn ?? 'Listed on ${widget.property.createdAt.day}/${widget.property.createdAt.month}/${widget.property.createdAt.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
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
        // Full-screen image viewer
        if (_isFullScreen)
          _buildFullScreenImageViewer(),
      ],
    );
  }

  Widget _buildFullScreenImageViewer() {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
           // Full-screen PageView
           PageView.builder(
             controller: _fullScreenPageController,
             onPageChanged: _onPageChanged,
             itemCount: widget.property.imageUrls.length,
            itemBuilder: (context, index) {
               return GestureDetector(
                 onTap: _closeFullScreen,
                 onDoubleTap: _toggleZoom,
                 onHorizontalDragEnd: (details) {
                   // Handle horizontal swipe gestures
                   if (details.primaryVelocity != null) {
                     if (details.primaryVelocity! > 0) {
                       // Swipe right - go to previous image
                       if (_currentImageIndex > 0) {
                         _fullScreenPageController.previousPage(
                           duration: const Duration(milliseconds: 300),
                           curve: Curves.easeInOut,
                         );
                       }
                     } else {
                       // Swipe left - go to next image
                       if (_currentImageIndex < widget.property.imageUrls.length - 1) {
                         _fullScreenPageController.nextPage(
                           duration: const Duration(milliseconds: 300),
                           curve: Curves.easeInOut,
                         );
                       }
                     }
                   }
                 },
                 child: Container(
                   width: double.infinity,
                   height: double.infinity,
                   child: Image.network(
                     widget.property.imageUrls[index],
                     fit: _isZoomed ? BoxFit.contain : BoxFit.cover,
                     width: double.infinity,
                     height: double.infinity,
                     errorBuilder: (context, error, stackTrace) {
                       return Container(
                         width: double.infinity,
                         height: double.infinity,
                         color: Colors.grey[800],
                         child: const Icon(
                           Icons.image,
                           size: 100,
                           color: Colors.grey,
                         ),
                       );
                     },
                   ),
                 ),
              );
            },
          ),
          // Close button
          Positioned(
            top: 50,
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
           // Image counter
           Positioned(
             top: 50,
             left: 20,
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               decoration: BoxDecoration(
                 color: Colors.black.withOpacity(0.5),
                 borderRadius: BorderRadius.circular(20),
               ),
               child: Text(
                 '${_currentImageIndex + 1} / ${widget.property.imageUrls.length}',
                 style: const TextStyle(
                   color: Colors.white,
                   fontSize: 16,
                   fontWeight: FontWeight.w500,
                 ),
               ),
             ),
           ),
           // Zoom indicator
           Positioned(
             top: 50,
             left: 0,
             right: 0,
             child: Center(
               child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 decoration: BoxDecoration(
                   color: Colors.black.withOpacity(0.5),
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Text(
                   _isZoomed ? 'Zoomed - Double tap to fit' : 'Double tap to zoom',
                   style: const TextStyle(
                     color: Colors.white,
                     fontSize: 14,
                     fontWeight: FontWeight.w500,
                   ),
                 ),
               ),
             ),
           ),
          // Navigation arrows for full-screen
          if (widget.property.imageUrls.length > 1) ...[
            // Previous arrow
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
                      color: Colors.black.withOpacity(0.7),
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
            // Next arrow
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
                      color: Colors.black.withOpacity(0.7),
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
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo[700], size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, color: Colors.indigo[700], size: 18),
      label: Text(label),
      backgroundColor: Colors.indigo.withOpacity(0.1),
      labelStyle: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.indigo.withOpacity(0.3)),
      ),
    );
  }
}