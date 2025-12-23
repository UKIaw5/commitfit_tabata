import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/graph_screen.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// ...

import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'state/pro_state.dart';
import 'config/app_settings.dart';
import 'services/consent_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  try {
    // Initialize Consent and Ads
    await ConsentService.instance.initialize();
  } catch (e) {
    debugPrint("Consent/AdMob initialization failed: $e");
  }
  
  // Initialize RevenueCat
  // TODO: Replace with your actual API key
  const androidRevenueCatApiKey = "goog_NmiQfzdeVrNdheCLyQXTCtoYiVN";
  
  try {
    await Purchases.configure(PurchasesConfiguration(androidRevenueCatApiKey));
    // ProService init is handled by ProState
  } catch (e) {
    debugPrint("RevenueCat initialization failed: $e");
  }
  
  await WakelockPlus.enable();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProState()..init()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: AppSettings.loadThemeColor(),
      builder: (context, snapshot) {
        final seedColorValue = snapshot.data ?? 0xFF2EA043;
        final isMonochrome = seedColorValue == 0xFF171717;
        final isWhite = seedColorValue == 0xFFFFFFFF;
        final isYellow = seedColorValue == 0xFFFACC15;

        final baseScheme = ColorScheme.fromSeed(
          seedColor: Color(seedColorValue),
          brightness: (isMonochrome || isYellow) ? Brightness.dark : Brightness.light,
        );

        ColorScheme colorScheme;
        if (isMonochrome) {
          colorScheme = baseScheme.copyWith(
            background: const Color(0xFF171717), // Near-black
            surface: const Color(0xFF262626), // Slightly lighter
            onSurface: const Color(0xFFE5E5E5), // Light gray text
            primary: const Color(0xFF737373), // Neutral gray accent
            onPrimary: Colors.white,
          );
        } else if (isWhite) {
          colorScheme = baseScheme.copyWith(
            background: Colors.white,
            surface: const Color(0xFFF3F4F6), // Very light gray for cards/appbar
            onSurface: const Color(0xFF111827), // Dark gray text
            primary: const Color(0xFF1F2937), // Dark gray accent
            onPrimary: Colors.white,
            secondary: const Color(0xFF9CA3AF),
          );
        } else if (isYellow) {
          colorScheme = baseScheme.copyWith(
            background: const Color(0xFF1F2937), // Dark Gray
            surface: const Color(0xFF374151), // Lighter Dark Gray
            onSurface: const Color(0xFFF9FAFB), // White-ish text
            primary: const Color(0xFFFACC15), // Yellow
            onPrimary: Colors.black, // Black text on yellow
            secondary: const Color(0xFFF59E0B), // Amber
          );
        } else {
          // Default / Red / Blue (Light mode based)
          colorScheme = baseScheme.copyWith(
            background: const Color(0xFFF2F5F0),
            surface: Colors.white,
          );
        }

        return MaterialApp(
          title: 'GitFit',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorScheme,
            scaffoldBackgroundColor: colorScheme.background,
            appBarTheme: AppBarTheme(
              backgroundColor: colorScheme.surface,
              foregroundColor: colorScheme.onSurface,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary, width: 1.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: colorScheme.primary,
              contentTextStyle: TextStyle(color: colorScheme.onPrimary),
            ),
          ),
          home: const HomeScreen(),
          routes: {
            '/timer': (context) => const HomeScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/graph': (context) => const GraphScreen(),
          },
        );
      },
    );
  }
}

