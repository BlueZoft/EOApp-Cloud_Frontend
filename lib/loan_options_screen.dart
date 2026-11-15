import 'package:flutter/material.dart';
import 'models/catalogue.dart';
import 'loan_details_screen.dart';
import 'widgets/app_page.dart';

class LoanOptionsScreen extends StatelessWidget {
  final List<LoanProduct> loans;
  final List<Branch> branches;
  const LoanOptionsScreen(
      {super.key, required this.loans, required this.branches});
  @override
  Widget build(BuildContext context) => AppPage(
      title: 'ඔබ සඳහාම වන මූල්‍ය පහසුකම්',
      child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: loans.length,
          itemBuilder: (context, index) {
            final loan = loans[index];
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(loan.name,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text(loan.description),
                          TextButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                      builder: (_) => LoanDetailsScreen(
                                          loan: loan, branches: branches))),
                              child: const Text('ඔබ දැනගතයුතු කරුණු'))
                        ])));
          }));
}
