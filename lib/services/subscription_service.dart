// lib/services/subscription_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the paywall should show and buy. Trial details come only from the
/// store, so the app never advertises a trial this user cannot receive.
class SubscriptionOffer {
  final ProductDetails product;
  final String recurringPrice;

  /// For example "3-day". Null when the store reports no free trial.
  final String? freeTrialLabel;

  const SubscriptionOffer({
    required this.product,
    required this.recurringPrice,
    this.freeTrialLabel,
  });
}

class PurchaseOutcome {
  final PurchaseStatus status;
  final String? message;

  const PurchaseOutcome(this.status, [this.message]);

  bool get grantsAccess =>
      status == PurchaseStatus.purchased || status == PurchaseStatus.restored;
}

class SubscriptionService {
  // --- Singleton ---
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Your product ID (Play Console / App Store Connect)
  static const String subscriptionId = 'tao_subscription_monthly';

  // Local entitlement cache flag
  static const String _entitledKey = 'entitled_premium';

  // Access for Google Play reviewers, who cannot make purchases. Only a hash
  // lives here because this repository is public. The code itself is in the
  // Play Console Sign in details declaration.
  static const String _reviewerAccessKey = 'reviewer_access';
  static const String _reviewerCodeHash =
      'a8c77c86ed43a6d26cdd87cc862c2e75abd070e0d2b40eeb9daa51ad8f58bb24';

  // Limits for store calls, so a stuck connection cannot hold up app launch.
  static const Duration _storeTimeout = Duration(seconds: 12);
  static const Duration _restoreSettle = Duration(milliseconds: 1500);

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  bool _isAvailable = false;
  bool _initialized = false;

  List<ProductDetails> _products = [];

  /// Why the store returned no subscription, for display on the paywall.
  String? storeIssue;
  final List<PurchaseDetails> _purchases = [];

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<void>? _entitlementArrived;

  final StreamController<PurchaseOutcome> _outcomes =
      StreamController<PurchaseOutcome>.broadcast();

