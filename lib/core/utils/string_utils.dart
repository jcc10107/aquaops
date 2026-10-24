/// String utility functions used across the application.
library;

/// Generates up to 2 uppercase initials from a user's full name.
/// - Returns 'U' if the input string is empty or contains only whitespace.
/// - For multi-word names, returns the first character of the first word
///   combined with the first character of the last word.
/// - For single-word names, returns up to the first 2 characters.
String getInitials(String fullName) {
  if (fullName.trim().isEmpty) return 'U';
  final List<String> parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.length > 1) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
}