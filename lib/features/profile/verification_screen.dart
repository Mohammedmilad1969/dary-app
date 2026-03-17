import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import '../../widgets/dary_loading_indicator.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _idCardImage;
  File? _businessLicenseImage;
  bool _isSubmitting = false;

  Future<void> _pickImage(ImageSource source, bool isIdCard) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          if (isIdCard) {
            _idCardImage = File(image.path);
          } else {
            _businessLicenseImage = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.errorPickingImage(e) ?? 'Error picking image'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImagePicker(BuildContext context, bool isIdCard) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppLocalizations.of(context)?.camera ?? 'Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera, isIdCard);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context)?.gallery ?? 'Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery, isIdCard);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitVerification() async {
    if (_idCardImage == null || _businessLicenseImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.pleaseUploadBothDocuments ?? 'Please upload both documents'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 2));

      // Update user verification status
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.verifyUser();

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)?.verificationSuccess ?? 'You are now a verified seller!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.verificationSuccessMessage ?? 
                    'Your documents have been verified. You can now enjoy all the benefits of being a verified seller.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to profile
                  },
                  child: Text(
                    AppLocalizations.of(context)?.continueText ?? 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.verificationError ?? 'Verification failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    // If user is already verified, show a different screen
    if (currentUser?.isVerified == true) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n?.verification ?? 'Verification'),
          centerTitle: true,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          actions: [
            LanguageToggleButton(languageService: languageService),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n?.alreadyVerified ?? 'You are already verified!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.alreadyVerifiedMessage ?? 
                  'Your account has been verified. You can enjoy all the benefits of being a verified seller.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.go('/profile'),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l10n?.backToProfile ?? 'Back to Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.verification ?? 'Verification'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          LanguageToggleButton(languageService: languageService),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.verificationInfo ?? 'Verification Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n?.verificationDescription ?? 
                      'To become a verified seller, please upload your ID card and business license. This helps us verify your identity and build trust with potential buyers.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // ID Card Upload
            Text(
              l10n?.uploadIdCard ?? 'Upload ID Card',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: InkWell(
                onTap: () => _showImagePicker(context, true),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _idCardImage != null ? Colors.green : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: _idCardImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            _idCardImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.credit_card,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n?.tapToUploadIdCard ?? 'Tap to upload ID card',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Business License Upload
            Text(
              l10n?.uploadBusinessLicense ?? 'Upload Business License',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: InkWell(
                onTap: () => _showImagePicker(context, false),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _businessLicenseImage != null ? Colors.green : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: _businessLicenseImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            _businessLicenseImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.business,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n?.tapToUploadLicense ?? 'Tap to upload business license',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const DaryLoadingIndicator(
                            size: 20,
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Text('Submitting...'),
                        ],
                      )
                    : Text(
                        l10n?.submitVerification ?? 'Submit for Verification',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Privacy Notice
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n?.privacyNotice ?? 
                        'Your documents are encrypted and stored securely. We only use them for verification purposes.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
