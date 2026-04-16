/// Light-weight validators for the onboarding & invoice forms.
class Validators {
  /// ZATCA VAT numbers are 15 digits, start with 3, end with 3.
  static String? vatNumber(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    if (value.length != 15) return 'Must be 15 digits';
    if (!RegExp(r'^\d{15}$').hasMatch(value)) return 'Digits only';
    if (!value.startsWith('3')) return 'Must start with 3';
    if (!value.endsWith('3')) return 'Must end with 3';
    return null;
  }

  static String? required(String? value, {String label = 'Field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (value.trim().length < 6) return 'OTP is usually 6 digits';
    return null;
  }

  static String? positiveNumber(String? value, {String label = 'Value'}) {
    if (value == null || value.isEmpty) return '$label is required';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Must be a number';
    if (parsed < 0) return 'Must be ≥ 0';
    return null;
  }
}
