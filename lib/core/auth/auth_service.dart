import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalAuthentication _localAuth = LocalAuthentication();

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    notifyListeners();
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    notifyListeners();
    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }

  Future<bool> isBiometricsAvailable() async {
    if (kIsWeb) return false;
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canAuthenticate && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) return false;
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access PassCoder',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    final response = await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    notifyListeners();
    return response;
  }
}
