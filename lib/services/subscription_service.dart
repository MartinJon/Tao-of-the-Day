// services/subscription_service.dart
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter/foundation.dart';
import 'trial_service.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();



  static const String _subscriptionId = 'tao_subscription_monthly';
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];

  Future<void> initialize() async {
    try {
      // Check if in-app purchases are available
      _isAvailable = await _inAppPurchase.isAvailable();
      if (!_isAvailable) {
        print('❌ In-app purchases not available');
        return;
      }


      print('✅ In-app purchases available');

      // Listen to purchase updates
      _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdate,
        onDone: () => print('🎧 Purchase stream closed'),
        onError: (error) => print('❌ Purchase stream error: $error'),
      );

      // Load products
      await _loadProducts();

    } catch (e) {
      print('❌ Subscription service initialization failed: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails({_subscriptionId});

      if (response.notFoundIDs.isNotEmpty) {
        print('❌ Product not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      print('✅ Loaded ${_products.length} products');

      for (var product in _products) {
        print('📦 Product: ${product.title} - ${product.price}');
      }

    } catch (e) {
      print('❌ Error loading products: $e');
    }
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchases) {
    for (var purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  void _handlePurchase(PurchaseDetails purchase) {
    if (purchase.status == PurchaseStatus.purchased) {
      print('✅ Purchase successful: ${purchase.productID}');
      _purchases.add(purchase);
    } else if (purchase.status == PurchaseStatus.error) {
      print('❌ Purchase error: ${purchase.error}');
    }
  }

  Future<bool> hasActiveSubscription() async {
    try {
      // For now, we'll use a simple approach
      // In production, you'd verify receipts with your server
      return _purchases.any((purchase) =>
      purchase.productID == _subscriptionId &&
          purchase.status == PurchaseStatus.purchased
      );
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }

  Future<void> purchaseSubscription() async {
    try {
      if (_products.isEmpty) {
        await _loadProducts();
      }

      final product = _products.firstWhere(
            (p) => p.id == _subscriptionId,
        orElse: () => throw Exception('Product not found'),
      );

      final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);

      print('🛒 Purchase initiated for: ${product.title}');

    } catch (e) {
      print('❌ Purchase failed: $e');
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      print('✅ Restore purchases initiated');
    } catch (e) {
      print('❌ Restore failed: $e');
      rethrow;
    }
  }
  Future<bool> canAccessApp() async {
    try {
      // Check if user has active subscription OR is in trial
      final hasSubscription = await hasActiveSubscription();
      if (hasSubscription) {
        return true;
      }

      // Also check trial status (you might want to move this logic)
      final trialActive = await TrialService.isTrialActive();
      return trialActive;

    } catch (e) {
      print('Error checking app access: $e');
      return false;
    }
  }
}
