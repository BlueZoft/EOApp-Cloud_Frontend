import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'translations.dart';

class AppStrings {
  final String language;
  final Map<String, String> _values;
  const AppStrings(this.language, this._values);
  String t(String key) => _values[key] ?? key;
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      AppStrings('si', uiTranslations['si']!);
  static const delegate = _StringsDelegate();
}

class _StringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _StringsDelegate();
  @override
  bool isSupported(Locale locale) =>
      ['si', 'en', 'ta'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) => SynchronousFuture(
      AppStrings(locale.languageCode, uiTranslations[locale.languageCode]!));
  @override
  bool shouldReload(_StringsDelegate old) => false;
}

class LanguageScope extends InheritedWidget {
  final Locale locale;
  final ValueChanged<Locale> change;
  const LanguageScope(
      {super.key,
      required this.locale,
      required this.change,
      required super.child});
  static LanguageScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>();
  @override
  bool updateShouldNotify(LanguageScope oldWidget) =>
      locale != oldWidget.locale;
}

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = LanguageScope.of(context);
    if (scope == null) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
          key: const ValueKey('language-picker'),
          value: scope.locale.languageCode,
          hint: Text(AppStrings.of(context).t('language')),
          items: const [
            DropdownMenuItem(value: 'si', child: Text('සිංහල')),
            DropdownMenuItem(value: 'en', child: Text('English')),
            DropdownMenuItem(value: 'ta', child: Text('தமிழ்'))
          ],
          onChanged: (value) {
            if (value != null) scope.change(Locale(value));
          },
        )));
  }
}
