import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// State notifier managing Pro subscription / lifetime unlock state.
class ProUserNotifier extends StateNotifier<bool> {
  static const String proEntitlementId = 'pro_access';

  ProUserNotifier() : super(false);

  /// Initializes RevenueCat with the platform API key.
  Future<void> initialize({required String apiKey}) async {
    try {
      await Purchases.configure(PurchasesConfiguration(apiKey));
      await checkProStatus();

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateFromCustomerInfo(customerInfo);
      });
    } catch (_) {}
  }

  /// Checks active entitlements from RevenueCat CustomerInfo.
  Future<bool> checkProStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _updateFromCustomerInfo(customerInfo);
    } catch (_) {
      return state;
    }
  }

  /// Purchases a selected offering package.
  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchase(PurchaseParams.package(package));
      return _updateFromCustomerInfo(purchaseResult.customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        // Log or handle error
      }
      return state;
    } catch (_) {
      return state;
    }
  }

  /// Restores previous App Store / Google Play purchases.
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return _updateFromCustomerInfo(customerInfo);
    } catch (_) {
      return state;
    }
  }

  /// Debug or test override to toggle Pro status without network calls.
  void setDebugProOverride(bool isPro) {
    state = isPro;
  }

  bool _updateFromCustomerInfo(CustomerInfo customerInfo) {
    final hasPro = customerInfo.entitlements.active.containsKey(proEntitlementId);
    state = hasPro;
    return hasPro;
  }
}

final isProUserProvider = StateNotifierProvider<ProUserNotifier, bool>((ref) {
  return ProUserNotifier();
});

/// Helper defining free vs Pro feature gating rules according to Section 1 of requirement.md.
class ProFeatureGate {
  /// The 3 default background wall themes included free.
  static const freeWallThemes = {'warm_cream', 'soft_sage', 'light_grey'};

  /// Free shelf props.
  static const freeProps = {'gap', 'bookend_brass'};

  /// Checks if a wall background theme requires Pro membership.
  static bool requiresProForWallTheme(String wallThemeId, bool isProUser) {
    if (isProUser) return false;
    return !freeWallThemes.contains(wallThemeId);
  }

  /// Checks if a decorative prop requires Pro membership.
  static bool requiresProForProp(String propId, bool isProUser) {
    if (isProUser) return false;
    return !freeProps.contains(propId);
  }

  /// Google Drive cloud backup is a Pro feature.
  /// (Local .zip and CSV export/import remain 100% free for everyone).
  static bool canUseGoogleDriveSync(bool isProUser) {
    return isProUser;
  }
}
