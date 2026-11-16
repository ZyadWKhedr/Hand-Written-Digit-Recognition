import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/digit_recognition_provider.dart';
import 'views/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HandwrittenDigitApp());
}

/// Root application widget.
///
/// Sets up the global [DigitRecognitionProvider] and configures the Material 3 theme.
/// Completely stateless and under 200 lines.
class HandwrittenDigitApp extends StatelessWidget {
  const HandwrittenDigitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DigitRecognitionProvider()..initialize(),
      child: MaterialApp(
        title: 'ONNX Handwritten Digit Recognition',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
            surface: const Color(0xFF141419),
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFF1E1E26),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF141419),
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
        ),
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
