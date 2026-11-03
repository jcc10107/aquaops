import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

const String _font = 'Plus Jakarta Sans';

class DeliveryQuickReplies extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const DeliveryQuickReplies({
    super.key,
    required this.onSelect,
  });

  static const List<String> _suggestions = [
    "I'm at the gate.",
    "Please call when you arrive.",
    "On my way!",
    "Can you leave it by the door?",
    "Thank you!",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final text = _suggestions[i];
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