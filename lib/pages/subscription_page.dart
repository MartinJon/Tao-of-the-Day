// import 'package:flutter/material.dart';
// import '../services/subscription_service.dart';
//
// class SubscriptionPage extends StatefulWidget {
//   const SubscriptionPage({super.key});
//
//   @override
//   _SubscriptionPageState createState() => _SubscriptionPageState();
// }
//
// class _SubscriptionPageState extends State<SubscriptionPage> {
//   final SubscriptionService _subscriptionService = SubscriptionService();
//   bool _isLoading = false;
//
//   void _handleSubscribe() async {
//     setState(() => _isLoading = true);
//
//     try {
//       await _subscriptionService.purchaseSubscription();
//       // Navigation will be handled by the subscription listener
//     } catch (e) {
//       _showErrorDialog('Subscription failed: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   void _handleRestore() async {
//     setState(() => _isLoading = true);
//
//     try {
//       await _subscriptionService.restorePurchases();
//       _showSuccessDialog('Purchases restored successfully!');
//     } catch (e) {
//       _showErrorDialog('Restore failed: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showSuccessDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Success'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Tao of the Day Premium'),
//         backgroundColor: isDarkMode ? const Color(0xFF5C1A00) : const Color(0xFF7E1A00),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             // Header
//             Icon(
//               Icons.auto_awesome,
//               size: 80,
//               color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
//             ),
//             const SizedBox(height: 20),
//
//             Text(
//               'Tao of the Day Premium',
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                 color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//
//             Text(
//               'Continue your Tao journey with unlimited access',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: isDarkMode ? Colors.white70 : Colors.black87,
//                 fontSize: 16,
//               ),
//             ),
//             const SizedBox(height: 30),
//
//             // Features
//             _buildFeature('3-Day Free Trial', 'Try everything free for 3 days'),
//             _buildFeature('Unlimited Tao Access', 'Explore all 81 chapters daily'),
//             _buildFeature('Ad-Free Experience', 'Focus on your contemplation'),
//             _buildFeature('Offline Listening', 'Download discussions for offline use'),
//
//             const SizedBox(height: 30),
//
//             // Pricing
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: (isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)).withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00)),
//               ),
//               child: Column(
//                 children: [
//                   Text(
//                     'Then \$2.99/month',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Cancel anytime during trial',
//                     style: TextStyle(
//                       color: isDarkMode ? Colors.white70 : Colors.black87,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const Spacer(),
//
//             // Subscribe Button
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _handleSubscribe,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                 ),
//                 child: _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text(
//                   'START 3-DAY FREE TRIAL',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//
//             // Restore Purchases
//             TextButton(
//               onPressed: _isLoading ? null : _handleRestore,
//               child: const Text('Restore Purchases'),
//             ),
//
//             const SizedBox(height: 20),
//
//             // Legal
//             Text(
//               'By continuing, you agree to our Terms and Privacy Policy',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: isDarkMode ? Colors.white60 : Colors.black54,
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFeature(String title, String description) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             Icons.check_circle,
//             color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
//             size: 20,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: isDarkMode ? Colors.white70 : Colors.black87,
//                   ),
//                 ),
//                 Text(
//                   description,
//                   style: TextStyle(
//                     color: isDarkMode ? Colors.white60 : Colors.black54,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }