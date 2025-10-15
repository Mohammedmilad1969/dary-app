import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';

class ImageUploadService {
  /// Upload a single image to Supabase Storage
  static Future<String?> uploadImage(XFile imageFile, String propertyId, int imageIndex) async {
    try {
      // Use Supabase Storage for both web and mobile
      return await _uploadImageSupabase(imageFile, propertyId, imageIndex);
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
}