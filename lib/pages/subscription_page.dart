// lib/pages/subscription_page.dart
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/subscription_service.dart';
import '../services/trial_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  bool _isEntitled = false;
  ProductDetails? _premiumProduct;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);

    // Make sure IAP is ready
    await _subscriptionService.initialize();

    // 🔄 Pull latest truth from the store and cache it
    await _subscriptionService.syncEntitlement();

    // Read the cached truth (fast)
    final entitled = await _subscriptionService.hasActiveSubscription();

    // Get products AFTER initialize
    List<ProductDetails> products = _subscriptionService.getProducts();

    // Optional: tiny retry in case the list was still empty on first frame
    if (products.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      products = _subscriptionService.getProducts();
    }

    // Pick your product (safe)
    ProductDetails? chosen;
    try {
      chosen = products.firstWhere((p) => p.id == 'tao_subscription_monthly');
    } catch (_) {
      if (products.isNotEmpty) chosen = products.first;
    }

    setState(() {
      _isEntitled = entitled;
      _premiumProduct = chosen;
      _isLoading = false;
    });
  }


  Future<bool> _waitForEntitlement({Duration timeout = const Duration(seconds: 20)}) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      final ok = await _subscriptionService.hasActiveSubscription();
      if (ok) return true;
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }


  Future<void> _handleSubscribe() async {
    if (_isEntitled) {
      _openManageSubscription();
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _subscriptionService.purchaseSubscription();

      // Nudge the store to emit purchases and then wait for listener to grant
      await _subscriptionService.syncEntitlement();
      final gotEntitlement = await _waitForEntitlement();

      if (gotEntitlement && mounted) {
        Navigator.pop(context); // success — leave paywall
        return;
      }

      // If we’re here, it’s pending / slow propagation — be gentle
      _showErrorDialog(
        'Your purchase is being processed. If Premium doesn’t unlock shortly, tap “Restore Purchases.”',
      );
    } catch (e) {
      if (mounted) _showErrorDialog('Subscription failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    try {
      await _subscriptionService.restorePurchases();

      // Recompute entitlement from what the store returned
      await _subscriptionService.syncEntitlement();

      final hasAccess = await _subscriptionService.hasActiveSubscription();
      if (hasAccess && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        _showErrorDialog('No active subscription found.');
      }
    } catch (e) {
      if (mounted) _showErrorDialog('Restore failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  void _openManageSubscription() {
    final url = Platform.isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tao of the Day Premium'),
        backgroundColor:
        isDarkMode ? const Color(0xFF5C1A00) : const Color(0xFF7E1A00),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome,
                size: 80,
                color: isDarkMode
                    ? const Color(0xFFD45C33)
                    : const Color(0xFF7E1A00)),
            const SizedBox(height: 20),
            Text('Tao of the Day Premium',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isDarkMode
                      ? const Color(0xFFD45C33)
                      : const Color(0xFF7E1A00),
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 10),
            Text('Continue your Tao journey beyond the trial',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    fontSize: 16)),
            const SizedBox(height: 30),

            // Trial badge
            FutureBuilder<bool>(
              future: TrialService.isTrialActive(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.data == true) {
                  return FutureBuilder<int>(
                    future: TrialService.getDaysRemaining(),
                    builder: (context, daysSnapshot) {
                      final daysRemaining = daysSnapshot.data ?? 0;
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.celebration,
                                    size: 40, color: Colors.green),
                                const SizedBox(height: 10),
                                const Text(
                                  'You\'re in your Free Trial!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  daysRemaining > 1
                                      ? '$daysRemaining days remaining in your trial'
                                      : 'Last day of your free trial',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (isDarkMode
                                  ? const Color(0xFFD45C33)
                                  : const Color(0xFF7E1A00))
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode
                                    ? const Color(0xFFD45C33)
                                    : const Color(0xFF7E1A00),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Upgrade to Premium Now',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode
                                        ? const Color(0xFFD45C33)
                                        : const Color(0xFF7E1A00),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Subscribe today and your payment will start after the trial ends',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Features
            _buildFeature('3-Day Free Trial', 'Try everything free for 3 days'),
            _buildFeature(
                'Continued Tao Access', 'Continue to explore Tao daily'),
            _buildFeature('Ad-Free Experience', 'Focus on your contemplation'),
            _buildFeature('Offline Listening',
                'Download discussions for offline use'),
            const SizedBox(height: 30),

            // Pricing
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDarkMode
                    ? const Color(0xFFD45C33)
                    : const Color(0xFF7E1A00))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode
                      ? const Color(0xFFD45C33)
                      : const Color(0xFF7E1A00),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _premiumProduct != null
                        ? 'Then ${_premiumProduct!.price}/month'
                        : 'Loading price…',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? const Color(0xFFD45C33)
                          : const Color(0xFF7E1A00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cancel anytime during trial',
                    style: TextStyle(
                      color:
                      isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Subscribe / Manage button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? const Color(0xFFD45C33)
                      : const Color(0xFF7E1A00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _isEntitled
                      ? 'MANAGE SUBSCRIPTION'
                      : 'SUBSCRIBE${_premiumProduct != null ? ' FOR ${_premiumProduct!.price}/MONTH' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Restore Purchases (you asked to keep this — yes!)
            TextButton(
              onPressed: _isLoading ? null : _handleRestore,
              child: const Text('Restore Purchases'),
            ),
            const SizedBox(height: 20),

            // Legal
            Text(
              'By continuing, you agree to our Terms and Privacy Policy. Payment will be charged to your Store account. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white60 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String title, String description) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle,
              color: isDarkMode
                  ? const Color(0xFFD45C33)
                  : const Color(0xFF7E1A00),
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.white70
                            : Colors.black87)),
                Text(description,
                    style: TextStyle(
                        color: isDarkMode
                            ? Colors.white60
                            : Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
