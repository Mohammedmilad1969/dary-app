import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/property.dart';
import '../../services/property_service.dart' as property_service;
import '../../providers/auth_provider.dart';
import '../../widgets/property_card.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dary_loading_indicator.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final property_service.PropertyService _propertyService = property_service.PropertyService();
  List<Property> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) {
        if (mounted) {
          setState(() {
            _favorites = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Get favorite property IDs from user's favorites subcollection
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      if (favoritesSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _favorites = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Extract property IDs from favorites
      final propertyIds = favoritesSnapshot.docs.map((doc) {
        final data = doc.data();
        return data['propertyId'] as String? ?? doc.id;
      }).where((id) => id.isNotEmpty).toList();

      if (propertyIds.isEmpty) {
        if (mounted) {
          setState(() {
            _favorites = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch properties from Firestore
      final properties = <Property>[];
      final firestore = FirebaseFirestore.instance;

      for (final propertyId in propertyIds) {
        try {
          final propertyDoc = await firestore
              .collection('properties')
              .doc(propertyId)
              .get();

          if (propertyDoc.exists) {
            final data = propertyDoc.data();
            if (data != null) {
              final property = Property.fromFirestore(propertyDoc.id, data);
              // Only add if property is published, not deleted, and not expired (matching home screen criteria)
              if (property.isPublished && !property.isDeleted && !property.isEffectivelyExpired) {
                properties.add(property);
              }
            }
          }
        } catch (e) {
          // Skip properties that don't exist or have errors
          if (mounted) {
            debugPrint('⚠️ Error loading favorite property $propertyId: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _favorites = properties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _favorites = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)?.errorLoadingFavorites ?? 'Error loading favorites'}: $e')),
        );
      }
    }
  }

  Future<void> _removeFavorite(String propertyId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;

      if (userId == null) return;

      // Remove from favorites in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(propertyId)
          .delete();

      // Reload favorites
      _loadFavorites();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.removedFromFavorites ?? 'Removed from favorites'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)?.errorRemovingFavorite ?? 'Error removing favorite'}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: DaryLoadingIndicator(color: Color(0xFF01352D)),
        ),
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
                                  Icons.favorite_rounded,
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
                                      AppLocalizations.of(context)?.myFavorites ?? 'My Favorites',
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AppLocalizations.of(context)?.propertiesSavedCount(_favorites.length) ?? '${_favorites.length} ${_favorites.length == 1 ? 'property' : 'properties'} saved',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                onPressed: _loadFavorites,
                                tooltip: 'Refresh',
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
          ),

          // Content
          if (_favorites.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF01352D).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border_rounded,
                        size: 64,
                        color: const Color(0xFF01352D).withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)?.noFavoritesYet ?? 'No favorites yet',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)?.startAddingToFavorites ?? 'Start adding properties to your favorites',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(top: 16, bottom: 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final property = _favorites[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Stack(
                        children: [
                          PropertyCard(
                            property: property,
                          ),
                          // Remove favorite button overlay
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.red),
                                onPressed: () => _removeFavorite(property.id),
                                tooltip: 'Remove from favorites',
                                iconSize: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _favorites.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}