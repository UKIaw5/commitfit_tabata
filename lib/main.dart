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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    debugPrint("AdMob initialization failed: $e");
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
        final baseScheme = ColorScheme.fromSeed(
          seedColor: Color(seedColorValue),
          brightness: Brightness.light,
        );
        final colorScheme = baseScheme.copyWith(
          background: const Color(0xFFF2F5F0),
          surface: Colors.white,
        );

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

