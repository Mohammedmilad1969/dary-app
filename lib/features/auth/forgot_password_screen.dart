import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dary_loading_indicator.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(_emailController.text.trim());
    final l10n = AppLocalizations.of(context)!;

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.resetInstructionsSent),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? l10n.verificationError),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryColor,
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
                    theme.colorScheme.secondary.withValues(alpha: 0.5),
                    theme.primaryColor.withValues(alpha: 0.0),
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
                  children: [
                    const SizedBox(height: 10),
                    // Back Button
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Illustration/Icon Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title and Description
                    Text(
                      l10n.forgotPasswordTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.forgotPasswordDescription,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

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
                          _buildTextField(
                            controller: _emailController,
                            hint: l10n.emailAddress,
                            icon: Icons.alternate_email_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) return l10n.emailRequired;
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return l10n.enterValidEmail;
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading ? null : _handleResetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: theme.primaryColor,
                                elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? const DaryLoadingIndicator(
                                        size: 24,
                                        strokeWidth: 3,
                                        color: Colors.teal,
                                      )
                                  : Text(
                                      l10n.sendInstructions,
                                      style: GoogleFonts.outfit(
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

                    // Back to Login Link
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                          children: [
                            TextSpan(text: '${l10n.rememberPassword} '),
                            TextSpan(
                              text: l10n.backToLogin,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 16),
        prefixIcon: Icon(icon, color: Colors.white60, size: 22),
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

