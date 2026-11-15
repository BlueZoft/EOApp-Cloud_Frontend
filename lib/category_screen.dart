import 'package:flutter/material.dart';
import 'models/catalogue.dart';
import 'loan_options_screen.dart';
import 'inquiry_form_screen.dart';
import 'guidance_screen.dart';
import 'widgets/app_page.dart';
import 'l10n/app_strings.dart';

class CategoryScreen extends StatelessWidget {
  final Catalogue catalogue;
  const CategoryScreen({super.key, required this.catalogue});
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    void browse([String? category]) => Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => LoanOptionsScreen(
                loans: catalogue.loans,
                branches: catalogue.branches,
                initialCategoryId: category)));
    return AppPage(
        title: strings.t('title'),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          ElevatedButton.icon(
              key: const ValueKey('browse-all'),
              onPressed: browse,
              icon: const Icon(Icons.search),
              label: Text(strings.t('browse'))),
          TextButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => GuidanceScreen(catalogue: catalogue))),
              icon: const Icon(Icons.explore_outlined),
              label: Text(strings.t('guide'))),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(strings.t('purpose'))),
          for (var i = 1; i <= 4; i++)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                    onPressed: () => browse('category-$i'),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(strings.t('category$i'))))),
          OutlinedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) =>
                          InquiryFormScreen(branches: catalogue.branches))),
              child: Text(strings.t('otherPurpose'))),
        ]));
  }
}
