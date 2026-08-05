import 'package:cuboid_flutter_template/features/auth/data/auth_validation.dart';

abstract final class FormValidators {
  static String? required(String? value, {required String label}) =>
      value == null || value.trim().isEmpty ? '$label is required' : null;

  static String? email(String? value, {bool optional = false}) {
    final email = value?.trim() ?? '';
    if (optional && email.isEmpty) return null;
    return isValidEmail(email) ? null : 'A valid email is required';
  }

  static String? phone(String? value, {bool optional = true}) {
    final phone = value?.trim() ?? '';
    if (optional && phone.isEmpty) return null;
    final normalized = phone.replaceAll(RegExp(r'[\s()-]'), '');
    return RegExp(r'^\+?\d{7,15}$').hasMatch(normalized)
        ? null
        : 'Enter a valid phone number';
  }

  static String? integerRange(
    String? value, {
    required String label,
    required int min,
    required int max,
    bool optional = false,
  }) {
    final text = value?.trim() ?? '';
    if (optional && text.isEmpty) return null;
    final number = int.tryParse(text);
    return number == null || number < min || number > max
        ? '$label must be a whole number from $min to $max'
        : null;
  }

  static String? numberRange(
    String? value, {
    required String label,
    required num min,
    required num max,
  }) {
    final number = num.tryParse(value?.trim() ?? '');
    return number == null || !number.isFinite || number < min || number > max
        ? '$label must be a number from $min to $max'
        : null;
  }

  static String? selection<T>(T? value, String message) =>
      value == null ? message : null;
}