  /// Purchase results as the store reports them. The paywall listens to this
  /// rather than polling for a result.
  Stream<PurchaseOutcome> get outcomes => _outcomes.stream;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Attach before any store call so no purchase update is missed.
      _purchaseSub ??= _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () => debugPrint('Purchase stream closed'),
        onError: (Object error) => debugPrint('Purchase stream error: $error'),
      );

      _isAvailable =
          await _inAppPurchase.isAvailable().timeout(_storeTimeout);
      if (!_isAvailable) {
        debugPrint('In-app purchases not available');
        _initialized = false; // allow a retry from the paywall
        return;
      }

      await _loadProducts();
    } catch (e) {
      debugPrint('Subscription service initialization failed: $e');
      _initialized = false; // allow a retry from the paywall
    }
  }

  static Future<void> ensureInitialized() async {
    await _instance.initialize();
  }

  // ---------------------------------------------------------------------------
  // Products
  // ---------------------------------------------------------------------------
  Future<void> _loadProducts() async {
    try {
      final response = await _inAppPurchase
          .queryProductDetails({subscriptionId}).timeout(_storeTimeout);

      _products = response.productDetails;
      storeIssue =
          _products.isEmpty ? await _describeMissingProduct(response) : null;
    } catch (e) {
      storeIssue = 'Store request failed: $e';
      debugPrint('Error loading products: $e');
    }
  }

  /// The plugin drops Play's response code when a product comes back empty,
  /// so ask Play again directly and report what it says.
  Future<String> _describeMissingProduct(ProductDetailsResponse response) async {
    final details = <String>[];
    if (!_isAvailable) details.add('billing not ready');
    final error = response.error;
    if (error != null) details.add('${error.code}: ${error.message}');

    final platform = InAppPurchasePlatform.instance;
    if (platform is InAppPurchaseAndroidPlatform) {
      try {
        final result = await platform.billingClientManager
            .runWithClient(
              (client) => client.queryProductDetails(
                productList: const [
                  ProductWrapper(
                    productId: subscriptionId,
                    productType: ProductType.subs,
                  ),
                ],
              ),
            )
            .timeout(_storeTimeout);
        final billing = result.billingResult;
        details.add(
          'Play ${billing.responseCode.name}'
          '${billing.debugMessage == null ? '' : ' (${billing.debugMessage})'}, '
          'found ${result.productDetailsList.length}, '
          'unfetched ${result.unfetchedProductList.length}',
        );
      } catch (e) {
        details.add('Play query failed: $e');
      }
    }

    return details.isEmpty ? 'No product returned' : details.join('; ');
  }

  /// The offer to show on the paywall, or null if the store has none.
  Future<SubscriptionOffer?> loadOffer() async {
    await initialize();

    // Play can briefly return nothing, so retry before giving up.
    for (var attempt = 1; _products.isEmpty && attempt <= 3; attempt++) {
      await _loadProducts();
      if (_products.isEmpty && attempt < 3) {
        await Future<void>.delayed(Duration(seconds: attempt));
      }
    }

    final matches = _products.where((p) => p.id == subscriptionId).toList();
    if (matches.isEmpty) return null;

    final playProducts = matches.whereType<GooglePlayProductDetails>().toList();
    if (playProducts.isNotEmpty) return _playOffer(playProducts);

    final appStoreProducts = matches.whereType<AppStoreProduct2Details>();
    if (appStoreProducts.isNotEmpty) {
      return _appStoreOffer(appStoreProducts.first);
    }

    // iOS 13-14 use the older StoreKit. The App Store purchase sheet still
    // shows any trial, so the paywall simply makes no trial claim here.
    return SubscriptionOffer(
      product: matches.first,
      recurringPrice: matches.first.price,
    );
  }

  /// Play returns one entry per base plan and offer, limited to the offers
  /// this user qualifies for. The first pricing phase of a trial offer is free,
  /// so the recurring price is taken from the last phase.
  SubscriptionOffer _playOffer(List<GooglePlayProductDetails> products) {
    SubscriptionOfferDetailsWrapper? detailsOf(GooglePlayProductDetails p) {
      final index = p.subscriptionIndex;
      final offers = p.productDetails.subscriptionOfferDetails;
      if (index == null || offers == null || index >= offers.length) {
        return null;
      }
      return offers[index];
    }

    bool hasFreeTrial(GooglePlayProductDetails p) {
      final phases = detailsOf(p)?.pricingPhases;
      return phases != null &&
          phases.length > 1 &&
          phases.first.priceAmountMicros == 0;
    }

    GooglePlayProductDetails chosen = products.first;
    for (final p in products) {
      if (detailsOf(p)?.offerId == null) chosen = p; // base plan as the default
    }
    for (final p in products) {
      if (hasFreeTrial(p)) {
        chosen = p;
        break;
      }
    }

    final phases = detailsOf(chosen)?.pricingPhases;
    return SubscriptionOffer(
      product: chosen,
      recurringPrice: phases?.last.formattedPrice ?? chosen.price,
      freeTrialLabel: hasFreeTrial(chosen)
          ? trialLabelFromIso8601(phases!.first.billingPeriod)
          : null,
    );
  }

  Future<SubscriptionOffer> _appStoreOffer(
    AppStoreProduct2Details product,
  ) async {
    String? trialLabel;
    try {
      final eligible = await SK2Product.isIntroductoryOfferEligible(product.id)
          .timeout(_storeTimeout);
      final offers = product.sk2Product.subscription?.promotionalOffers ??
          const <SK2SubscriptionOffer>[];
      if (eligible) {
        for (final offer in offers) {
          if (offer.type == SK2SubscriptionOfferType.introductory &&
              offer.paymentMode == SK2SubscriptionOfferPaymentMode.freeTrial) {
            trialLabel = _trialLabel(offer.period, offer.periodCount);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Could not read App Store trial details: $e');
    }

    return SubscriptionOffer(
      product: product,
      recurringPrice: product.price,
      freeTrialLabel: trialLabel,
    );
  }

  String? _trialLabel(SK2SubscriptionPeriod period, int periodCount) {
    final count = period.value * periodCount;
    switch (period.unit) {
      case SK2SubscriptionPeriodUnit.day:
        return '$count-day';
      case SK2SubscriptionPeriodUnit.week:
        return '$count-week';
      case SK2SubscriptionPeriodUnit.month:
        return '$count-month';
      case SK2SubscriptionPeriodUnit.year:
        return '$count-year';
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase / Restore
  // ---------------------------------------------------------------------------

  /// Opens the store purchase sheet. The result arrives through [outcomes].
  Future<void> purchaseSubscription(SubscriptionOffer offer) async {
    final started = await _inAppPurchase.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: offer.product),
    );
    if (!started) throw Exception('The store could not start the purchase.');
  }

  /// Unlocks the app on this device if [code] is the reviewer access code.
  Future<bool> redeemAccessCode(String code) async {
    final normalized = code.trim().toUpperCase();
    final hash = sha256.convert(utf8.encode(normalized)).toString();
    if (hash != _reviewerCodeHash) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewerAccessKey, true);
    return true;
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases().timeout(_storeTimeout);
  }

  /// Re-sync local entitlement from the store and return it. If the store
  /// cannot be reached, the last known entitlement stands.
  Future<bool> syncEntitlement({Duration settle = _restoreSettle}) async {
    await initialize();
    if (!_isAvailable) return hasActiveSubscription();

    try {
      _purchases.clear();
      final arrived = Completer<void>();
      _entitlementArrived = arrived;

      await _inAppPurchase.restorePurchases().timeout(_storeTimeout);

      // Finish as soon as an active subscription arrives. Otherwise allow the
      // purchase stream a moment to deliver.
      await arrived.future.timeout(settle, onTimeout: () {});

      final entitled = _purchases.any(
        (p) =>
            p.productID == subscriptionId &&
            (p.status == PurchaseStatus.purchased ||
                p.status == PurchaseStatus.restored),
      );
      await _persistEntitlement(entitled);
      return hasActiveSubscription();
    } catch (e) {
      debugPrint('syncEntitlement failed: $e');
      return hasActiveSubscription();
    } finally {
      _entitlementArrived = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Listener & Entitlement
  // ---------------------------------------------------------------------------
  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      _handlePurchase(p);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    try {
      final grantsAccess = purchase.productID == subscriptionId &&
          (purchase.status == PurchaseStatus.purchased ||
              purchase.status == PurchaseStatus.restored);

      if (grantsAccess) {
        _upsertPurchase(purchase);
        await _persistEntitlement(true);
        final arrived = _entitlementArrived;
        if (arrived != null && !arrived.isCompleted) arrived.complete();
      }

      // Android refunds purchases that are not acknowledged, and iOS keeps
      // redelivering transactions that are not finished.
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }

      _outcomes.add(PurchaseOutcome(purchase.status, purchase.error?.message));
    } catch (e) {
      debugPrint('Error in _handlePurchase: $e');
    }
  }

  void _upsertPurchase(PurchaseDetails p) {
    final idx = _purchases.indexWhere((x) => x.purchaseID == p.purchaseID);
    if (idx >= 0) {
      _purchases[idx] = p;
    } else {
      _purchases.add(p);
    }
  }

  Future<void> _persistEntitlement(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_entitledKey, value);
  }

  Future<bool> hasActiveSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getBool(_entitledKey) ?? false) ||
          (prefs.getBool(_reviewerAccessKey) ?? false);
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      return false;
    }
  }
}

/// Converts a Play billing period such as "P3D" or "P1W" to "3-day" or
/// "1-week". Returns null if the period is not in a recognized form.
@visibleForTesting
String? trialLabelFromIso8601(String period) {
  final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(period);
  if (match == null) return null;
  const units = {'D': 'day', 'W': 'week', 'M': 'month', 'Y': 'year'};
  return '${match.group(1)}-${units[match.group(2)]}';
}
