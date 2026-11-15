import '../l10n/si.dart';

class Validators {
  static String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? Si.required : null;
  static String? name(String? value) =>
      requiredText(value) ??
      ((value!.trim().length < 4 || value.trim().length > 60)
          ? Si.invalid
          : null);
  static String? age(String? value) {
    final age = int.tryParse(value?.trim() ?? '');
    return age == null || age < 18 || age > 99
        ? 'වයස අවුරුදු 18 සිට 99 දක්වා ඇතුළත් කරන්න'
        : null;
  }

  static String? nic(String? value) =>
      RegExp(r'^([0-9]{9}[xXvV]|[0-9]{12})$').hasMatch(value?.trim() ?? '')
          ? null
          : Si.invalid;
  static String? telephone(String? value) =>
      RegExp(r'^0[0-9]{9}$').hasMatch(value?.trim() ?? '') ? null : Si.invalid;
  static String? email(String? value) => value == null ||
          value.trim().isEmpty ||
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
      ? null
      : Si.invalid;
}
