import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/language_service.dart';
import '../../widgets/language_toggle_button.dart';
import 'package:dary/services/theme_service.dart';
import '../../widgets/dary_loading_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Translates a Firebase REST API error code to a localized string.
  /// Firebase REST API returns uppercase codes like: INVALID_PASSWORD, EMAIL_NOT_FOUND, etc.
  String _translateAuthError(String? rawError, AppLocalizations? l10n) {
    if (rawError == null || rawError.isEmpty) {
      return l10n?.firebaseGenericError ?? 'An error occurred. Please try again.';
    }
    // Uppercase for matching (REST API codes are uppercase)
    final e = rawError.toUpperCase();

    // Firebase REST API error codes
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
    } else if (e.contains('EMAIL_NOT_VERIFIED') || e.contains('EMAIL NOT VERIFIED')) {
      return l10n?.emailNotVerifiedMessage ?? 'Please verify your email to access all features.';
    }
    return l10n?.firebaseGenericError ?? 'An error occurred. Please try again.';
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final l10n = AppLocalizations.of(context);
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.login(
          _identifierController.text.trim(),
          _passwordController.text,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.loginSuccess ?? 'Login successful! Welcome back'),
              backgroundColor: const Color(0xFF01352D),
              duration: const Duration(seconds: 3),
            ),
          );
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
            content: Text(l10n?.loginSuccess ?? 'Login successful! Welcome back'),
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
      backgroundColor: const Color(0xFF01352B),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF025141).withValues(alpha: 0.5),
                    const Color(0xFF01352B).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF025141).withValues(alpha: 0.4),
                    const Color(0xFF01352B).withValues(alpha: 0.0),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 10), // Reduced from 40
                    
                    // Logo and Branding
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        padding: const EdgeInsets.all(12), // Reduced from 20
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 15, // Reduced from 20
                              offset: const Offset(0, 8), // Reduced from 10
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/dary_logo.png',
                          width: 50, // Reduced from 80
                          height: 50, // Reduced from 80
                          fit: BoxFit.contain,
                          color: const Color(0xFF01352B),
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.home_work_rounded,
                            color: Color(0xFF01352B),
                            size: 40, // Reduced from 60
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12), // Reduced from 24
                    Text(
                      l10n?.welcomeToDary ?? 'Welcome to Dary',
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 26, // Reduced from 32
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      l10n?.yourSmartPropertyCompanion ?? 'Your smart property companion',
                      style: ThemeService.getDynamicStyle(
                        context,
                        fontSize: 14, // Reduced from 16
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20), // Reduced from 48

                    // Glassmorphic Form Container
                    Container(
                      padding: const EdgeInsets.all(20), // Reduced from 24
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24), // Reduced from 32
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30, // Reduced from 40
                            offset: const Offset(0, 15), // Reduced from 20
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Identifier Field
                          _buildTextField(
                            controller: _identifierController,
                            hint: l10n?.emailOrPhone ?? 'Email or Phone',
                            icon: Icons.mail_outline_rounded,
                            validator: (value) => 
                                value!.isEmpty ? (l10n?.enterEmailOrPhone ?? 'Enter your email or phone') : null,
                          ),
                          const SizedBox(height: 16), // Reduced from 20
                          
                          // Password Field
                          _buildTextField(
                            controller: _passwordController,
                            hint: l10n?.password ?? 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onTogglePassword: () => 
                                setState(() => _obscurePassword = !_obscurePassword),
                            validator: (value) => 
                                value!.isEmpty ? (l10n?.enterPassword ?? 'Enter your password') : null,
                          ),
                          
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 30),
                              ),
                              child: Text(
                                l10n?.forgotPassword ?? 'Forgot Password?',
                                style: ThemeService.getDynamicStyle(
                                  context,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13, // Reduced from 14
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12), // Reduced from 24
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 54, // Reduced from 60
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF01352B),
                                elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? const DaryLoadingIndicator(
                                        size: 20,
                                        strokeWidth: 2.5,
                                        color: Color(0xFF01352B),
                                      )
                                  : Text(
                                      l10n?.signIn ?? 'Sign In',
                                      style: ThemeService.getDynamicStyle(
                                        context,
                                        fontSize: 16, // Reduced from 18
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20), // Reduced from 40
                    
                    // Social Login Section
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            l10n?.orContinueWith ?? 'Or continue with',
                            style: ThemeService.getDynamicStyle(
                              context,
                              color: Colors.white54,
                              fontSize: 13, // Reduced from 14
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                      ],
                    ),
                    const SizedBox(height: 16), // Reduced from 32
                    // Google Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: authProvider.isLoading ? null : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             const FaIcon(
                               FontAwesomeIcons.google,
                               color: Colors.white,
                               size: 20,
                             ),
                            const SizedBox(width: 10),
                            Text(
                              l10n?.google ?? 'Google',
                              style: ThemeService.getDynamicStyle(
                                context,
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20), // Reduced from 40
                    
                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n?.dontHaveAccount ?? "Don't have an account?",
                          style: ThemeService.getDynamicStyle(
                            context, 
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 30),
                          ),
                          child: Text(
                            l10n?.signUp ?? 'Sign Up',
                            style: ThemeService.getDynamicStyle(
                              context,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15, // Reduced from 16
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Reduced from 40
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
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
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

