import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to manage Firebase Auth users manually
/// Since Firebase Auth has web compatibility issues, we'll use this to
/// track which users need to be created in Firebase Console
class FirebaseAuthHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get list of users that need to be created in Firebase Auth
  static Future<List<Map<String, dynamic>>> getUsersForFirebaseAuth() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        users.add({
          'id': doc.id,
          'email': data['email'],
          'name': data['name'],
          'phone': data['phone'],
          'createdAt': data['createdAt'],
          'isVerified': data['isVerified'] ?? false,
          'isAdmin': data['isAdmin'] ?? false,
        });
      }
      
      if (kDebugMode) {
        debugPrint('📋 Found ${users.length} users in Firestore');
      }
      
      return users;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting users: $e');
      }
      return [];
    }
  }

  /// Print user information for manual Firebase Auth creation
  static Future<void> printUsersForFirebaseAuth() async {
    try {
      final users = await getUsersForFirebaseAuth();
      
      if (kDebugMode) {
        debugPrint('\n🔥 FIREBASE AUTH USERS TO CREATE:');
        debugPrint('=' * 50);
        
        for (int i = 0; i < users.length; i++) {
          final user = users[i];
          debugPrint('${i + 1}. Email: ${user['email']}');
          debugPrint('   Name: ${user['name']}');
          debugPrint('   Phone: ${user['phone']}');
          debugPrint('   Verified: ${user['isVerified']}');
          debugPrint('   Admin: ${user['isAdmin']}');
          debugPrint('   Created: ${user['createdAt']}');
          debugPrint('   ---');
        }
        
        debugPrint('\n📝 INSTRUCTIONS:');
        debugPrint('1. Go to Firebase Console → Authentication → Users');
        debugPrint('2. Click "Add user" for each user above');
        debugPrint('3. Use the email and create a password');
        debugPrint('4. Users will then appear in Firebase Auth');
        debugPrint('=' * 50);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error printing users: $e');
      }
    }
  }

  /// Mark a user as created in Firebase Auth
  static Future<void> markUserAsFirebaseAuthCreated(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'firebaseAuthCreated': true,
        'firebaseAuthCreatedAt': Timestamp.now(),
      });
      
      if (kDebugMode) {
        debugPrint('✅ User $userId marked as Firebase Auth created');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error marking user: $e');
      }
    }
  }

  /// Get users that haven't been created in Firebase Auth yet
  static Future<List<Map<String, dynamic>>> getUsersNotInFirebaseAuth() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('firebaseAuthCreated', isNull: true)
          .get();
      
      final users = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        users.add({
          'id': doc.id,
          'email': data['email'],
          'name': data['name'],
          'phone': data['phone'],
          'createdAt': data['createdAt'],
          'isVerified': data['isVerified'] ?? false,
          'isAdmin': data['isAdmin'] ?? false,
        });
      }
      
      if (kDebugMode) {
        debugPrint('📋 Found ${users.length} users not in Firebase Auth');
      }
      
      return users;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting users not in Firebase Auth: $e');
      }
      return [];
    }
  }
}
