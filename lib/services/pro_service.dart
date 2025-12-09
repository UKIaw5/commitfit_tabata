import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class ProService {
  static final ProService _instance = ProService._internal();
  factory ProService() => _instance;
  ProService._internal();

  // Single source of truth for the entitlement identifier
  // Matches the identifier in RevenueCat dashboard
  static const String proEntitlementId = 'GitFit Pro';

  /// Initialize RevenueCat listener
  void init(void Function(CustomerInfo) onUpdate) {
    Purchases.addCustomerInfoUpdateListener(onUpdate);
  }

  /// Check if user is Pro from CustomerInfo
  bool isPro(CustomerInfo info) {
    return info.entitlements.active.containsKey(proEntitlementId);
  }

  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  Future<bool> purchasePro() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (kDebugMode) {
        print('[ProService] Offerings: ${offerings.all.keys}');
      }

      final offering = offerings.current ?? offerings.all['default'];
      if (offering == null) {
        if (kDebugMode) print('[ProService] No offering found');
        return false;
      }

      final package = offering.lifetime ?? offering.availablePackages.firstOrNull;
      if (package == null) {
        if (kDebugMode) print('[ProService] No package found');
        return false;
      }

      if (kDebugMode) {
        print('[ProService] Purchasing package: ${package.identifier}');
      }

      final info = await Purchases.purchasePackage(package);
      return isPro(info);
    } catch (e) {
      if (kDebugMode) print('[ProService] Purchase failed: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return isPro(info);
    } catch (e) {
      if (kDebugMode) print('[ProService] Restore failed: $e');
      return false;
    }
  }
}
