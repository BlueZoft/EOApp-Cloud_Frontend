import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_frontend/models/catalogue.dart';
import 'package:flutter_frontend/services/loan_discovery.dart';
import 'package:flutter_frontend/l10n/app_strings.dart';
import 'package:flutter_frontend/l10n/translations.dart';
import 'package:flutter_frontend/loan_options_screen.dart';
import 'package:flutter_frontend/loan_comparison_screen.dart';
import 'package:flutter_frontend/inquiry_form_screen.dart';
import 'package:flutter_frontend/guidance_screen.dart';

const loans = [
  LoanProduct(
      id: 'loan-01',
      categoryId: 'category-1',
      name: 'Alpha',
      description: 'New enterprises',
      audience: 'Small businesses',
      interestRate: '6% or 8% depending on purpose',
      maximumAmount: 'As listed — confirm with institution',
      repaymentPeriod: '5 years',
      eligibleActivities: 'Food production'),
  LoanProduct(
      id: 'loan-02',
      categoryId: 'category-1',
      name: 'Beta',
      description: 'Existing enterprises',
      audience: 'Small businesses',
      interestRate: '8%',
      maximumAmount: '25 million',
      repaymentPeriod: '10 years',
      eligibleActivities: 'Food processing'),
  LoanProduct(
      id: 'loan-03',
      categoryId: 'category-2',
      name: 'Gamma',
      description: 'Agricultural projects',
      audience: 'Farmers',
      interestRate: '6.5%',
      maximumAmount: 'Depends on project',
      repaymentPeriod: 'Varies',
      eligibleActivities: 'Crops'),
  LoanProduct(
      id: 'loan-04',
      categoryId: 'category-3',
      name: 'Delta',
      description: 'Coconut activities',
      audience: 'Growers',
      interestRate: 'As listed',
      maximumAmount: 'As listed',
      repaymentPeriod: 'As listed',
      eligibleActivities: 'Coconut'),
];
Widget localized(Widget home, {ValueNotifier<Locale>? language}) {
  final locale = language ?? ValueNotifier(const Locale('en'));
  return ValueListenableBuilder<Locale>(
      valueListenable: locale,
      builder: (_, value, __) => LanguageScope(
          locale: value,
          change: (next) => locale.value = next,
          child: MaterialApp(
              locale: value,
              supportedLocales: const [
                Locale('si'),
                Locale('en'),
                Locale('ta')
              ],
              localizationsDelegates: const [
                AppStrings.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate
              ],
              home: home)));
}

void main() {
  test(
      'search combines words across fields, ignores case/whitespace and keeps category boundaries',
      () {
    expect(
        LoanDiscovery.filter(loans, query: '  ALPHA  food ').map((x) => x.id),
        ['loan-01']);
    expect(LoanDiscovery.filter(loans, query: 'food', categoryId: 'category-2'),
        isEmpty);
    expect(LoanDiscovery.filter(loans, query: '').length, 4);
    expect(LoanDiscovery.filter(loans, query: 'unmatched'), isEmpty);
    expect(LoanDiscovery.filter(loans, query: 'தென்னை').single.id, 'loan-04');
    expect(
        LoanDiscovery.filter(loans, query: 'කෘෂිකර්මය').single.id, 'loan-03');
  });
  test(
      'comparison selection is deduplicated, capped and stable across filtering',
      () {
    final selection = ComparisonSelection();
    expect(selection.canCompare, false);
    expect(selection.add('loan-01'), true);
    expect(selection.add('loan-01'), true);
    expect(selection.ids.length, 1);
    selection.add('loan-02');
    expect(selection.canCompare, true);
    selection.add('loan-03');
    expect(selection.add('loan-04'), false);
    LoanDiscovery.filter(loans, query: 'Delta');
    expect(selection.resolve(loans).map((x) => x.name),
        ['Alpha', 'Beta', 'Gamma']);
    selection.remove('loan-02');
    expect(selection.add('loan-04'), true);
    selection.clear();
    expect(selection.canCompare, false);
  });
  test('all customer locales define the same keys with actual translations',
      () {
    final keys = uiTranslations['en']!.keys.toSet();
    for (final entry in uiTranslations.entries) {
      expect(entry.value.keys.toSet(), keys);
      for (final text in entry.value.entries) {
        if (entry.key == 'si' && text.key == 'catalogueLanguage') continue;
        expect(text.value.trim(), isNotEmpty,
            reason: '${entry.key}.${text.key}');
      }
    }
    expect(uiTranslations['ta']!['submit'],
        isNot(uiTranslations['en']!['submit']));
  });
  testWidgets(
      'narrow-screen search preserves hidden selections and opens a scrollable comparison with original terms',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
        localized(const LoanOptionsScreen(loans: loans, branches: [])));
    await tester.pumpAndSettle();
    for (final id in ['loan-01', 'loan-02']) {
      final field = find.byKey(ValueKey('compare-$id'));
      await tester.scrollUntilVisible(field, 160,
          scrollable: find
              .descendant(
                  of: find.byKey(const ValueKey('loan-results')),
                  matching: find.byType(Scrollable))
              .first);
      await tester.pumpAndSettle();
      await tester.tap(field);
      await tester.pumpAndSettle();
    }
    await tester.enterText(find.byKey(const ValueKey('loan-search')), 'Gamma');
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNWidgets(2));
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('loan-results')),
            matching: find.text('Gamma')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('compare-open')));
    await tester.pumpAndSettle();
    expect(find.byType(LoanComparisonScreen), findsOneWidget);
    expect(find.text('6% or 8% depending on purpose'), findsOneWidget);
    final scroll = find.byKey(const ValueKey('comparison-scroll'));
    await tester.drag(scroll, const Offset(-250, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<SingleChildScrollView>(scroll).controller!.offset,
        greaterThan(0));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'language changes preserve form data and translate customer labels and validation',
      (tester) async {
    final language = ValueNotifier(const Locale('en'));
    addTearDown(language.dispose);
    await tester.pumpWidget(
        localized(const InquiryFormScreen(branches: []), language: language));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('name')), 'Synthetic Person');
    await tester.enterText(find.byKey(const ValueKey('age')), 'ab');
    await tester.pumpAndSettle();
    expect(find.text(uiTranslations['en']!['ageError']!), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('language-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('தமிழ்').last);
    await tester.pumpAndSettle();
    expect(find.text('Synthetic Person'), findsOneWidget);
    expect(find.text(uiTranslations['ta']!['name']!), findsOneWidget);
    expect(find.text(uiTranslations['ta']!['ageError']!), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'guide explains its limits, changes preparation tips and opens the selected purpose',
      (tester) async {
    await tester.pumpWidget(
        localized(const GuidanceScreen(catalogue: Catalogue(loans, []))));
    await tester.pumpAndSettle();
    expect(find.text(uiTranslations['en']!['guideNotice']!), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guide-purpose')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agriculture and crops').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guide-stage')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Existing business').last);
    await tester.pumpAndSettle();
    expect(find.text(uiTranslations['en']!['existingTip']!), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('guide-explore')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('guide-explore')));
    await tester.pumpAndSettle();
    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
