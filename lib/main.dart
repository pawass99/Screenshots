import 'package:flutter/material.dart';
import 'package:screenshots/features/auth/presentation/splash_page.dart';
import 'package:screenshots/theme/screenshot_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL dan SUPABASE_ANON_KEY harus diisi lewat --dart-define.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ScreenShot',
      theme: ScreenshotTheme.dark(),
      home: const SplashPage(),
    );
  }
}
