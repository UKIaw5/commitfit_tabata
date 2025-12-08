import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class ProService {
  static final ProService _instance = ProService._internal();
  factory ProService() => _instance;
  ProService._internal();

  final ValueNotifier<bool> isProNotifier = ValueNotifier(false);
  bool get isPro => isProNotifier.value;

  Future<void> init() async {
    try {
      // Listen to customer info updates
      Purchases.addCustomerInfoUpdateListener((info) {
        _updateProStatus(info);
      });

      // Initial check
      final info = await Purchases.getCustomerInfo();
      _updateProStatus(info);
    } catch (e) {
      debugPrint('ProService init failed: $e');
      // Default to free on error
      isProNotifier.value = false;
    }
  }

  void _updateProStatus(CustomerInfo info) {
    // Check for "pro" entitlement
    // Adjust "pro" to match your actual entitlement identifier in RevenueCat
    final entitlement = info.entitlements.all['pro'];
    final isActive = entitlement?.isActive ?? false;
    
    if (isActive != isProNotifier.value) {
      isProNotifier.value = isActive;
      debugPrint('Pro status updated: $isActive');
    }
  }

  Future<bool> purchasePro() async {
    try {
      final offerings = await Purchases.getOfferings();
      // Use "default" offering and "lifetime" package as configured in RevenueCat
      final offering = offerings.current ?? offerings.all['default'];
      
      if (offering == null) {
        debugPrint('No offering found');
        return false;
      }

      // Look for lifetime package, fallback to first available if needed
      final package = offering.lifetime ?? offering.availablePackages.firstOrNull;

      if (package == null) {
        debugPrint('No package found');
        return false;
      }

      final info = await Purchases.purchasePackage(package);
      _updateProStatus(info);
      return isPro;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _updateProStatus(info);
    } catch (e) {
      debugPrint('Restore failed: $e');
    }
  }
}
