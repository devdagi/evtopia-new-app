/// Basic input validation helpers.
class Validation {
  Validation._();

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Registration password: matches backend (min 8, letter, upper, lower, number, symbol).
  static String? registrationPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'At least 8 characters';
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) return 'Add at least one letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Add a lowercase letter';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add an uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Add at least one number';
    // Symbol: use normal string to avoid raw-string quote issues (e.g. \' and `)
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/' r"'`~]").hasMatch(value)) {
      return 'Add at least one symbol (e.g. !@#\$%)';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length < 9) return 'Enter a valid phone number';
    return null;
  }

  /// OTP: numeric, 4–6 digits.
  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'OTP is required';
    final v = value.trim();
    if (!RegExp(r'^\d{4,6}$').hasMatch(v)) {
      return 'Enter a valid 4–6 digit OTP';
    }
    return null;
  }

  /// Password for reset (evtopia-ecom backend min 6).
  static String? resetPassword(String? value) {
    return password(value, minLength: 6);
  }

  /// Confirm password must match [password].
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
