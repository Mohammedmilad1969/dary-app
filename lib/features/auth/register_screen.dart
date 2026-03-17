import 'dart:io';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import 'package:dary/services/theme_service.dart';
import '../../widgets/dary_loading_indicator.dart';
import 'package:flutter/services.dart';
import '../../utils/text_input_formatters.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import '../../widgets/text_captcha.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isCaptchaValid = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Translates a Firebase REST API error code to a localized string.
  /// Firebase REST API returns uppercase codes like: EMAIL_EXISTS, WEAK_PASSWORD, etc.
  String _translateAuthError(String? rawError, AppLocalizations? l10n) {
    if (rawError == null || rawError.isEmpty) {
      return l10n?.firebaseGenericError ?? 'An error occurred. Please try again.';
    }
    // Uppercase for matching (REST API codes are uppercase)
    final e = rawError.toUpperCase();

    // Check for custom AuthException messages
    if (rawError.contains('AuthException:')) {
      return rawError.replaceAll('AuthException:', '').trim();
    }
    
    // 1. Check for Rate Limiting (Priority)
    if (e.contains('TOO_MANY_ATTEMPTS') || e.contains('TOO_MANY_REQUESTS') || e.contains('TOO MANY')) {
      return l10n?.firebaseTooManyRequests ?? 'Too many attempts from this device. Please wait 15-30 minutes before trying again.';
    }

    // 2. Check for reCAPTCHA / Domain issues
    if (e.contains('RECAPTCHA') || e.contains('VERIFICATION REQUIRES RECAPTCHA') || 
        e.contains('INVALID_APP_CREDENTIAL') || e.contains('CAPTCHA_CHECK_FAILED')) {
      return 'Authentication failed. Please check if reCAPTCHA is solved or if the domain is authorized in Firebase Console.';
    }
    
    // 3. Phone already in use
    if (e.contains('PHONE_NUMBER_ALREADY_EXISTS') || e.contains('PHONE ALREADY') || e.contains('PHONE NUMBER IS ALREADY REGISTERED')) {
      return l10n?.firebasePhoneAlreadyInUse ?? 'This phone number is already registered.';
    }

    // 4. Other Firebase REST API error codes
    if (e.contains('INVALID_PASSWORD') || e.contains('INVALID_LOGIN_CREDENTIALS') || e.contains('WRONG_PASSWORD')) {
      return l10n?.firebaseWrongPassword ?? 'Incorrect password. Please try again.';
    } else if (e.contains('EMAIL_NOT_FOUND') || e.contains('USER_NOT_FOUND') || e.contains('USER NOT FOUND') || e.contains('NO USER RECORD')) {
      return l10n?.firebaseUserNotFound ?? 'No account found with this email or phone.';
    } else if (e.contains('EMAIL_EXISTS') || e.contains('EMAIL_ALREADY_IN_USE') || e.contains('EMAIL ALREADY')) {
      return l10n?.firebaseEmailAlreadyInUse ?? 'This email is already registered.';
    } else if (e.contains('PHONE_NUMBER_ALREADY_EXISTS') || e.contains('PHONE ALREADY') || e.contains('PHONE NUMBER IS ALREADY REGISTERED')) {
      return l10n?.firebasePhoneAlreadyInUse ?? 'This phone number is already registered.';
    } else if (e.contains('WEAK_PASSWORD') || e.contains('WEAK PASSWORD')) {
      return l10n?.firebaseWeakPassword ?? 'Password is too weak.';
    } else if (e.contains('TOO_MANY_ATTEMPTS') || e.contains('TOO_MANY_REQUESTS') || e.contains('TOO MANY')) {
      return l10n?.firebaseTooManyRequests ?? 'Too many attempts. Please wait.';
    } else if (e.contains('NETWORK_REQUEST_FAILED') || e.contains('NETWORK ERROR') || e.contains('NETWORK_ERROR')) {
      return l10n?.firebaseNetworkError ?? 'Network error. Check your connection.';
    } else if (e.contains('INVALID_EMAIL')) {
      return l10n?.firebaseInvalidEmail ?? 'Invalid email format.';
    } else if (e.contains('USER_DISABLED')) {
      return l10n?.firebaseUserDisabled ?? 'This account has been disabled.';
    } else if (e.contains('OPERATION_NOT_ALLOWED')) {
      return l10n?.firebaseOperationNotAllowed ?? 'Operation not allowed.';
    } else if (e.contains('ACCOUNT_EXISTS_WITH_DIFFERENT_CREDENTIAL')) {
      return l10n?.firebaseAccountExistsWithDifferentCredential ?? 'Account exists with different credentials.';
    } else if (e.contains('REQUIRES_RECENT_LOGIN')) {
      return l10n?.firebaseRequiresRecentLogin ?? 'Please sign in again.';
    } else if (e.contains('INVALID_CREDENTIAL')) {
      return l10n?.firebaseInvalidCredential ?? 'Invalid credentials.';
    } else if (rawError.contains('EMAIL_NOT_VERIFIED') || rawError.contains('EMAIL NOT VERIFIED')) {
      return l10n?.emailNotVerifiedMessage ?? 'Please verify your email to access all features.';
    }
    
    // If it's a direct message (not a code), return it if it's user friendly
    if (!e.contains('_') && e.length > 5 && e.length < 100) {
      return rawError;
    }
    
    return l10n?.firebaseGenericError ?? 'An error occurred. Please try again.';
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final l10n = AppLocalizations.of(context);
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.termsAndConditions ?? 'Please agree to terms and conditions'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }
      
      if (!_isCaptchaValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete the security check'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _phoneController.text.trim(),
          _passwordController.text,
        );

        if (success && mounted) {
          // Use a small delay or post-frame callback to ensure stable state before navigating
          Future.microtask(() {
            if (mounted) {
              context.go('/');
            }
          });
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_translateAuthError(authProvider.errorMessage, l10n)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ RegisterScreen: Registration error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_translateAuthError(e.toString(), AppLocalizations.of(context))),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final l10n = AppLocalizations.of(context);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.signingInWithGoogle ?? 'Signing in with Google...'),
          backgroundColor: const Color(0xFF01352D),
          duration: const Duration(seconds: 2),
        ),
      );
      
      final success = await authProvider.signInWithGoogle();
      
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.registerSuccess ?? 'Account created successfully! Welcome to Dary'),
            backgroundColor: const Color(0xFF01352D),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_translateAuthError(authProvider.errorMessage, l10n)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_translateAuthError(e.toString(), AppLocalizations.of(context))),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageService = Provider.of<LanguageService>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF01352D),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF025141).withValues(alpha: 0.5),
                    const Color(0xFF01352D).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF025141).withValues(alpha: 0.4),
                    const Color(0xFF01352D).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => context.go('/'),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: LanguageToggleButton(languageService: languageService),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // Logo and Branding
                    Center(
                      child: Hero(
                        tag: 'app_logo',
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/dary_logo.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                            color: const Color(0xFF01352D),
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.home_work_rounded,
                              color: Color(0xFF01352D),
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              l10n?.createAccount ?? 'Create Account',
                              style: ThemeService.getDynamicStyle(
                                context,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              l10n?.joinDaryFindDreamHome ?? 'Join Dary and find your dream home',
                              textAlign: TextAlign.center,
                              style: ThemeService.getDynamicStyle(
                                context,
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Glassmorphic Form Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Full Name Field
                          _buildTextField(
                            controller: _nameController,
                            hint: l10n?.fullName ?? 'Full Name',
                            icon: Icons.person_outline_rounded,
                            validator: (value) => 
                                value!.isEmpty ? (l10n?.enterFullName ?? 'Enter your full name') : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            hint: l10n?.emailAddress ?? 'Email Address',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return l10n?.enterEmail ?? 'Enter your email';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return l10n?.invalidEmail ?? 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Phone Field
                          _buildTextField(
                            controller: _phoneController,
                            hint: l10n?.phoneNumber ?? 'Phone Number',
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [PhoneNumberFormatter()],
                            validator: (value) => 
                                value!.isEmpty ? (l10n?.enterPhoneNumber ?? 'Enter your phone number') : null,
                          ),
                          const SizedBox(height: 16),
                          
                          // Password Field
                          _buildTextField(
                            controller: _passwordController,
                            hint: l10n?.password ?? 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onTogglePassword: () => 
                                setState(() => _obscurePassword = !_obscurePassword),
                            validator: (value) {
                              if (value == null || value.isEmpty) return l10n?.enterPasswordValidation ?? 'Enter password';
                              if (value.length < 8) return l10n?.passwordMinLength ?? 'Password must be at least 8 characters';
                              if (!value.contains(RegExp(r'[A-Z]'))) return l10n?.passwordNeedsCapital ?? 'Must contain at least one capital letter';
                              if (!value.contains(RegExp(r'[0-9]'))) return l10n?.passwordNeedsNumber ?? 'Must contain at least one number';
                              if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return l10n?.passwordNeedsSymbol ?? 'Must contain at least one symbol';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Confirm Password Field
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hint: l10n?.confirmPassword ?? 'Confirm Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onTogglePassword: () => 
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            validator: (value) {
                              if (value == null || value.isEmpty) return l10n?.confirmYourPassword ?? 'Confirm your password';
                              if (value != _passwordController.text) return l10n?.passwordsDoNotMatch ?? 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Security Check (Text Captcha)
                          TextCaptcha(
                            onValidChanged: (isValid) => setState(() => _isCaptchaValid = isValid),
                          ),
                          const SizedBox(height: 24),
                          
                          // Terms and Conditions Toggle
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.9,
                                child: Switch(
                                  value: _agreeToTerms,
                                  onChanged: (value) => setState(() => _agreeToTerms = value),
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: const Color(0xFF025141),
                                  inactiveTrackColor: Colors.white12,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  l10n?.agreeToTermsPrivacy ?? 'I agree to the Terms & Privacy Policy',
                                  style: ThemeService.getDynamicStyle(
                                    context,
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF01352D),
                                elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? const DaryLoadingIndicator(
                                        size: 24,
                                        strokeWidth: 3,
                                        color: Color(0xFF01352D),
                                      )
                                  : Text(
                                      l10n?.createAccount ?? 'Create Account',
                                      style: ThemeService.getDynamicStyle(
                                        context,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                    const SizedBox(height: 32),
                    
                    // Social Login Section
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            l10n?.orSignUpWith ?? 'Or sign up with',
                            style: ThemeService.getDynamicStyle(
                              context,
                              color: Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Google Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton(
                        onPressed: authProvider.isLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.google,
                              color: Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n?.googleAccount ?? 'Google Account',
                              style: ThemeService.getDynamicStyle(
                                context,
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    
                    const SizedBox(height: 32),
                    
                    // Sign In Link
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n?.alreadyHaveAccount ?? 'Already have an account?',
                            style: ThemeService.getDynamicStyle(context, color: Colors.white70),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(
                              l10n?.signIn ?? 'Sign In',
                              style: ThemeService.getDynamicStyle(
                                context,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<dynamic>? inputFormatters,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters != null ? List<TextInputFormatter>.from(inputFormatters) : null,
      style: ThemeService.getDynamicStyle(context, color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: ThemeService.getDynamicStyle(context, color: Colors.white38, fontSize: 16),
        prefixIcon: Icon(icon, color: Colors.white60, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white60,
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white38, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}

// Removing local WavePainter as it's no longer used in the new design

