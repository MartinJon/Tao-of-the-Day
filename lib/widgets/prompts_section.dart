// widgets/prompts_section.dart
import 'package:flutter/material.dart';
import '../models/tao_data.dart';

class PromptsSection extends StatelessWidget {
  final TaoData taoData;

  const PromptsSection({super.key, required this.taoData});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Check if there are any prompts to display
    if (!taoData.hasPrompts) {
      return const SizedBox.shrink(); // Return empty widget if no prompts
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),

        // Section Header
        Row(
          children: [
            const SizedBox(width: 8),
            Text(
              'Prompts',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Prompt 1
        if (taoData.prompt1.isNotEmpty)
          _buildPromptCard(
            context: context,
            prompt: taoData.prompt1,
            promptNumber: 1,
            isDarkMode: isDarkMode,
          ),

        // Prompt 2
        if (taoData.prompt2.isNotEmpty)
          _buildPromptCard(
            context: context,
            prompt: taoData.prompt2,
            promptNumber: 2,
            isDarkMode: isDarkMode,
          ),
      ],
    );
  }

  Widget _buildPromptCard({
    required BuildContext context,
    required String prompt,
    required int promptNumber,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prompt Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFFD45C33) : const Color(0xFF7E1A00),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Prompt $promptNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Prompt Text
          SelectableText(
            prompt,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}