import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const TradeSignalsApp());
}

class TradeSignalsApp extends StatelessWidget {
  const TradeSignalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Page/surface/ink tokens straight from the shared reference palette
    // (same one the web dashboard uses), so both apps read as one system.
    const lightScheme = ColorScheme.light(
      surface: Color(0xFFFCFCFB),
      onSurface: Color(0xFF0B0B0B),
      onSurfaceVariant: Color(0xFF52514E),
      primary: Color(0xFF0B0B0B),
      onPrimary: Color(0xFFF9F9F7),
    );
    const darkScheme = ColorScheme.dark(
      surface: Color(0xFF1A1A19),
      onSurface: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFFC3C2B7),
      primary: Color(0xFFFFFFFF),
      onPrimary: Color(0xFF0D0D0D),
    );

    return MaterialApp(
      title: 'Trade Signals',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: const Color(0xFFF9F9F7),
        dividerColor: const Color(0x1A0B0B0B),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        dividerColor: const Color(0x1AFFFFFF),
        fontFamily: 'Roboto',
      ),
      home: const DashboardScreen(),
    );
  }
}
