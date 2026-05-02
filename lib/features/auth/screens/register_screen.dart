import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/liquid_background.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkSoft = Color(0xFF5A5F72);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      _showSnack('Please accept the Terms & Conditions');
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.registerWithEmailPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      _showSnack(authProvider.errorMessage ??
          'Registration failed. Please try again.');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      final msg = authProvider.errorMessage ?? '';
      if (!msg.toLowerCase().contains('cancel')) {
        _showSnack(
          msg.isEmpty ? 'Google Sign-In failed. Please try again.' : msg,
        );
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 26),
                        _buildRegisterCard(),
                        const SizedBox(height: 24),
                      ],
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
            onTap: () => Navigator.of(context).pop(),
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

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/pawfect-logo.png',
          width: 280,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        const Text(
          'Create your account',
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
          'Join the pack and start tracking the\nsigns that matter for your companion.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: _inkSoft,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return GlassCard(
      radius: 28,
      blur: 22,
      tintOpacity: 0.6,
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Full name'),
            const SizedBox(height: 8),
            _glassField(
              controller: _nameController,
              hint: 'Your name',
              icon: Icons.person_outline_rounded,
              capitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: Validators.name,
            ),
            const SizedBox(height: 14),
            _label('Email'),
            const SizedBox(height: 8),
            _glassField(
              controller: _emailController,
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            _label('Password'),
            const SizedBox(height: 8),
            _glassField(
              controller: _passwordController,
              hint: 'At least 8 characters',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: Validators.password,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _inkSoft,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _label('Confirm password'),
            const SizedBox(height: 8),
            _glassField(
              controller: _confirmPasswordController,
              hint: 'Type it again',
              icon: Icons.lock_outline_rounded,
              obscure: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleRegister(),
              validator: (value) => Validators.confirmPassword(
                value,
                _passwordController.text,
              ),
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _inkSoft,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _termsRow(),
            const SizedBox(height: 18),
            _primaryButton(),
            const SizedBox(height: 18),
            _orDivider(),
            const SizedBox(height: 16),
            _googleButton(),
          ],
        ),
      ),
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
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    Widget? suffix,
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
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        textCapitalization: capitalization,
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
          suffixIcon: suffix,
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

  Widget _termsRow() {
    return GestureDetector(
      onTap: () => setState(() => _acceptTerms = !_acceptTerms),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _acceptTerms
                  ? PawfectColors.pawfectOrange
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _acceptTerms
                    ? PawfectColors.pawfectOrange
                    : _inkSoft.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: _acceptTerms
                ? const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: const TextStyle(
                  fontSize: 12,
                  color: _inkSoft,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: const TextStyle(
                      color: PawfectColors.pawfectOrange,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleRegister,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
              : const Text(
                  'Create Account',
                  style: TextStyle(
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

  Widget _orDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: const Text(
            'or',
            style: TextStyle(
              fontSize: 11,
              color: _inkSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _googleButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleGoogleSignIn,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.65),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.7),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/google_logo.png',
              height: 20,
              width: 20,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.g_mobiledata, size: 22, color: _ink);
              },
            ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _ink,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
