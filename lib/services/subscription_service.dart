// lib/services/subscription_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'trial_service.dart';

class SubscriptionService {
  // --- Singleton ---
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // Your product ID (Play Console / App Store Connect)
  static const String _subscriptionId = 'tao_subscription_monthly';

  // Local entitlement cache flag
  static const String _entitledKey = 'entitled_premium';

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  bool _isAvailable = false;
  bool _initialized = false;

  List<ProductDetails> _products = [];
  final List<PurchaseDetails> _purchases = [];

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  // Public getter for UI
  List<ProductDetails> getProducts() => List.unmodifiable(_products);

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        debugPrint('❌ In-app purchases not available');
        _initialized = true; // avoid re-trying endlessly
        return;
      }
      debugPrint('✅ In-app purchases available');

      // Attach the purchase update listener once
      _purchaseSub ??= _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () => debugPrint('🎧 Purchase stream closed'),
        onError: (error) => debugPrint('❌ Purchase stream error: $error'),
      );

      await _loadProducts();
      // On init, try to restore known entitlements
      await refreshPurchases();

      _initialized = true;
    } catch (e) {
      debugPrint('❌ Subscription service initialization failed: $e');
      _initialized = true;
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
      final response =
      await _inAppPurchase.queryProductDetails({_subscriptionId});

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('❌ Product not found: ${response.notFoundIDs}');
      }
      _products = response.productDetails;
      debugPrint('Loaded products: ${_products.length}');
      for (final p in _products) {
        debugPrint('Product: ${p.id} | price: ${p.price} | title: ${p.title}');
      }

      for (final p in _products) {
        debugPrint('📦 Product: ${p.id} | ${p.title} | ${p.price}');
      }
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase / Restore
  // ---------------------------------------------------------------------------
  Future<void> purchaseSubscription() async {
    try {
      if (_products.isEmpty) {
        await _loadProducts();
      }
      final product = _products.firstWhere(
            (p) => p.id == _subscriptionId,
        orElse: () => throw Exception('Product not found'),
      );

      final purchaseParam = PurchaseParam(productDetails: product);

      // Subscriptions are purchased with buyNonConsumable in the plugin API
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      debugPrint('🛒 Purchase initiated for: ${product.title}');
    } catch (e) {
      debugPrint('❌ Purchase failed: $e');
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      debugPrint('✅ Restore purchases initiated');
    } catch (e) {
      debugPrint('❌ Restore failed: $e');
      rethrow;
    }
  }
// Add inside SubscriptionService class

  /// Re-sync local entitlement by restoring purchases and recomputing.
  /// Returns the final entitlement (true/false).
  Future<bool> syncEntitlement({Duration settle = const Duration(seconds: 1)}) async {
    try {
      // Trigger re-emission of known purchases
      await _inAppPurchase.restorePurchases();

      // Give purchaseStream a moment to deliver updates
      await Future.delayed(settle);

      // Compute entitlement purely from in-memory purchases
      final entitled = _purchases.any((p) =>
      p.productID == _subscriptionId &&
          (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored)
      );

      // Persist the computed truth
      await _persistEntitlement(entitled);
      debugPrint('🔄 syncEntitlement => $entitled (from ${_purchases.length} purchases)');
      return entitled;
    } catch (e) {
      debugPrint('❌ syncEntitlement failed: $e');
      return await hasActiveSubscription(); // fall back to whatever was cached
    }
  }

  /// Prefer this in code paths where you want a silent refresh of entitlement.
  Future<void> refreshPurchases() async {
    // On both iOS and Android, this will re-emit past purchases via purchaseStream
    await _inAppPurchase.restorePurchases();
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
      debugPrint('🧾 Purchase update: '
          'id=${purchase.purchaseID}, '
          'product=${purchase.productID}, '
          'status=${purchase.status}, '
          'pendingComplete=${purchase.pendingCompletePurchase}');

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _upsertPurchase(purchase);

          // Persist entitlement immediately
          await _persistEntitlement(true);
          debugPrint('✅ Entitlement granted and cached.');

          // VERY IMPORTANT on Android: acknowledge or Google may refund
          if (purchase.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchase);
            debugPrint('🙏 Purchase acknowledged.');
          }
          break;

        case PurchaseStatus.pending:
          debugPrint('⏳ Purchase pending...');
          // Do not grant; UI should show "Purchase pending" if you want.
          break;

        case PurchaseStatus.error:
          debugPrint('❌ Purchase error: ${purchase.error}');
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('❌ Error in _handlePurchase: $e');
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
      return prefs.getBool(_entitledKey) ?? false;
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      return false;
    }
  }
}

