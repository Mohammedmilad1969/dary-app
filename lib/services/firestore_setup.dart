import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_structure.dart';

/// Firestore Setup Script
/// 
/// This script initializes the Firestore database with default data
/// Run this once when setting up your Firebase project
class FirestoreSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize all collections with default data
  static Future<void> initializeFirestore() async {
    try {
      print('🚀 Starting Firestore initialization...');

      // Initialize default packages
      await FirestoreStructure.initializeDefaultPackages();
      
      // Create sample users (optional - for testing)
      await _createSampleUsers();
      
      // Create sample properties (optional - for testing)
      await _createSampleProperties();
      
      print('✅ Firestore initialization completed successfully!');
    } catch (e) {
      print('❌ Error during Firestore initialization: $e');
      rethrow;
    }
  }

  /// Create sample users for testing
  static Future<void> _createSampleUsers() async {
    try {
      // Sample user 1
      await FirestoreStructure.createUserDocument(
        uid: 'sample_user_1',
        name: 'John Doe',
        email: 'john.doe@example.com',
        phone: '+1234567890',
        isVerified: true,
      );

      // Sample user 2
      await FirestoreStructure.createUserDocument(
        uid: 'sample_user_2',
        name: 'Jane Smith',
        email: 'jane.smith@example.com',
        phone: '+1987654321',
        isVerified: true,
      );

      // Admin user
      await FirestoreStructure.createUserDocument(
        uid: 'admin_user',
        name: 'Admin User',
        email: 'admin@dary.com',
        phone: '+9999999999',
        isVerified: true,
        isAdmin: true,
      );

      // Create wallets for sample users
      await FirestoreStructure.createWalletDocument(
        uid: 'sample_user_1',
        initialBalance: 200.0,
      );

      await FirestoreStructure.createWalletDocument(
        uid: 'sample_user_2',
        initialBalance: 150.0,
      );

      await FirestoreStructure.createWalletDocument(
        uid: 'admin_user',
        initialBalance: 1000.0,
      );

      print('✅ Sample users created');
    } catch (e) {
      print('❌ Error creating sample users: $e');
    }
  }

  /// Create sample properties for testing
  static Future<void> _createSampleProperties() async {
    try {
      // Sample property 1
      await FirestoreStructure.createPropertyDocument(
        propertyId: 'property_1',
        userId: 'sample_user_1',
        title: 'Modern Apartment in Downtown',
        description: 'Beautiful modern apartment with stunning city views',
        price: 250000.0,
        monthlyRent: 1200.0,
        sizeSqm: 120,
        city: 'Tripoli',
        neighborhood: 'Downtown',
        address: '123 Main Street, Tripoli',
        bedrooms: 3,
        bathrooms: 2,
        floors: 5,
        yearBuilt: 2020,
        type: 'apartment',
        status: 'for_sale',
        condition: 'excellent',
        contactPhone: '+1234567890',
        contactEmail: 'john.doe@example.com',
        agentName: 'John Doe',
        imageUrls: [
          'https://via.placeholder.com/400x300/4F46E5/FFFFFF?text=Apartment+1',
          'https://via.placeholder.com/400x300/059669/FFFFFF?text=Living+Room',
          'https://via.placeholder.com/400x300/DC2626/FFFFFF?text=Kitchen',
        ],
        features: {
          'hasBalcony': true,
          'hasParking': true,
          'hasAC': true,
          'hasElevator': true,
        },
        isVerified: true,
      );

      // Sample property 2
      await FirestoreStructure.createPropertyDocument(
        propertyId: 'property_2',
        userId: 'sample_user_2',
        title: 'Luxury Villa with Garden',
        description: 'Spacious villa with beautiful garden and pool',
        price: 500000.0,
        monthlyRent: 2500.0,
        sizeSqm: 300,
        city: 'Benghazi',
        neighborhood: 'Al-Sabri',
        address: '456 Garden Avenue, Benghazi',
        bedrooms: 5,
        bathrooms: 4,
        floors: 2,
        yearBuilt: 2018,
        type: 'villa',
        status: 'for_rent',
        condition: 'excellent',
        contactPhone: '+1987654321',
        contactEmail: 'jane.smith@example.com',
        agentName: 'Jane Smith',
        imageUrls: [
          'https://via.placeholder.com/400x300/7C3AED/FFFFFF?text=Villa+1',
          'https://via.placeholder.com/400x300/EA580C/FFFFFF?text=Garden',
          'https://via.placeholder.com/400x300/0891B2/FFFFFF?text=Pool',
        ],
        features: {
          'hasGarden': true,
          'hasPool': true,
          'hasParking': true,
          'hasSecurity': true,
          'hasAC': true,
        },
        isVerified: true,
        isBoosted: true,
        boostPackageName: 'Top Listing - 1 Week',
        boostExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      // Sample property 3
      await FirestoreStructure.createPropertyDocument(
        propertyId: 'property_3',
        userId: 'sample_user_1',
        title: 'Commercial Office Space',
        description: 'Prime commercial office space in business district',
        price: 750000.0,
        sizeSqm: 500,
        city: 'Misrata',
        neighborhood: 'Business District',
        address: '789 Business Boulevard, Misrata',
        bedrooms: 0,
        bathrooms: 3,
        floors: 1,
        yearBuilt: 2015,
        type: 'commercial',
        status: 'for_sale',
        condition: 'good',
        contactPhone: '+1234567890',
        contactEmail: 'john.doe@example.com',
        agentName: 'John Doe',
        imageUrls: [
          'https://via.placeholder.com/400x300/059669/FFFFFF?text=Office+1',
          'https://via.placeholder.com/400x300/DC2626/FFFFFF?text=Reception',
          'https://via.placeholder.com/400x300/7C3AED/FFFFFF?text=Conference',
        ],
        features: {
          'hasParking': true,
          'hasAC': true,
          'hasSecurity': true,
          'hasElevator': true,
        },
        isVerified: false,
      );

      // Sample property 4 - "new villa" (boosted)
      await FirestoreStructure.createPropertyDocument(
        propertyId: 'property_4',
        userId: 'sample_user_1',
        title: 'new villa',
        description: 'Brand new modern villa with contemporary design and premium amenities.',
        price: 600000.0,
        sizeSqm: 350,
        city: 'Tripoli',
        neighborhood: 'Al-Andalus',
        address: '123 New Villa Street, Tripoli',
        bedrooms: 4,
        bathrooms: 3,
        floors: 2,
        yearBuilt: 2024,
        type: 'villa',
        status: 'for_sale',
        condition: 'excellent',
        contactPhone: '+218-21-555-0100',
        contactEmail: 'newvilla@dary.com',
        agentName: 'New Villa Properties',
        imageUrls: [
          'https://via.placeholder.com/400x300/10B981/FFFFFF?text=New+Villa',
          'https://via.placeholder.com/400x300/059669/FFFFFF?text=Modern+Design',
          'https://via.placeholder.com/400x300/DC2626/FFFFFF?text=Premium+Amenities',
        ],
        features: {
          'hasBalcony': true,
          'hasGarden': true,
          'hasParking': true,
          'hasPool': true,
          'hasGym': false,
          'hasSecurity': true,
          'hasElevator': false,
          'hasAC': true,
          'hasHeating': true,
          'hasFurnished': false,
          'hasPetFriendly': true,
          'hasNearbySchools': true,
          'hasNearbyHospitals': true,
          'hasNearbyShopping': true,
          'hasPublicTransport': true,
        },
        isVerified: true,
        isBoosted: true,
        boostPackageName: 'Premium Boost - 1 Week',
        boostExpiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      print('✅ Sample properties created');
    } catch (e) {
      print('❌ Error creating sample properties: $e');
    }
  }

  /// Add sample transactions to wallets
  static Future<void> addSampleTransactions() async {
    try {
      // Add transactions for sample_user_1
      await FirestoreStructure.addWalletTransaction(
        uid: 'sample_user_1',
        type: 'deposit',
        amount: 200.0,
        description: 'Initial wallet deposit',
      );

      await FirestoreStructure.addWalletTransaction(
        uid: 'sample_user_1',
        type: 'purchase',
        amount: -20.0,
        description: 'Top Listing - 1 Day purchase',
        referenceId: 'property_1',
        metadata: {'packageId': 'top_listing_1day'},
      );

      // Add transactions for sample_user_2
      await FirestoreStructure.addWalletTransaction(
        uid: 'sample_user_2',
        type: 'deposit',
        amount: 150.0,
        description: 'Initial wallet deposit',
      );

      await FirestoreStructure.addWalletTransaction(
        uid: 'sample_user_2',
        type: 'purchase',
        amount: -100.0,
        description: 'Top Listing - 1 Week purchase',
        referenceId: 'property_2',
        metadata: {'packageId': 'top_listing_1week'},
      );

      print('✅ Sample transactions added');
    } catch (e) {
      print('❌ Error adding sample transactions: $e');
    }
  }

  /// Create sample saved searches
  static Future<void> createSampleSavedSearches() async {
    try {
      // Saved search 1
      await FirestoreStructure.createSavedSearchDocument(
        searchId: 'search_1',
        userId: 'sample_user_1',
        name: 'Apartments in Tripoli',
        description: 'Looking for apartments in Tripoli downtown area',
        filters: {
          'type': 'apartment',
          'city': 'Tripoli',
          'neighborhood': 'Downtown',
          'minPrice': 200000.0,
          'maxPrice': 300000.0,
          'minBedrooms': 2,
          'maxBedrooms': 4,
          'features': ['hasBalcony', 'hasParking', 'hasAC'],
        },
      );

      // Saved search 2
      await FirestoreStructure.createSavedSearchDocument(
        searchId: 'search_2',
        userId: 'sample_user_2',
        name: 'Villas with Pool',
        description: 'Luxury villas with swimming pool',
        filters: {
          'type': 'villa',
          'features': ['hasPool', 'hasGarden', 'hasSecurity'],
          'minPrice': 400000.0,
          'maxPrice': 600000.0,
          'condition': 'excellent',
        },
      );

      print('✅ Sample saved searches created');
    } catch (e) {
      print('❌ Error creating sample saved searches: $e');
    }
  }

  /// Complete setup with all sample data
  static Future<void> completeSetup() async {
    try {
      print('🚀 Starting complete Firestore setup...');

      await initializeFirestore();
      await addSampleTransactions();
      await createSampleSavedSearches();

      print('✅ Complete Firestore setup finished!');
      print('📊 Collections created:');
      print('   - users (with sample users)');
      print('   - properties (with sample properties)');
      print('   - wallet (with sample wallets and transactions)');
      print('   - saved_searches (with sample searches)');
      print('   - packages (with default packages)');
    } catch (e) {
      print('❌ Error during complete setup: $e');
      rethrow;
    }
  }

  /// Clear all collections (use with caution!)
  static Future<void> clearAllCollections() async {
    try {
      print('⚠️ Clearing all Firestore collections...');

      final collections = [
        'users',
        'properties',
        'wallet',
        'saved_searches',
        'packages',
      ];

      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        final batch = _firestore.batch();
        
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        print('✅ Cleared collection: $collection');
      }

      print('✅ All collections cleared');
    } catch (e) {
      print('❌ Error clearing collections: $e');
      rethrow;
    }
  }
}
