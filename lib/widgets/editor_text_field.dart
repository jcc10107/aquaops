import 'package:flutter/material.dart';

/// Shared input field builder widget used across Terms/Privacy and GCash Account Editor screens.
class EditorTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? errorText;
  final VoidCallback? onChanged;
  final TextInputType keyboardType;
  final String? hintText;

  const EditorTextField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.errorText,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.hintText,
  });

  static const String _font = 'Plus Jakarta Sans';
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF3F4850);
  static const Color _fieldBg = Color(0xFFF2F3FF);
  static const Color _coral = Color(0xFFF43F5E);

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: _font,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: _onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: maxLines > 1 ? 10 : 0),
          height: maxLines > 1 ? null : 42,
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: hasError ? Border.all(color: _coral, width: 1.5) : null,
          ),
          alignment: maxLines > 1 ? null : Alignment.centerLeft,
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            onChanged: (_) => onChanged?.call(),
            style: const TextStyle(
              fontFamily: _font,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _onSurface,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontFamily: _font,
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontFamily: _font,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _coral,
              ),
            ),
          ),
      ],
    );
  }
}