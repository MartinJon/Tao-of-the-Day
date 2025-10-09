// import 'package:purchases_flutter/purchases_flutter.dart';
// import 'package:flutter/foundation.dart';
//
// class SubscriptionService {
//   static final SubscriptionService _instance = SubscriptionService._internal();
//   factory SubscriptionService() => _instance;
//   SubscriptionService._internal();
//
//   static const String apiKeyApple = 'your_apple_app_public_key';
//   static const String apiKeyGoogle = 'your_google_play_public_key';
//   static const String subscriptionId = 'tao_subscription_monthly';
//
//   bool _isInitialized = false;
//
//   Future<void> initialize() async {
//     if (_isInitialized) return;
//
//     try {
//       if (defaultTargetPlatform == TargetPlatform.iOS) {
//         await Purchases.configure(PurchasesConfiguration(apiKeyApple));
//       } else if (defaultTargetPlatform == TargetPlatform.android) {
//         await Purchases.configure(PurchasesConfiguration(apiKeyGoogle));
//       }
//
//       _isInitialized = true;
//       print('✅ RevenueCat initialized');
//     } catch (e) {
//       print('❌ RevenueCat initialization failed: $e');
//     }
//   }
//
//   Future<bool> isSubscribed() async {
//     try {
//       await initialize();
//       final customerInfo = await Purchases.getCustomerInfo();
//
//       // Check if user has active subscription OR is in trial period
//       final entitlement = customerInfo.entitlements.active['premium'];
//
//       if (entitlement != null) {
//         // User has active subscription or is in trial
//         return true;
//       }
//
//       return false;
//     } catch (e) {
//       print('Error checking subscription: $e');
//       return false;
//     }
//   }
//
//   Future<bool> isInTrialPeriod() async {
//     try {
//       final customerInfo = await Purchases.getCustomerInfo();
//       final entitlement = customerInfo.entitlements.active['premium'];
//
//       // Check if user is in trial period
//       return entitlement?.isSandbox == true ||
//           entitlement?.periodType == PeriodType.trial;
//     } catch (e) {
//       print('Error checking trial: $e');
//       return false;
//     }
//   }
//
//   Future<void> purchaseSubscription() async {
//     try {
//       final offerings = await Purchases.getOfferings();
//       final currentOffering = offerings.current;
//
//       if (currentOffering != null) {
//         final package = currentOffering.monthly; // or .annual, .lifetime
//
//         if (package != null) {
//           await Purchases.purchasePackage(package);
//           print('✅ Subscription purchase initiated');
//         }
//       }
//     } catch (e) {
//       print('❌ Purchase failed: $e');
//       rethrow;
//     }
//   }
//
//   Future<void> restorePurchases() async {
//     try {
//       await Purchases.restorePurchases();
//       print('✅ Purchases restored');
//     } catch (e) {
//       print('❌ Restore failed: $e');
//       rethrow;
//     }
//   }
//
//   // Check if user is eligible for free trial (first-time user)
//   Future<bool> isEligibleForTrial() async {
//     try {
//       final customerInfo = await Purchases.getCustomerInfo();
//       // First-time users are generally eligible for trials
//       return customerInfo.entitlements.active.isEmpty;
//     } catch (e) {
//       return true; // Default to eligible if we can't determine
//     }
//   }
// }