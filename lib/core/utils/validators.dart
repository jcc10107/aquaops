class Validators {
  /// Strips all non-digit characters from a phone/GCash number string.
  static String sanitizePhone(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'\D'), '');
  }

  /// Alias for [sanitizePhone].
  static String stripPhoneDigits(String? value) => sanitizePhone(value);

  /// Validates email address format.
  /// Returns `null` if valid, or an error message string if invalid.
  static String? validateEmail(
      String? value, {
        String? requiredMessage,
        String? invalidMessage,
      }) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return requiredMessage ?? 'Email address is required.';
    }
    final emailValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!emailValid) {
      return invalidMessage ?? 'Please enter a valid email address.';
    }
    return null;
  }

  /// Validates 11-digit Philippine mobile phone number starting with '09'.
  /// Returns `null` if valid, or an error message string if invalid.
  static String? validateMobile(
      String? value, {
        String? requiredMessage,
        String? invalidMessage,
      }) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return requiredMessage ?? 'Mobile phone is required.';
    }
    final digits = sanitizePhone(phone);
    if (digits.length != 11 || !digits.startsWith('09')) {
      return invalidMessage ?? 'Enter a valid 11-digit mobile number.';
    }
    return null;
  }

  /// Validates password length and presence.
  static String? validatePassword(
      String? value, {
        int minLength = 8,
        String? requiredMessage,
        String? minLengthMessage,
      }) {
    final password = value ?? '';
    if (password.isEmpty) {
      return requiredMessage ?? 'Password is required.';
    }
    if (password.length < minLength) {
      return minLengthMessage ?? 'Password must be at least $minLength characters.';
    }
    return null;
  }

  /// Validates GCash number (must be 11 digits starting with '09').
  static String? validateGCash(
      String? value, {
        String? requiredMessage,
        String? invalidMessage,
      }) {
    final gcash = value?.trim() ?? '';
    if (gcash.isEmpty) {
      return requiredMessage ?? 'GCash mobile number is required.';
    }
    final digits = sanitizePhone(gcash);
    if (digits.length != 11 || !digits.startsWith('09')) {
      return invalidMessage ?? 'Enter a valid 11-digit GCash number (09XXXXXXXXX).';
    }
    return null;
  }

  /// Helper boolean check for email validity.
  static bool isValidEmail(String? value) {
    return validateEmail(value) == null;
  }

  /// Helper boolean check for GCash validity.
  static bool isValidGCash(String? value) {
    return validateGCash(value) == null;
  }

  /// Helper boolean check for 11-digit mobile validity.
  static bool isValidMobile(String? value) {
    return validateMobile(value) == null;
  }
}