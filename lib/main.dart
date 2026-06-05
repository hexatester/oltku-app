import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oltku/l10n/app_localizations.dart';
import 'package:oltku/screens/olt_list_view.dart';

// Global locale notifier so any widget can switch the language.
final ValueNotifier<Locale> appLocale = ValueNotifier(const Locale('id'));

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'OLT ONU Dashboard',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: const [
            Locale('id'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F0C1B),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              secondary: Color(0xFF06B6D4),
              surface: Color(0xFF1E1B2E),
              error: Color(0xFFEF4444),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1B2E),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              titleLarge: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            useMaterial3: true,
          ),
          home: const OltListView(),
        );
      },
    );
  }
}
