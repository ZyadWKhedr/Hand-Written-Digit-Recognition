import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/digit_recognition_provider.dart';
import 'views/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HandwrittenDigitApp());
}

/// Root application widget styled following Apple Human Interface Guidelines (HIG).
///
/// Completely stateless and under 200 lines.
class HandwrittenDigitApp extends StatelessWidget {
  const HandwrittenDigitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DigitRecognitionProvider()..initialize(),
      child: MaterialApp(
        title: 'ONNX Digit Recognition',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000000),
          colorScheme: const ColorScheme.dark(
            primary: CupertinoColors.activeBlue,
            surface: Color(0xFF18181F),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF000000),
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
