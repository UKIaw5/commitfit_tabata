import 'package:flutter/foundation.dart';
import '../services/pro_service.dart';

class ProState extends ChangeNotifier {
  bool _isPro = false;
  bool get isPro => _isPro;

  final ProService _proService = ProService();

  Future<void> init() async {
    // Listen to updates from RevenueCat
    _proService.init((info) {
      final newStatus = _proService.isPro(info);
      if (newStatus != _isPro) {
        _isPro = newStatus;
        notifyListeners();
      }
    });

    // Initial check
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final info = await _proService.getCustomerInfo();
      final newStatus = _proService.isPro(info);
      if (newStatus != _isPro) {
        _isPro = newStatus;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ProState] refresh failed: $e');
      }
    }
  }
}
