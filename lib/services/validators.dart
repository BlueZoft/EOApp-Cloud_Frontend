import '../l10n/app_strings.dart';
import '../l10n/translations.dart';

class Validators {
  static String text(AppStrings? strings, String key) =>
      strings?.t(key) ?? uiTranslations['si']![key]!;
  static String? requiredText(String? value, {AppStrings? strings}) =>
      value == null || value.trim().isEmpty ? text(strings, 'required') : null;
  static String? name(String? value, {AppStrings? strings}) =>
      requiredText(value, strings: strings) ??
      ((value!.trim().length < 4 || value.trim().length > 60)
          ? text(strings, 'invalid')
          : null);
  static String? age(String? value, {AppStrings? strings}) {
    final age = int.tryParse(value?.trim() ?? '');
    return age == null || age < 18 || age > 99
        ? text(strings, 'ageError')
        : null;
  }

  static String? nic(String? value, {AppStrings? strings}) =>
      RegExp(r'^([0-9]{9}[xXvV]|[0-9]{12})$').hasMatch(value?.trim() ?? '')
          ? null
          : text(strings, 'invalid');
  static String? telephone(String? value, {AppStrings? strings}) =>
      RegExp(r'^0[0-9]{9}$').hasMatch(value?.trim() ?? '')
          ? null
          : text(strings, 'invalid');
  static String? email(String? value, {AppStrings? strings}) => value == null ||
          value.trim().isEmpty ||
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
      ? null
      : text(strings, 'invalid');
}
