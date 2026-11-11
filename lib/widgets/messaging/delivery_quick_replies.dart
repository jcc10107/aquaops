import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

const String _font = 'Plus Jakarta Sans';

class DeliveryQuickReplies extends StatelessWidget {
  final ValueChanged<String> onSelect;
  final bool isRider;

  const DeliveryQuickReplies({
    super.key,
    required this.onSelect,
    this.isRider = false,
  });

  // Each side gets phrasing that actually fits what they'd say — a rider
  // saying "Please call when you arrive" (meant for a customer) never made
  // sense, and vice versa.
  static const List<String> _riderSuggestions = [
    'On my way!',
    'Arriving in 5 minutes.',
    "I'm outside your gate.",
    'Please prepare exact payment.',
    "Can't find the address — can you guide me?",
  ];

  static const List<String> _customerSuggestions = [
    "I'm at the gate.",
    'Please call when you arrive.',
    'Can you leave it by the door?',
    'How many minutes away are you?',
    'Thank you!',
  ];

  @override
  Widget build(BuildContext context) {
    final suggestions = isRider ? _riderSuggestions : _customerSuggestions;
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final text = suggestions[i];
          return ActionChip(
            onPressed: () => onSelect(text),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.slate200),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            label: Text(
              text,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}