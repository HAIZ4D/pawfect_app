import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendPasswordResetEmail(
      _emailController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (mounted) {
      if (success) {
        setState(() => _emailSent = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.errorMessage ??
                  'Failed to send reset email. Please try again.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _backToLogin() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      body: Stack(
        children: [
          const LiquidBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildBackBar(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: _emailSent
                          ? _buildSuccessView()
                          : _buildResetForm(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: _backToLogin,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.7),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _ink,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm() {
    return Column(
      children: [
        _buildHeaderIcon(Icons.lock_reset_rounded, PawfectColors.pawfectOrange),
        const SizedBox(height: 16),
        const Text(
          'Forgot password?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _ink,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your email and we\'ll send a\nreset link straight to your inbox.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: _inkSoft,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 26),
        GlassCard(
          radius: 26,
          blur: 22,
          tintOpacity: 0.6,
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('Email'),
                const SizedBox(height: 8),
                _glassField(
                  controller: _emailController,
                  hint: 'you@example.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: Validators.email,
                  onSubmitted: (_) => _handleSendResetEmail(),
                ),
                const SizedBox(height: 18),
                _primaryButton(
                  label: 'Send Reset Link',
                  onTap: _handleSendResetEmail,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      children: [
        _buildHeaderIcon(Icons.check_circle_rounded, const Color(0xFF2E8A68)),
        const SizedBox(height: 24),
        GlassCard(
          radius: 26,
          blur: 22,
          tintOpacity: 0.6,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Email sent!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2E8A68),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We've sent a reset link to:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _inkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _emailController.text.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: PawfectColors.pawfectOrange,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEAD5).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFE07B2A),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Check your inbox — and the spam folder, just in case.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: _ink,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _primaryButton(label: 'Back to Login', onTap: _backToLogin),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderIcon(IconData icon, Color tint) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tint, tint.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: tint.withOpacity(0.4),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(icon, size: 40, color: Colors.white),
    );
  }

  Widget _label(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: _inkSoft,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    void Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.7),
          width: 1.2,
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        onFieldSubmitted: onSubmitted,
        style: const TextStyle(
          fontSize: 14,
          color: _ink,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: _inkSoft,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: PawfectColors.pawfectOrange,
            size: 20,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              PawfectColors.pawfectOrange,
              Color(0xFFFFB347),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: PawfectColors.pawfectOrange.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
        ),
      ),
    );
  }
}
