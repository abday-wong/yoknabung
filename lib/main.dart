import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/savings_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SavingsProvider(),
      child: const YokNabungApp(),
    ),
  );
}

class YokNabungApp extends StatelessWidget {
  const YokNabungApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YokNabung',
      debugShowCheckedModeBanner: false,
      
      // Indonesian Localization Setup
      supportedLocales: const [
        Locale('id', 'ID'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('id', 'ID'),

      // Neo-Brutalist Theme Styling
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFFFDE7), // Warm cream background
        fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
        textTheme: TextTheme(
          displayLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
          displayMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
          displaySmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
          headlineLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
          headlineMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
          headlineSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
          titleLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 18, color: const Color(0xFF111111)),
          titleMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 16, color: const Color(0xFF111111)),
          titleSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 14, color: const Color(0xFF111111)),
          bodyLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: const Color(0xFF111111)),
          bodyMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: const Color(0xFF111111)),
          bodySmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: const Color(0xFF111111)),
          labelLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
          labelMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
          labelSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: const Color(0xFF111111)),
        ),
        
        // Remove material shadows
        shadowColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          color: Color(0xFFFFFDE7),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF111111)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
