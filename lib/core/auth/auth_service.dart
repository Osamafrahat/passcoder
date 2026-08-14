import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

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
    if (response.user != null) {
      await _saveCredentials(email, password);
    }
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
    if (response.user != null) {
      await _saveCredentials(email, password);
    }
    notifyListeners();
    return response;
  }

  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.passcoder://login-callback/',
    );
    notifyListeners();
  }

  Future<void> _saveCredentials(String email, String password) async {
    try {
      await _secureStorage.write(key: 'saved_email', value: email);
      await _secureStorage.write(key: 'saved_password', value: password);
    } catch (e) {
      debugPrint('Failed to save credentials: $e');
    }
  }

  Future<Map<String, String>?> _getSavedCredentials() async {
    try {
      final email = await _secureStorage.read(key: 'saved_email');
      final password = await _secureStorage.read(key: 'saved_password');
      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
    } catch (e) {
      debugPrint('Failed to read credentials: $e');
      return null;
    }
    return null;
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

  Future<bool> hasSavedCredentials() async {
    final creds = await _getSavedCredentials();
    return creds != null;
  }

  Future<bool> authenticateWithBiometrics() async {
    if (kIsWeb) return false;
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your passwords',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      debugPrint('Biometric auth failed: $e');
      return false;
    }
  }

  Future<AuthResponse?> signInWithBiometrics() async {
    final creds = await _getSavedCredentials();
    if (creds == null) return null;

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: creds['email']!,
        password: creds['password']!,
      );
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Biometric sign in failed: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _secureStorage.delete(key: 'saved_email');
    await _secureStorage.delete(key: 'saved_password');
    notifyListeners();
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
