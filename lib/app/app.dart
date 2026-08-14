import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/login_screen.dart';
import '../features/passwords/password_list_screen.dart';
import '../features/notes/notes_list_screen.dart';
import '../features/cards/cards_list_screen.dart';
import '../features/generator/password_generator_screen.dart';
import '../features/passwords/password_form_screen.dart';
import '../features/notes/note_form_screen.dart';
import '../features/cards/card_form_screen.dart';

class PassCoderApp extends StatelessWidget {
  const PassCoderApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      themeMode: ThemeMode.system,
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/?')) return MaterialPageRoute(builder: (_) => const AuthGate());
        return null;
      },
      onUnknownRoute: (settings) => MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) return const HomeScreen();
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.data?.session != null) return const HomeScreen();
        return const LoginScreen();
      },
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

  final _titles = const ['Passwords', 'Notes', 'Cards', 'Generator'];
  final _fabLabels = const ['Add Password', 'Add Note', 'Add Card', ''];
  final _icons = const [Icons.lock_outline, Icons.note_alt_outlined, Icons.credit_card_outlined, Icons.password_outlined];
  final _selectedIcons = const [Icons.lock, Icons.note_alt, Icons.credit_card, Icons.password];

  void _onFabPressed() {
    switch (_currentIndex) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordFormScreen()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteFormScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CardFormScreen()));
        break;
    }
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
      await Supabase.instance.client.auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screens = [
      PasswordListScreen(),
      NotesListScreen(),
      CardsListScreen(),
      const PasswordGeneratorScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: screens[_currentIndex],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: Material(
              color: theme.colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _onLogout,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.logout_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _currentIndex < 3
          ? FloatingActionButton.extended(
              onPressed: _onFabPressed,
              icon: const Icon(Icons.add),
              label: Text(_fabLabels[_currentIndex]),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: NavigationBar(
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
      ),
    );
  }
}
