import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State notifier managing Pro subscription / lifetime unlock state,
/// persistent SharedPreferences caching, offline gift code redemption,
/// and RevenueCat cloud entitlements.
class ProUserNotifier extends StateNotifier<bool> {
  static const String proEntitlementId = 'pro_access';

  // SharedPreferences Keys
  static const String spKeyProUnlocked = 'shelfcraft_is_pro_unlocked';
  static const String spKeyProSource = 'shelfcraft_pro_unlock_source';
  static const String spKeyRedeemedCode = 'shelfcraft_pro_redeemed_code';

  /// Standard curated promo/gift codes accepted offline
  static const Set<String> validGiftCodes = {
    'GIFT-READSANCTUARY',
    'GIFT-SHELFCRAFT',
    'BOOKWORM-PRO',
    'SLOWREAD-VIP',
    'READMORE-2026',
    'COMMUNITY-GIFT',
    'PRO-LIFETIME-GIFT',
    'READSANCTUARY-VIP',
    'SHELFCRAFT-VIP',
  };

  /// Creator master passkeys
  static const Set<String> creatorPasskeys = {
    'READSANCTUARY-CREATOR',
    'SHELFCRAFT-CREATOR',
    'CREATOR-KEY-2026',
    'DEV-UNLOCKED',
  };

  String? _unlockSource;
  String? _redeemedCode;

  String? get unlockSource => _unlockSource;
  String? get redeemedCode => _redeemedCode;

  ProUserNotifier({bool initialPro = false}) : super(initialPro) {
    _loadSavedProStatus();
  }

  /// Restores persistent Pro status from SharedPreferences on launch.
  Future<void> _loadSavedProStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isUnlocked = prefs.getBool(spKeyProUnlocked) ?? false;
      _unlockSource = prefs.getString(spKeyProSource);
      _redeemedCode = prefs.getString(spKeyRedeemedCode);

      if (isUnlocked) {
        state = true;
      }
    } catch (_) {}
  }

  /// Validates and redeems a promotional or gift voucher code.
  /// If valid, permanently persists Pro status without requiring payment.
  Future<bool> redeemGiftCode(String rawCode) async {
    final cleanCode = rawCode.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;

    final isValidCode = validGiftCodes.contains(cleanCode) ||
        creatorPasskeys.contains(cleanCode) ||
        _isValidPatternCode(cleanCode);

    if (isValidCode) {
      final source = creatorPasskeys.contains(cleanCode)
          ? 'creator_passkey'
          : 'gift_code';
      await _persistProStatus(true, source: source, code: cleanCode);
      state = true;
      return true;
    }

    return false;
  }

  /// Pattern-based matching for generated gift codes (e.g., 'GIFT-XXXXX', 'PRO-XXXXX')
  bool _isValidPatternCode(String code) {
    if ((code.startsWith('GIFT-') || code.startsWith('PRO-') || code.startsWith('VIP-')) &&
        code.length >= 8) {
      return true;
    }
    return false;
  }

  /// Persists Pro status into SharedPreferences.
  Future<void> _persistProStatus(bool isPro,
      {String source = 'in_app_purchase', String? code}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(spKeyProUnlocked, isPro);
      if (isPro) {
        _unlockSource = source;
        _redeemedCode = code;
        await prefs.setString(spKeyProSource, source);
        if (code != null) {
          await prefs.setString(spKeyRedeemedCode, code);
        }
      } else {
        _unlockSource = null;
        _redeemedCode = null;
        await prefs.remove(spKeyProSource);
        await prefs.remove(spKeyRedeemedCode);
      }
    } catch (_) {}
  }

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

  /// Purchases a selected offering package via RevenueCat.
  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaseResult =
          await Purchases.purchase(PurchaseParams.package(package));
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

  /// Debug or test override to toggle Pro status with persistence.
  Future<void> setDebugProOverride(bool isPro,
      {String source = 'debug_override'}) async {
    await _persistProStatus(isPro, source: source);
    state = isPro;
  }

  /// Completely resets Pro status back to free tier.
  Future<void> resetProStatus() async {
    await _persistProStatus(false);
    state = false;
  }

  bool _updateFromCustomerInfo(CustomerInfo customerInfo) {
    final hasPro =
        customerInfo.entitlements.active.containsKey(proEntitlementId);
    if (hasPro) {
      _persistProStatus(true, source: 'revenuecat');
      state = true;
      return true;
    }
    // If not in RevenueCat, preserve gift code / persistent unlock if present
    return state;
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
