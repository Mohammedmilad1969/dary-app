# Firestore Database Structure & Setup Guide

This document provides a complete guide for setting up your Firebase Firestore database with the proper collection structure for the Dary Properties app.

## 📁 Collections Overview

### 1. **users/{uid}**
Stores user profile information and preferences.

**Fields:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "profileImageUrl": "https://...",
  "totalListings": 5,
  "activeListings": 3,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z",
  "isVerified": false,
  "isAdmin": false,
  "lastLoginAt": "2024-01-15T10:30:00Z",
  "preferences": {
    "notifications": true,
    "emailUpdates": true,
    "language": "en",
    "theme": "light"
  },
  "stats": {
    "propertiesViewed": 0,
    "searchesPerformed": 0,
    "favoritesCount": 0
  }
}
```

### 2. **properties/{propertyId}**
Stores property listings with all details.

**Fields:**
```json
{
  "userId": "user_123",
  "title": "Modern Apartment",
  "description": "Beautiful apartment...",
  "price": 250000.0,
  "monthlyRent": 1200.0,
  "sizeSqm": 120,
  "city": "Tripoli",
  "neighborhood": "Downtown",
  "address": "123 Main Street",
  "bedrooms": 3,
  "bathrooms": 2,
  "floors": 5,
  "yearBuilt": 2020,
  "type": "apartment",
  "status": "for_sale",
  "condition": "excellent",
  "deposit": 5000.0,
  "contactPhone": "+1234567890",
  "contactEmail": "john@example.com",
  "agentName": "John Doe",
  "imageUrls": ["https://..."],
  "features": {
    "hasBalcony": true,
    "hasGarden": false,
    "hasParking": true,
    "hasPool": false,
    "hasGym": false,
    "hasSecurity": true,
    "hasElevator": true,
    "hasAC": true,
    "hasHeating": false,
    "hasFurnished": false,
    "hasPetFriendly": true,
    "hasNearbySchools": true,
    "hasNearbyHospitals": true,
    "hasNearbyShopping": true,
    "hasPublicTransport": true
  },
  "views": 0,
  "isFeatured": false,
  "isVerified": false,
  "isBoosted": false,
  "boostPackageName": "Top Listing - 1 Week",
  "boostExpiresAt": "2024-01-22T10:30:00Z",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z",
  "publishedAt": "2024-01-15T10:30:00Z",
  "expiresAt": "2024-02-15T10:30:00Z",
  "location": {
    "latitude": 32.8872,
    "longitude": 13.1913,
    "address": "123 Main Street"
  },
  "analytics": {
    "totalViews": 0,
    "uniqueViews": 0,
    "contactClicks": 0,
    "favorites": 0,
    "shares": 0
  }
}
```

### 3. **wallet/{uid}**
Stores user wallet information and transaction history.

**Fields:**
```json
{
  "balance": 200.0,
  "currency": "LYD",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z",
  "transactions": [
    {
      "id": "txn_123",
      "type": "deposit",
      "amount": 200.0,
      "description": "Initial wallet deposit",
      "referenceId": null,
      "metadata": {},
      "createdAt": "2024-01-15T10:30:00Z",
      "status": "completed"
    }
  ],
  "settings": {
    "autoRecharge": false,
    "rechargeThreshold": 50.0,
    "notifications": true
  },
  "stats": {
    "totalDeposited": 200.0,
    "totalSpent": 0.0,
    "totalTransactions": 1
  }
}
```

### 4. **saved_searches/{searchId}**
Stores user's saved property searches.

**Fields:**
```json
{
  "userId": "user_123",
  "name": "Apartments in Tripoli",
  "description": "Looking for apartments in downtown",
  "filters": {
    "type": "apartment",
    "city": "Tripoli",
    "neighborhood": "Downtown",
    "minPrice": 200000.0,
    "maxPrice": 300000.0,
    "minBedrooms": 2,
    "maxBedrooms": 4,
    "features": ["hasBalcony", "hasParking"]
  },
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z",
  "lastRunAt": "2024-01-15T10:30:00Z",
  "isActive": true,
  "notifications": {
    "enabled": true,
    "email": true,
    "push": true
  },
  "stats": {
    "runCount": 0,
    "resultsFound": 0,
    "lastResultsCount": 0
  },
  "schedule": {
    "frequency": "daily",
    "nextRun": "2024-01-16T10:30:00Z"
  }
}
```

### 5. **packages/{packageId}**
Stores premium listing packages.

**Fields:**
```json
{
  "name": "Top Listing - 1 Week",
  "description": "Boost your property for 1 week",
  "price": 100.0,
  "currency": "LYD",
  "durationDays": 7,
  "features": [
    "Featured placement",
    "Priority in search results",
    "Highlighted listing",
    "Increased visibility"
  ],
  "isActive": true,
  "priority": 2,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-15T10:30:00Z",
  "stats": {
    "totalPurchases": 0,
    "totalRevenue": 0.0,
    "activeSubscriptions": 0
  },
  "settings": {
    "maxProperties": 3,
    "boostPriority": 2,
    "featuredPlacement": true
  }
}
```

## 🚀 Setup Instructions

### Step 1: Firebase Console Setup

1. **Go to [Firebase Console](https://console.firebase.google.com)**
2. **Create a new project** or select existing one
3. **Enable Firestore Database:**
   - Go to Firestore Database
   - Click "Create database"
   - Choose "Start in test mode" (for development)
   - Select a location (choose closest to your users)

### Step 2: Enable Authentication

1. **Go to Authentication**
2. **Click "Get started"**
3. **Go to "Sign-in method" tab**
4. **Enable "Email/Password" provider**

### Step 3: Configure Security Rules

Copy the security rules from `firestore_structure.dart` to Firebase Console > Firestore > Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Allow reading other users for public profiles
    }
    
    // Properties collection - authenticated users can read, owners can write
    match /properties/{propertyId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == resource.data.userId;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Wallet collection - users can only access their own wallet
    match /wallet/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Saved searches collection - users can only access their own searches
    match /saved_searches/{searchId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Packages collection - authenticated users can read, admins can write
    match /packages/{packageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
  }
}
```

