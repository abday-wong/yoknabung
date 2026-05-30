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
  const YokNabungApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<SavingsProvider>(context).isDarkMode;
    final scaffoldBgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFFFDE7);
    final textColor = isDark ? Colors.white : const Color(0xFF111111);

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
        brightness: isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: scaffoldBgColor,
        fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
        textTheme: TextTheme(
          displayLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: textColor),
          displayMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: textColor),
          displaySmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: textColor),
          headlineLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: textColor),
          headlineMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: textColor),
          headlineSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: textColor),
          titleLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 18, color: textColor),
          titleMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 16, color: textColor),
          titleSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 14, color: textColor),
          bodyLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: textColor),
          bodyMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: textColor),
          bodySmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w500, color: textColor),
          labelLarge: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: textColor),
          labelMedium: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: textColor),
          labelSmall: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: textColor),
        ),
        
        // Remove material shadows
        shadowColor: Colors.transparent,
        appBarTheme: AppBarTheme(
          backgroundColor: scaffoldBgColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
