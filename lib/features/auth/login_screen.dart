import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth/auth_service.dart';
import '../../app/app.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricsAvailable = false;
  bool _hasSavedCredentials = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final authService = context.read<AuthService>();
    final available = await authService.isBiometricsAvailable();
    final hasCreds = await authService.hasSavedCredentials();
    if (mounted) setState(() { _biometricsAvailable = available; _hasSavedCredentials = hasCreds; });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      await authService.signIn(email: _emailController.text.trim(), password: _passwordController.text);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      await authService.signInWithGoogle();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _biometricLogin() async {
    final authService = context.read<AuthService>();
    if (kIsWeb) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometric login not available on web.'))); return; }
    setState(() => _isLoading = true);
    try {
      final didAuth = await authService.authenticateWithBiometrics();
      if (!didAuth) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Authentication failed.'), backgroundColor: Colors.red)); return; }
      final response = await authService.signInWithBiometrics();
      if (response != null && mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthGate()));
      else if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No saved credentials. Sign in first.'), backgroundColor: Colors.orange));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBiometrics = _biometricsAvailable && _hasSavedCredentials;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
            theme.colorScheme.secondary,
          ]),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.shield_outlined, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text('PassCoder', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text('Secure Password Manager', style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 44),
                      _buildGlassCard(
                        child: Column(
                          children: [
                            _buildGoogleButton(),
                            const SizedBox(height: 16),
                            Row(children: [
                              const Expanded(child: Divider(color: Colors.white38)),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('or', style: TextStyle(color: Colors.white70, fontSize: 13))),
                              const Expanded(child: Divider(color: Colors.white38)),
                            ]),
                            const SizedBox(height: 16),
                            _buildTextField(controller: _emailController, hint: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 14),
                            _buildTextField(controller: _passwordController, hint: 'Password', icon: Icons.lock_outlined, obscure: _obscurePassword, suffix: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white60, size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
                            const SizedBox(height: 22),
                            SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: theme.colorScheme.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple)) : const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            )),
                            if (showBiometrics) ...[
                              const SizedBox(height: 14),
                              SizedBox(width: double.infinity, height: 50, child: OutlinedButton.icon(
                                onPressed: _biometricLogin,
                                icon: const Icon(Icons.fingerprint, color: Colors.white70),
                                label: const Text('Sign in with Biometrics', style: TextStyle(color: Colors.white70)),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                              )),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.2)), boxShadow: [BoxShadow(blurRadius: 30, color: Colors.black.withValues(alpha: 0.1))]),
      child: child,
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(
      onPressed: _isLoading ? null : _loginWithGoogle,
      icon: const Icon(Icons.g_mobiledata, size: 26),
      label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    ));
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false, TextInputType? keyboardType, Widget? suffix}) {
    return TextFormField(
      controller: controller, obscureText: obscure, keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white60, size: 20), suffixIcon: suffix,
        filled: true, fillColor: Colors.white.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white38)),
      ),
      validator: (v) { if (v == null || v.isEmpty) return 'Required'; if (hint == 'Email' && !v.contains('@')) return 'Invalid email'; return null; },
    );
  }
}
