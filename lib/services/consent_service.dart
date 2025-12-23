import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentService {
  static final ConsentService instance = ConsentService._internal();
  factory ConsentService() => instance;
  ConsentService._internal();

  bool _isMobileAdsInitialized = false;

  /// Initialize consent and ads
  Future<void> initialize() async {
    // Create ConsentRequestParameters
    // For testing, we can use ConsentDebugSettings
    ConsentDebugSettings? debugSettings;
    
    // UNCOMMENT FOR TESTING EEA GEOGRAPHY
    // debugSettings = ConsentDebugSettings(
    //   debugGeography: DebugGeography.debugGeographyEea,
    //   testIdentifiers: ['TEST-DEVICE-HASHED-ID'], // Add your test device ID if needed
    // );

    final params = ConsentRequestParameters(
      consentDebugSettings: debugSettings,
    );

    // Request consent info update
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // Success: Load and show consent form if required
        await _loadAndShowConsentForm();
      },
      (FormError error) {
        debugPrint('Error updating consent info: ${error.message}');
        // On error, try to initialize ads anyway (if possible)
        _initializeMobileAds();
      },
    );
  }

  Future<void> _loadAndShowConsentForm() async {
    ConsentForm.loadAndShowConsentFormIfRequired(
      (FormError? error) {
        if (error != null) {
          debugPrint('Error showing consent form: ${error.message}');
        }
        // Check if we can request ads
        _initializeMobileAds();
      },
    );
  }

  Future<void> _initializeMobileAds() async {
    if (_isMobileAdsInitialized) return;

    if (await ConsentInformation.instance.canRequestAds()) {
      try {
        await MobileAds.instance.initialize();
        _isMobileAdsInitialized = true;
        debugPrint('MobileAds initialized');
      } catch (e) {
        debugPrint('MobileAds init failed: $e');
      }
    } else {
      debugPrint('Cannot request ads (consent not granted)');
    }
  }

  /// Check if privacy options (revocation) are required
  Future<bool> isPrivacyOptionsRequired() async {
    final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  /// Show privacy options form
  Future<void> showPrivacyOptionsForm(BuildContext context) async {
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) {
        debugPrint('Error showing privacy options: ${error.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.message}')),
        );
      } else {
        // User might have changed consent status
        _initializeMobileAds();
      }
    });
  }
}
