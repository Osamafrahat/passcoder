import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/login_screen.dart';
import '../features/passwords/password_list_screen.dart';
import '../features/passwords/password_form_screen.dart';
import '../features/notes/notes_list_screen.dart';
import '../features/notes/note_form_screen.dart';
import '../features/cards/cards_list_screen.dart';
import '../features/cards/card_form_screen.dart';
import '../features/generator/password_generator_screen.dart';
import '../features/health/password_health_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/trash/trash_bin_screen.dart';
import '../core/theme/theme_service.dart';
import '../core/services/auto_lock_service.dart';

class PassCoderApp extends StatelessWidget {
  const PassCoderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    return MaterialApp(
      title: 'PassCoder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1), brightness: Brightness.light),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5FA),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1), brightness: Brightness.dark),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      themeMode: themeService.themeMode,
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/?')) return MaterialPageRoute(builder: (_) => const AuthGate());
        return null;
      },
      onUnknownRoute: (settings) => MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _authenticated = false;
  bool _biometricFailed = false;
  bool _pendingBiometric = false;
  bool _checked = false;
  StreamSubscription<AuthState>? _authSubscription;
  DateTime? _backgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final autoLock = context.read<AutoLockService>();
    if (state == AppLifecycleState.paused) {
      _backgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed && _authenticated) {
      if (_backgroundTime != null && autoLock.timeoutMinutes > 0) {
        final elapsed = DateTime.now().difference(_backgroundTime!).inMinutes;
        if (elapsed >= autoLock.timeoutMinutes) {
          autoLock.lockNow();
          setState(() { _authenticated = false; _biometricFailed = false; });
        }
      }
      _backgroundTime = null;
    }
  }

  void _listenAuth() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && !_checked) {
        _checked = true;
        _handleSession(session);
      } else if (session == null && !_isLoading) {
        setState(() { _authenticated = false; _biometricFailed = false; });
      }
    });

    final session = _supabase.auth.currentSession;
    if (session != null) {
      _handleSession(session);
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (!_checked && mounted) {
          _checked = true;
          final s = _supabase.auth.currentSession;
          if (s != null) {
            _handleSession(s);
          } else {
            setState(() { _isLoading = false; _authenticated = false; });
          }
        }
      });
    }
  }

  Future<void> _handleSession(Session session) async {
    if (kIsWeb) {
      setState(() { _isLoading = false; _authenticated = true; });
      return;
    }

    final hasSaved = await _hasSavedCredentials();
    final biometricsAvailable = await _isBiometricsAvailable();

    if (hasSaved && biometricsAvailable) {
      _pendingBiometric = true;
      setState(() { _isLoading = false; });
      Future.delayed(const Duration(milliseconds: 500), _triggerBiometric);
    } else {
      setState(() { _isLoading = false; _authenticated = true; });
    }
  }

  Future<void> _triggerBiometric() async {
    if (!_pendingBiometric || !mounted) return;
    _pendingBiometric = false;
    final success = await _authenticateWithBiometrics();
    if (success) {
      setState(() { _authenticated = true; });
      context.read<AutoLockService>().resetTimer();
    } else {
      setState(() { _authenticated = false; _biometricFailed = true; });
    }
  }

  Future<bool> _hasSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('has_saved_credentials') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isBiometricsAvailable() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canAuth && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access PassCoder',
        options: const AuthenticationOptions(stickyAuth: false, biometricOnly: false, useErrorDialogs: true),
      );
    } catch (_) {
      return false;
    }
  }

  void _retryBiometric() async {
    _pendingBiometric = true;
    Future.delayed(const Duration(milliseconds: 300), _triggerBiometric);
  }

  void _usePassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('has_saved_credentials');
    await _supabase.auth.signOut();
    setState(() { _authenticated = false; _biometricFailed = false; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_authenticated) {
      if (_biometricFailed) {
        return _BiometricLockScreen(onRetry: _retryBiometric, onUsePassword: _usePassword);
      }
      return const LoginScreen();
    }
    return const HomeScreen();
  }
}

class _BiometricLockScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onUsePassword;

  const _BiometricLockScreen({required this.onRetry, required this.onUsePassword});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7), theme.colorScheme.secondary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.fingerprint, size: 72, color: Colors.white),
              ),
              const SizedBox(height: 28),
              const Text('Authentication Required', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Use your fingerprint or PIN to continue', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15)),
              const SizedBox(height: 48),
              SizedBox(
                width: 220, height: 54,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.fingerprint, size: 24),
                  label: const Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: onUsePassword, child: const Text('Use Password Instead', style: TextStyle(color: Colors.white70, fontSize: 14))),
            ]),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _reloadTrigger = 0;

  final _titles = const ['Passwords', 'Notes', 'Cards', 'Generator'];
  final _icons = const [Icons.lock_outline, Icons.note_alt_outlined, Icons.credit_card_outlined, Icons.password_outlined];
  final _selectedIcons = const [Icons.lock, Icons.note_alt, Icons.credit_card, Icons.password];

  @override
  void initState() {
    super.initState();
    context.read<AutoLockService>().startTimer();
  }

  void _onLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('has_saved_credentials');
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  void _onFabPressed() {
    Widget? form;
    switch (_currentIndex) {
      case 0: form = const PasswordFormScreen(); break;
      case 1: form = const NoteFormScreen(); break;
      case 2: form = const CardFormScreen(); break;
    }
    if (form != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => form!)).then((_) {
        setState(() => _reloadTrigger++);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (_currentIndex < 3)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              itemBuilder: (_) => [
                if (_currentIndex == 0) ...[
                  const PopupMenuItem(value: 'health', child: Row(children: [Icon(Icons.health_and_safety, size: 18), SizedBox(width: 8), Text('Password Health')])),
                  const PopupMenuItem(value: 'trash', child: Row(children: [Icon(Icons.delete_outline, size: 18), SizedBox(width: 8), Text('Trash Bin')])),
                ],
                const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings, size: 18), SizedBox(width: 8), Text('Settings')])),
                const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, size: 18, color: Colors.red), SizedBox(width: 8), Text('Sign Out', style: TextStyle(color: Colors.red))])),
              ],
              onSelected: (v) {
                if (v == 'logout') _onLogout();
                else if (v == 'settings') Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen(
                  themeService: context.read<ThemeService>(),
                  autoLockService: context.read<AutoLockService>(),
                )));
                else if (v == 'health' || v == 'trash') Navigator.push(context, MaterialPageRoute(builder: (_) =>
                  v == 'health' ? const PasswordHealthScreen() : const TrashBinScreen()));
              },
            ),
        ],
      ),
      floatingActionButton: _currentIndex < 3
          ? FloatingActionButton.extended(
              heroTag: 'fab_main',
              onPressed: _onFabPressed,
              icon: const Icon(Icons.add),
              label: Text('Add ${_titles[_currentIndex].substring(0, _titles[_currentIndex].length - 1)}'),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          PasswordListScreen(onLogout: _onLogout, reloadTrigger: _reloadTrigger),
          NotesListScreen(onLogout: _onLogout, reloadTrigger: _reloadTrigger),
          CardsListScreen(onLogout: _onLogout, reloadTrigger: _reloadTrigger),
          const PasswordGeneratorScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 70,
        indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        destinations: List.generate(4, (i) => NavigationDestination(
          icon: Icon(_icons[i], color: theme.colorScheme.onSurfaceVariant),
          selectedIcon: Icon(_selectedIcons[i], color: theme.colorScheme.primary),
          label: _titles[i],
        )),
      ),
    );
  }
}
