import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/property.dart';
import '../../services/property_service.dart' as property_service;
import '../../screens/property_detail_screen.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/property_card.dart';

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
            final data = propertyDoc.data() as Map<String, dynamic>?;
            if (data != null) {
              final property = Property.fromFirestore(propertyDoc.id, data);
              properties.add(property);
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
          SnackBar(content: Text('Error loading favorites: $e')),
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
          const SnackBar(
            content: Text('Removed from favorites'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing favorite: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: CustomScrollView(
          slivers: [
            // Header section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'My Favorites (${_favorites.length})',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Properties list using PropertyCard (same as homepage)
            if (_favorites.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 100,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No favorites yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start adding properties to your favorites',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
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
                                    color: Colors.black.withOpacity(0.2),
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
            // Extra space for bottom navigation
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}