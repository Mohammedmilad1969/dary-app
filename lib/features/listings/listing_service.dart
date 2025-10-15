import 'package:flutter/material.dart';

class Listing {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final DateTime createdAt;
  final String category;

  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.createdAt,
    required this.category,
  });
}

class ListingService {
  static final List<Listing> _listings = [
    Listing(
      id: '1',
      title: 'Sample Listing',
      description: 'This is a sample listing description',
      price: 99.99,
      imageUrl: '',
      createdAt: DateTime(2024, 3, 15),
      category: 'General',
    ),
  ];

  static List<Listing> get listings => _listings;

  static Future<List<Listing>> fetchListings() async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 1));
    return _listings;
  }

  static Future<Listing?> createListing(Listing listing) async {
    // TODO: Implement actual creation logic
    await Future.delayed(const Duration(seconds: 1));
    return listing;
  }
}
