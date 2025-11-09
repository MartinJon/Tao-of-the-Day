import 'package:flutter/material.dart';
import '../services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/trial_service.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;
  ProductDetails? premiumProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    // Load your product here from SubscriptionService
    final subscriptionService = SubscriptionService();
    // Get the product details and set state
  }
  void _handleSubscribe() async {
    setState(() => _isLoading = true);
    try {
      await _subscriptionService.purchaseSubscription();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showErrorDialog('Subscription failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleRestore() async {
    setState(() => _isLoading = true);
    try {
      await _subscriptionService.restorePurchases();
      final hasAccess = await _subscriptionService.hasActiveSubscription();
      if (hasAccess && mounted) {
        Navigator.pop(context);
      } else if (mounted) {
        _showErrorDialog('No active subscription found.');
      }
    } catch (e) {
      if (mounted) _showErrorDialog('Restore failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tao of the Day Premium'),
        backgroundColor: isDarkMode ? const Color(0xFF5C1A00) : const Color(0xFF7E1A00),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header
            Icon(Icons.auto_awesome, size: 80, color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
            const SizedBox(height: 20),
            Text('Tao of the Day Premium', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00), fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Continue your Tao journey beyond the trial', textAlign: TextAlign.center, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: 16)),
            const SizedBox(height: 30),

            // Trial Status (if in trial)
            FutureBuilder<bool>(
              future: TrialService.isTrialActive(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return SizedBox();
                if (snapshot.data == true) {
                  return FutureBuilder<int>(
                    future: TrialService.getDaysRemaining(),
                    builder: (context, daysSnapshot) {
                      final daysRemaining = daysSnapshot.data ?? 0;
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green)),
                            child: Column(children: [
                              Icon(Icons.celebration, size: 40, color: Colors.green),
                              SizedBox(height: 10),
                              Text('You\'re in your Free Trial!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                              SizedBox(height: 8),
                              Text(daysRemaining > 1 ? '$daysRemaining days remaining in your trial' : 'Last day of your free trial', textAlign: TextAlign.center, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
                            ]),
                          ),
                          SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: (isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00))),
                            child: Column(children: [
                              Text('Upgrade to Premium Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00))),
                              SizedBox(height: 8),
                              Text('Subscribe today and your payment will start after the trial ends', textAlign: TextAlign.center, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: 14)),
                            ]),
                          ),
                          SizedBox(height: 20),
                        ],
                      );
                    },
                  );
                }
                return SizedBox();
              },
            ),

            // Features
            _buildFeature('3-Day Free Trial', 'Try everything free for 3 days'),
            _buildFeature('Continued Tao Access', 'Continue to explore Tao daily'),
            _buildFeature('Ad-Free Experience', 'Focus on your contemplation'),
            _buildFeature('Offline Listening', 'Download discussions for offline use'),
            const SizedBox(height: 30),

            // Pricing
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: (isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00))),
              child: Column(children: [
              Text('Then ${premiumProduct?.price ?? "Loading..."}/month', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00))),
                SizedBox(height: 8),
                Text('Cancel anytime during trial', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
              ]),
            ),
            const SizedBox(height: 30),

            // Subscribe Button (ALWAYS SHOWN)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubscribe,
                style: ElevatedButton.styleFrom(backgroundColor: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBSCRIBE FOR \$099./MONTH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),

            // Restore Purchases (ALWAYS SHOWN)
            TextButton(onPressed: _isLoading ? null : _handleRestore, child: const Text('Restore Purchases')),
            const SizedBox(height: 20),

            // Legal
            Text('By continuing, you agree to our Terms and Privacy Policy. Payment will be charged to your Google Play Account. Subscription automatically renews unless canceled at least 24 hours before the end of the current period.', textAlign: TextAlign.center, style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String title, String description) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.check_circle, color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00), size: 20),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black87)),
          Text(description, style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.black54)),
        ])),
      ]),
    );
  }
}