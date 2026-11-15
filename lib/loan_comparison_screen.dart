import 'package:flutter/material.dart';
import 'models/catalogue.dart';
import 'l10n/app_strings.dart';
import 'loan_details_screen.dart';
import 'widgets/app_page.dart';

class LoanComparisonScreen extends StatefulWidget {
  final List<LoanProduct> loans;
  final List<Branch> branches;
  const LoanComparisonScreen(
      {super.key, required this.loans, required this.branches});
  @override
  State<LoanComparisonScreen> createState() => _LoanComparisonScreenState();
}

class _LoanComparisonScreenState extends State<LoanComparisonScreen> {
  final _horizontal = ScrollController();
  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final rows = <String, String Function(LoanProduct)>{
      'audience': (x) => x.audience,
      'amount': (x) => x.maximumAmount,
      'rate': (x) => x.interestRate,
      'repayment': (x) => x.repaymentPeriod,
      'activities': (x) => x.eligibleActivities,
    };
    return AppPage(
        title: strings.t('comparison'),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(strings.t('readTerms')),
          if (strings.language != 'si')
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(strings.t('catalogueLanguage'))),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(strings.t('scrollCompare'))),
          Scrollbar(
              controller: _horizontal,
              thumbVisibility: true,
              child: SingleChildScrollView(
                key: const ValueKey('comparison-scroll'),
                controller: _horizontal,
                scrollDirection: Axis.horizontal,
                child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Table(
                      defaultColumnWidth: const FixedColumnWidth(220),
                      columnWidths: const {0: FixedColumnWidth(150)},
                      border: TableBorder.all(
                          color: Theme.of(context).dividerColor),
                      defaultVerticalAlignment: TableCellVerticalAlignment.top,
                      children: [
                        TableRow(children: [
                          Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(strings.t('schemes'))),
                          for (final loan in widget.loans)
                            Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(loan.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      TextButton(
                                          onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      LoanDetailsScreen(
                                                          loan: loan,
                                                          branches: widget
                                                              .branches))),
                                          child: Text(strings.t('details'))),
                                    ])),
                        ]),
                        for (final entry in rows.entries)
                          TableRow(children: [
                            Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(strings.t(entry.key),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium)),
                            for (final loan in widget.loans)
                              Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Semantics(
                                      label:
                                          '${loan.name}: ${strings.t(entry.key)}: ${entry.value(loan)}',
                                      excludeSemantics: true,
                                      child: Text(entry.value(loan)))),
                          ]),
                      ],
                    )),
              )),
        ]));
  }
}
