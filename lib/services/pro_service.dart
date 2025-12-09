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
      debugPrint('[IAP] offerings keys: ${offerings.all.keys}');
      debugPrint('[IAP] current offering: ${offerings.current?.identifier}');

      final offering = offerings.current ?? offerings.all['default'];
      if (offering == null) {
        debugPrint('[IAP] No offering found. Available keys: ${offerings.all.keys}');
        return false;
      }

      final package = offering.lifetime ?? offering.availablePackages.firstOrNull;
      debugPrint('[IAP] selected package: ${package?.identifier}');
      debugPrint('[IAP] selected product: ${package?.storeProduct.identifier}');

      if (package == null) {
        debugPrint('[IAP] No package found in offering');
        return false;
      }

      final info = await Purchases.purchasePackage(package);
      _updateProStatus(info);
      debugPrint('[IAP] purchase success: ${info.entitlements.active.keys}');
      return isPro;
    } catch (e) {
      debugPrint('[IAP] purchase error: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      _updateProStatus(info);
      debugPrint('[IAP] restore success: ${info.entitlements.active.keys}');
      return isPro;
    } catch (e) {
      debugPrint('[IAP] Restore failed: $e');
      return false;
    }
  }
}
