// lib/main.dart
import 'package:flutter/material.dart';
import 'presentation/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LegalMetrologyInspectorApp());
}

class LegalMetrologyInspectorApp extends StatelessWidget {
  const LegalMetrologyInspectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legal Metrology LMO Edge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Manrope', // Distinctive typography (banning Inter, Roboto, Arial, Helvetica)
        scaffoldBackgroundColor: const Color(0xFF08090C), // Deep Void Charcoal
        primaryColor: const Color(0xFF0080FF), // Flat high-contrast Cobalt Cyan
        cardColor: const Color(0xFF101318),
        dividerColor: const Color(0xFF222733),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0080FF),
          secondary: Color(0xFF00C853), // Flat Signal Green
          surface: Color(0xFF101318),
          error: Color(0xFFD50000), // Flat Signal Red
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF101318),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: const CardTheme(
          color: Color(0xFF101318),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)), // Sharp geometry
            side: BorderSide(color: Color(0xFF222733)),
          ),
        ),
        dialogTheme: const DialogTheme(
          backgroundColor: Color(0xFF101318),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)), // Sharp geometry
            side: BorderSide(color: Color(0xFF222733)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
