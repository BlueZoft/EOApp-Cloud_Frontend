import 'package:flutter/material.dart';
import 'models/catalogue.dart';
import 'widgets/app_page.dart';
import 'inquiry_form_screen.dart';
import 'l10n/app_strings.dart';

class LoanDetailsScreen extends StatelessWidget {
  final LoanProduct loan;
  final List<Branch> branches;
  const LoanDetailsScreen(
      {super.key, required this.loan, required this.branches});
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return AppPage(
        title: loan.name,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (strings.language != 'si') Text(strings.t('catalogueLanguage')),
          DetailCard(label: strings.t('audience'), value: loan.audience),
          DetailCard(label: strings.t('amount'), value: loan.maximumAmount),
          DetailCard(label: strings.t('rate'), value: loan.interestRate),
          DetailCard(
              label: strings.t('repayment'), value: loan.repaymentPeriod),
          DetailCard(
              label: strings.t('activities'), value: loan.eligibleActivities),
          ElevatedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) =>
                          InquiryFormScreen(loan: loan, branches: branches))),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(strings.t('askScheme')))),
        ]));
  }
}
