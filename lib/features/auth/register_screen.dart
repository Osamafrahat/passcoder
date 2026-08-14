import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/auth_service.dart';
import '../../app/app.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      await authService.signUp(email: _emailController.text.trim(), password: _passwordController.text);
      // Save credentials for biometric login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_saved_credentials', true);
      await prefs.setString('saved_email', _emailController.text.trim());
      debugPrint('REGISTER: Credentials saved via SharedPreferences');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created! Check email for verification.'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithGoogle();
      // Save marker for Google sign-in
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_saved_credentials', true);
      await prefs.setString('saved_email', Supabase.instance.client.auth.currentUser?.email ?? 'google_user');
      debugPrint('GOOGLE REGISTER: Credentials saved via SharedPreferences');
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
          theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7), theme.colorScheme.secondary,
        ])),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.person_add_outlined, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  Text('Create Account', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Start securing your passwords', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildGoogleBtn(),
                          const SizedBox(height: 16),
                          Row(children: [
                            const Expanded(child: Divider(color: Colors.white38)),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('or', style: TextStyle(color: Colors.white70, fontSize: 13))),
                            const Expanded(child: Divider(color: Colors.white38)),
                          ]),
                          const SizedBox(height: 16),
                          _buildField(controller: _emailController, hint: 'Email', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
                          const SizedBox(height: 14),
                          _buildField(controller: _passwordController, hint: 'Password', icon: Icons.lock_outlined, obscure: _obscurePassword, suffix: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white60, size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
                          const SizedBox(height: 14),
                          _buildField(controller: _confirmPasswordController, hint: 'Confirm Password', icon: Icons.lock_outlined, obscure: _obscureConfirm, suffix: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white60, size: 20), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
                          const SizedBox(height: 22),
                          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: theme.colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                          )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Already have an account? Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleBtn() {
    return SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
      onPressed: _isLoading ? null : _registerWithGoogle,
      icon: const Icon(Icons.g_mobiledata, size: 26),
      label: const Text('Sign up with Google', style: TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    ));
  }

  Widget _buildField({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false, TextInputType? keyboard, Widget? suffix}) {
    return TextFormField(
      controller: controller, obscureText: obscure, keyboardType: keyboard, style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white60, size: 20), suffixIcon: suffix,
        filled: true, fillColor: Colors.white.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white38)),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (hint == 'Email' && !v.contains('@')) return 'Invalid email';
        if (hint == 'Password' && v.length < 8) return 'Min 8 characters';
        if (hint == 'Confirm Password' && v != _passwordController.text) return 'Passwords don\'t match';
        return null;
      },
    );
  }
}