### Step 4: Create Indexes

Go to Firebase Console > Firestore > Indexes and create these composite indexes:

1. **Collection: properties**
   - Fields: status (Ascending), city (Ascending), createdAt (Descending)

2. **Collection: properties**
   - Fields: type (Ascending), price (Ascending), createdAt (Descending)

3. **Collection: properties**
   - Fields: isBoosted (Descending), isFeatured (Descending), createdAt (Descending)

4. **Collection: saved_searches**
   - Fields: userId (Ascending), createdAt (Descending)

5. **Collection: wallet**
   - Fields: updatedAt (Descending)

### Step 5: Initialize Collections

Use the setup script to initialize your collections:

```dart
import 'package:dary/services/firestore_setup.dart';

// Initialize with sample data
await FirestoreSetup.completeSetup();

// Or initialize just the structure
await FirestoreSetup.initializeFirestore();
```

## 🔧 Usage Examples

### Creating a User Document
```dart
await FirestoreStructure.createUserDocument(
  uid: 'user_123',
  name: 'John Doe',
  email: 'john@example.com',
  phone: '+1234567890',
  isVerified: true,
);
```

### Creating a Property Document
```dart
await FirestoreStructure.createPropertyDocument(
  propertyId: 'property_123',
  userId: 'user_123',
  title: 'Modern Apartment',
  description: 'Beautiful apartment...',
  price: 250000.0,
  // ... other fields
);
```

### Adding Wallet Transaction
```dart
await FirestoreStructure.addWalletTransaction(
  uid: 'user_123',
  type: 'deposit',
  amount: 200.0,
  description: 'Wallet recharge',
);
```

## 📊 Default Packages

The setup script creates these default packages:

1. **Top Listing - 1 Day** (20 LYD)
2. **Top Listing - 1 Week** (100 LYD)
3. **Top Listing - 1 Month** (300 LYD)

## 🔍 Query Examples

### Get Properties by City
```dart
final properties = await FirebaseFirestore.instance
  .collection('properties')
  .where('city', isEqualTo: 'Tripoli')
  .where('status', isEqualTo: 'for_sale')
  .orderBy('createdAt', descending: true)
  .get();
```

### Get User's Properties
```dart
final userProperties = await FirebaseFirestore.instance
  .collection('properties')
  .where('userId', isEqualTo: userId)
  .orderBy('createdAt', descending: true)
  .get();
```

### Get Boosted Properties
```dart
final boostedProperties = await FirebaseFirestore.instance
  .collection('properties')
  .where('isBoosted', isEqualTo: true)
  .where('boostExpiresAt', isGreaterThan: Timestamp.now())
  .orderBy('boostExpiresAt', descending: true)
  .get();
```

## ⚠️ Important Notes

1. **Security Rules**: Always test your security rules thoroughly
2. **Indexes**: Create indexes before running complex queries
3. **Data Validation**: Validate data on both client and server side
4. **Backup**: Set up regular backups for production data
5. **Monitoring**: Enable Firestore monitoring and alerts

## 🆘 Troubleshooting

### Common Issues:

1. **Permission Denied**: Check security rules and user authentication
2. **Index Missing**: Create required composite indexes
3. **Quota Exceeded**: Monitor usage and upgrade plan if needed
4. **Slow Queries**: Optimize queries and add proper indexes

### Support:
- [Firebase Documentation](https://firebase.google.com/docs/firestore)
- [FlutterFire Documentation](https://firebase.flutter.dev/docs/firestore/usage/)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
