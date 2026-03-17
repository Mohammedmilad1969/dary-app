import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class ImageUploadService {
  /// Compress image file
  static Future<XFile> compressImage(XFile file) async {
    // Web Compression Support
    if (kIsWeb) {
      try {
        print('Compressing image for Web: ${file.name}');
        final bytes = await file.readAsBytes();
        
        // Skip compression for very small files (< 200KB)
        if (bytes.length < 200 * 1024) return file;

        // Compress using compressWithList
        final compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minHeight: 1280, // slightly larger for better web quality
          minWidth: 1280, 
          quality: 70, // 70% quality
        );
        
        print('Compression result: ${bytes.length} -> ${compressedBytes.length} bytes');
        
        // Return compressed file as XFile
        return XFile.fromData(
          Uint8List.fromList(compressedBytes), 
          name: file.name, 
          mimeType: 'image/jpeg' // Force jpeg for consistency
        );
      } catch (e) {
        print('Web compression failed: $e');
        return file; // Fallback to original
      }
    }

    // Mobile/Desktop Compression
    final dir = await path_provider.getTemporaryDirectory();
    final targetPath = '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
    );

    return result ?? file;
  }

  /// Upload a single image to Supabase Storage
  static Future<String?> uploadImage(XFile imageFile, String propertyId, int imageIndex) async {
    try {
      // Compress image before uploading
      final compressedFile = await compressImage(imageFile);
      // Use Supabase Storage for both web and mobile
      return await _uploadImageSupabase(compressedFile, propertyId, imageIndex);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Upload image to Supabase Storage (works for both web and mobile)
  static Future<String?> _uploadImageSupabase(XFile imageFile, String propertyId, int imageIndex) async {
    try {
      // Create a unique filename with proper extension
      final extension = imageFile.name.split('.').last;
      final fileName = 'property_${propertyId}_${imageIndex}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      print('Uploading image: $fileName');
      
      // Handle web vs mobile uploads differently
      if (kIsWeb) {
        // For web: use Uint8List
        final Uint8List fileBytes = await imageFile.readAsBytes();
        final response = await Supabase.instance.client.storage
            .from('property-images')
            .uploadBinary(fileName, fileBytes);
        
        if (response.isNotEmpty) {
          final publicUrl = Supabase.instance.client.storage
              .from('property-images')
              .getPublicUrl(fileName);
          
          print('Image uploaded successfully (web): $publicUrl');
          return publicUrl;
        }
      } else {
        // For mobile: use File
        final response = await Supabase.instance.client.storage
            .from('property-images')
            .upload(fileName, File(imageFile.path));
        
        if (response.isNotEmpty) {
          final publicUrl = Supabase.instance.client.storage
              .from('property-images')
              .getPublicUrl(fileName);
          
          print('Image uploaded successfully (mobile): $publicUrl');
          return publicUrl;
        }
      }
      return null;
    } catch (e) {
      print('Error uploading image to Supabase: $e');
      return null;
    }
  }

  /// Upload multiple images
  static Future<List<String>> uploadImages(List<XFile> imageFiles, String propertyId) async {
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final url = await uploadImage(imageFiles[i], propertyId, i);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }
    
    return uploadedUrls;
  }

  /// Delete an image from Supabase Storage
  static Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract filename from URL
      final fileName = imageUrl.split('/').last.split('?').first;
      await Supabase.instance.client.storage
          .from('property-images')
          .remove([fileName]);
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Delete multiple images
  static Future<void> deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      await deleteImage(url);
    }
  }

  /// Get image upload progress (simulated)
  static Stream<double> getUploadProgress(XFile imageFile, String propertyId, int imageIndex) {
    return Stream.periodic(const Duration(milliseconds: 100), (count) {
      return (count * 0.1).clamp(0.0, 1.0);
    }).take(10);
  }

  /// Upload profile or cover image for user
  static Future<String?> uploadProfileImage(XFile imageFile, {bool isCoverImage = false}) async {
    try {
      final authProvider = Supabase.instance.client.auth.currentUser;
      final userId = authProvider?.id ?? 'anonymous';
      
      // Create a unique filename with folder prefix
      final extension = imageFile.name.split('.').last;
      final prefix = isCoverImage ? 'cover' : 'profile';
      final fileName = '${prefix}_${userId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      print('Uploading ${isCoverImage ? "cover" : "profile"} image: $fileName');
      
      // Use the existing property-images bucket (or create a user-images bucket)
      const bucketName = 'property-images'; // Using existing bucket
      
      // Handle web vs mobile uploads differently
      if (kIsWeb) {
        // For web: use Uint8List
        final Uint8List fileBytes = await imageFile.readAsBytes();
        final response = await Supabase.instance.client.storage
            .from(bucketName)
            .uploadBinary(fileName, fileBytes);
        
        if (response.isNotEmpty) {
          final publicUrl = Supabase.instance.client.storage
              .from(bucketName)
              .getPublicUrl(fileName);
          
          print('Image uploaded successfully (web): $publicUrl');
          return publicUrl;
        }
      } else {
        // For mobile: use File
        final response = await Supabase.instance.client.storage
            .from(bucketName)
            .upload(fileName, File(imageFile.path));
        
        if (response.isNotEmpty) {
          final publicUrl = Supabase.instance.client.storage
              .from(bucketName)
              .getPublicUrl(fileName);
          
          print('Image uploaded successfully (mobile): $publicUrl');
          return publicUrl;
        }
      }
      return null;
    } catch (e) {
      print('Error uploading profile/cover image: $e');
      return null;
    }
  }

  /// Upload a chat image
  static Future<String?> uploadChatImage(XFile imageFile, String conversationId) async {
    try {
      // Compress image before uploading
      final compressedFile = await compressImage(imageFile);
      
      // Create a unique filename
      final extension = compressedFile.name.split('.').last;
      final fileName = 'chat_${conversationId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      print('Uploading chat image: $fileName');
      
      // Use the existing property-images bucket for now
      const bucketName = 'property-images';
      
      if (kIsWeb) {
        final Uint8List fileBytes = await compressedFile.readAsBytes();
        await Supabase.instance.client.storage
            .from(bucketName)
            .uploadBinary(fileName, fileBytes);
      } else {
        await Supabase.instance.client.storage
            .from(bucketName)
            .upload(fileName, File(compressedFile.path));
      }
      
      final publicUrl = Supabase.instance.client.storage
          .from(bucketName)
          .getPublicUrl(fileName);
          
      return publicUrl;
    } catch (e) {
      print('Error uploading chat image: $e');
      return null;
    }
  }
}