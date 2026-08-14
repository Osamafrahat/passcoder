import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/config/supabase_config.dart';
import 'core/auth/auth_service.dart';
import 'core/encryption/encryption_service.dart';
import 'core/theme/theme_service.dart';
import 'core/services/auto_lock_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => EncryptionService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => AutoLockService()),
      ],
      child: const PassCoderApp(),
    ),
  );
}
