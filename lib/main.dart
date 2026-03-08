import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //supabase connection
  await Supabase.initialize(
    url: 'https://cikciqgrxbphnylebzue.supabase.co',
    anonKey: 'sb_publishable_MS5dhMvJ43KF1EEU37BMQA_-fzgtiUH',
  );

  // make sure supabase is connected
  try {
    final supabase = Supabase.instance.client;
    await supabase.from('user').select().limit(1);
    print('Supabase connected!');
  } catch (e) {
    print('Supabase connection failed: $e');
  }

  runApp(const SmartSecureApp());
}

class SmartSecureApp extends StatelessWidget {
  const SmartSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSecure',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B6FE8),
          primary: const Color(0xFF3B6FE8),
        ),
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
