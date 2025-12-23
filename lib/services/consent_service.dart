import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentService {
  static final ConsentService instance = ConsentService._internal();
  factory ConsentService() => instance;
  ConsentService._internal();

  final ValueNotifier<bool> canRequestAdsNotifier = ValueNotifier(false);
  final ValueNotifier<bool> mobileAdsInitializedNotifier = ValueNotifier(false);
  bool _isMobileAdsInitialized = false;

  ConsentRequestParameters _getParams() {
    ConsentDebugSettings? debugSettings;
    
    // DEBUG-ONLY: Force EEA geography for testing
    if (kDebugMode) {
      debugSettings = ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
        testIdentifiers: ['B3EEABB8EE11C2BE770B684D95219ECB'],
      );
    }

    return ConsentRequestParameters(
      consentDebugSettings: debugSettings,
    );
  }

  /// Initialize consent and ads
  Future<void> initialize() async {
    final params = _getParams();

    // Request consent info update
    if (kDebugMode) {
      debugPrint('[UMP] Requesting consent info update...');
      if (params.consentDebugSettings != null) {
        debugPrint('[UMP] DebugGeography: ${params.consentDebugSettings!.debugGeography}');
      }
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // Log status
        final status = await ConsentInformation.instance.getConsentStatus();
        final privacyStatus = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
        final canRequest = await ConsentInformation.instance.canRequestAds();
        
        canRequestAdsNotifier.value = canRequest;
        
        // Minimal production logging
        debugPrint('[UMP] Update Success. canRequestAds: $canRequest');
        if (kDebugMode) {
          debugPrint('[UMP] ConsentStatus: $status');
          debugPrint('[UMP] PrivacyOptionsRequirementStatus: $privacyStatus');
        }

        // Success: Load and show consent form if required
        await _loadAndShowConsentForm();
      },
      (FormError error) {
        debugPrint('[UMP] Error updating consent info: ${error.message}');
        // On error, try to initialize ads anyway (if possible)
        _initializeMobileAds();
      },
    );
  }

  Future<void> _loadAndShowConsentForm() async {
    ConsentForm.loadAndShowConsentFormIfRequired(
      (FormError? error) async {
        if (error != null) {
          debugPrint('[UMP] Error showing consent form: ${error.message}');
        } else {
          if (kDebugMode) {
            debugPrint('[UMP] Consent form dismissed (or not required)');
          }
        }
        
        // Refresh info after form
        await _refreshConsentInfo();

        // Check if we can request ads
        _initializeMobileAds();
      },
    );
  }

  Future<void> _refreshConsentInfo() async {
    final completer = Completer<void>();
    final params = _getParams();
    
    ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          final status = await ConsentInformation.instance.getConsentStatus();
          final privacyStatus = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
          final canAds = await ConsentInformation.instance.canRequestAds();
          
          canRequestAdsNotifier.value = canAds;
          
          debugPrint('[UMP] Refreshed. canRequestAds: $canAds');
          if (kDebugMode) {
            debugPrint('[UMP] ConsentStatus: $status');
            debugPrint('[UMP] PrivacyOptionsRequirementStatus: $privacyStatus');
          }
          
          completer.complete();
        },
        (error) {
          debugPrint('[UMP] Error refreshing consent info: ${error.message}');
          completer.complete();
        }
    );
    
    return completer.future;
  }

  Future<void> _initializeMobileAds() async {
    if (_isMobileAdsInitialized) {
      mobileAdsInitializedNotifier.value = true;
      return;
    }

    // Strict check: Only initialize if canRequestAds is true
    if (await ConsentInformation.instance.canRequestAds()) {
      try {
        await MobileAds.instance.initialize();
        _isMobileAdsInitialized = true;
        mobileAdsInitializedNotifier.value = true;
        debugPrint('[ADS] MobileAds initialized');
      } catch (e) {
        debugPrint('[ADS] MobileAds init failed: $e');
      }
    } else {
      debugPrint('[ADS] blocked: canRequestAds=false');
    }
  }

  /// Check if privacy options (revocation) are required
  Future<bool> isPrivacyOptionsRequired() async {
    final status = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  /// Show privacy options form
  Future<void> showPrivacyOptionsForm(BuildContext context) async {
    ConsentForm.showPrivacyOptionsForm((FormError? error) async {
      if (error != null) {
        debugPrint('Error showing privacy options: ${error.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${error.message}')),
        );
      } else {
        // User might have changed consent status
        await _refreshConsentInfo();
        _initializeMobileAds();
      }
    });
  }

  /// Reset consent state (Debug only)
  Future<void> reset() async {
    if (!kDebugMode) return; // Guard against production usage
    await ConsentInformation.instance.reset();
    _isMobileAdsInitialized = false;
    canRequestAdsNotifier.value = false;
    mobileAdsInitializedNotifier.value = false;
    debugPrint('[UMP] Consent info reset');
  }
}
