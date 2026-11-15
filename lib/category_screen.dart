import 'package:flutter/material.dart';
import 'models/catalogue.dart';
import 'loan_options_screen.dart';
import 'inquiry_form_screen.dart';
import 'widgets/app_page.dart';
import 'l10n/si.dart';

class CategoryScreen extends StatelessWidget {
  final Catalogue catalogue;
  const CategoryScreen({super.key, required this.catalogue});
  @override
  Widget build(BuildContext context) {
    const labels = [
      'කුඩා, සුළු, මධ්‍ය පරිමාණ ව්‍යාපාර හෝ ව්‍යාපෘති ආරම්භ කිරීමට හෝ පවත්වාගෙන යාමට',
      'වී වගාව සහ අනෙකුත් භෝග හා කෘෂි ව්‍යාපෘති සඳහා',
      'පොල් වගාව සහ ඊට සම්බන්ධ කර්මාන්ත කටයුතු වෙනුවෙන්',
      'වෙනත් විශේෂිත සංවර්ධන අවශ්‍යතා වෙනුවෙන්'
    ];
    return AppPage(
        title: Si.title,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('ඔබගේ මුදල් අවශ්‍යතාවය කුමක් සඳහාද? පහතින් තෝරන්න.')),
          for (var i = 0; i < labels.length; i++)
            Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => LoanOptionsScreen(
                                loans: catalogue.loans
                                    .where((x) =>
                                        x.categoryId == 'category-${i + 1}')
                                    .toList(),
                                branches: catalogue.branches))),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(labels[i])))),
          OutlinedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) =>
                          InquiryFormScreen(branches: catalogue.branches))),
              child:
                  const Text('ඔබගේ අවශ්‍යතාවය ඉහත සඳහන් නැත්නම් මෙය තෝරන්න.'))
        ]));
  }
}
