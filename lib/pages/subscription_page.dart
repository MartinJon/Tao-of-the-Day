// lib/pages/subscription_page.dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../menu_dialogs.dart';
import '../services/storage_service.dart';
import '../services/subscription_service.dart';
import '../welcome_wrapper.dart';
import 'number_selector_page.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  StreamSubscription<PurchaseOutcome>? _outcomeSub;

  bool _isLoading = true;
  bool _isEntitled = false;
  bool _openedEntitled = false;
  bool _leaving = false;
  SubscriptionOffer? _offer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _outcomeSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await _subscriptionService.initialize();

    _openedEntitled = await _subscriptionService.hasActiveSubscription();
    _outcomeSub ??= _subscriptionService.outcomes.listen(_onOutcome);

    final entitled = await _subscriptionService.syncEntitlement();
    final offer = await _subscriptionService.loadOffer();

    if (!mounted || _leaving) return;
    setState(() {
      _isEntitled = entitled;
      _offer = offer;
      _isLoading = false;
    });
  }

  void _onOutcome(PurchaseOutcome outcome) {
    if (!mounted || _leaving) return;

    if (outcome.grantsAccess) {
      if (!_openedEntitled) _enterApp();
      return;
    }

    switch (outcome.status) {
      case PurchaseStatus.pending:
        setState(() => _isLoading = false);
        _showMessage(
          'Purchase pending',
          'Your purchase is waiting for confirmation from the store. '
              'Premium will unlock when it completes.',
        );
        break;
      case PurchaseStatus.canceled:
        setState(() => _isLoading = false);
        break;
      case PurchaseStatus.error:
        setState(() => _isLoading = false);
        _showMessage(
          'Purchase failed',
          outcome.message ?? 'The store could not complete the purchase.',
        );
        break;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        break;
    }
  }

  /// This page can be the app's first screen, with nothing beneath it to
  /// return to, so it replaces itself in that case.
  Future<void> _enterApp() async {
    if (_leaving) return;
    _leaving = true;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    final hasSeenWelcome = await StorageService.shouldShowWelcome();
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => hasSeenWelcome
            ? const NumberSelectorPage()
            : const WelcomeWrapper(child: NumberSelectorPage()),
      ),
    );
  }

  Future<void> _handleSubscribe() async {
    if (_isEntitled) {
      _openManageSubscription();
      return;
    }

    final offer = _offer;
    if (offer == null) {
      setState(() => _isLoading = true);
      await _init();
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _subscriptionService.purchaseSubscription(offer);
      // The spinner stays on until a result arrives in _onOutcome.
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Purchase failed', '$e');
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    final hasAccess = await _subscriptionService.syncEntitlement();

    if (!mounted || _leaving) return;
    setState(() {
      _isEntitled = hasAccess;
      _isLoading = false;
    });
    if (hasAccess) {
      _enterApp();
    } else {
      _showMessage('Restore Purchases', 'No active subscription found.');
    }
  }

  void _openManageSubscription() {
    final url = Platform.isIOS
        ? 'https://apps.apple.com/account/subscriptions'
        : 'https://play.google.com/store/account/subscriptions';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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

  String get _buttonLabel {
    if (_isEntitled) return 'MANAGE SUBSCRIPTION';
    final offer = _offer;
    if (offer == null) return 'TRY AGAIN';
    final trial = offer.freeTrialLabel;
    if (trial != null) return 'START ${trial.toUpperCase()} FREE TRIAL';
    return 'SUBSCRIBE FOR ${offer.recurringPrice}/MONTH';
  }

  String get _priceSummary {
    final offer = _offer;
    if (offer == null) {
      return 'Subscription details are unavailable right now. Check your '
          'connection and try again.';
    }
    final trial = offer.freeTrialLabel;
    if (trial != null) {
      return '$trial free trial, then ${offer.recurringPrice}/month';
    }
    return '${offer.recurringPrice}/month';
  }

  String get _legalText {
    final store = Platform.isIOS ? 'Apple Account' : 'Google Play account';
    final trial = _offer?.freeTrialLabel;
    final chargeTiming = trial != null
        ? 'Payment is charged to your $store when the free trial ends, unless '
            'you cancel at least 24 hours before it ends.'
        : 'Payment is charged to your $store when you confirm the purchase.';
    return '$chargeTiming The subscription renews automatically each month at '
        'the price shown unless canceled at least 24 hours before the end of '
        'the current period. Manage or cancel it at any time in your $store '
        'settings.';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accent =
        isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00);

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
            Icon(Icons.spa, size: 80, color: accent),
            const SizedBox(height: 20),
            Text(
              'Tao of the Day Premium',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'One chapter of the Tao Te Ching each day',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),

            // Features
            _buildFeature('All 81 Chapters', 'Choose a chapter or let chance decide'),
            _buildFeature('Audio Discussions', 'Listen to discussions of each chapter'),
            _buildFeature('Notes and Prompts', 'Contemplation notes and questions for each chapter'),
            const SizedBox(height: 30),

            // Pricing
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent),
              ),
              child: Text(
                _isLoading && _offer == null ? 'Loading price…' : _priceSummary,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Subscribe / Manage button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubscribe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _buttonLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),

            TextButton(
              onPressed: _isLoading ? null : _handleRestore,
              child: const Text('Restore Purchases'),
            ),
            const SizedBox(height: 20),

            // Legal
            Text(
              _legalText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white60 : Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () =>
                      MenuDialogs.showTermsOfServiceDialog(context),
                  child: const Text('Terms of Use'),
                ),
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse(MenuDialogs.privacyPolicyUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: const Text('Privacy Policy'),
                ),
              ],
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
