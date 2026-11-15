import 'package:flutter/material.dart';
import 'models/catalogue.dart';
import 'widgets/app_page.dart';
import 'inquiry_form_screen.dart';

class LoanDetailsScreen extends StatelessWidget {
  final LoanProduct loan;
  final List<Branch> branches;
  const LoanDetailsScreen(
      {super.key, required this.loan, required this.branches});
  @override
  Widget build(BuildContext context) => AppPage(
      title: loan.name,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        DetailCard(label: 'කවුරුන් සඳහා ද?', value: loan.audience),
        DetailCard(label: 'උපරිම ණය මුදල', value: loan.maximumAmount),
        DetailCard(label: 'ණය පොළිය', value: loan.interestRate),
        DetailCard(
            label: 'උපරිම ආපසු ගෙවීමේ කාල සීමාව', value: loan.repaymentPeriod),
        DetailCard(
            label: 'සුදුසුකම් ලබන ව්‍යාපෘති/ව්‍යාපාර',
            value: loan.eligibleActivities),
        ElevatedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                    builder: (_) =>
                        InquiryFormScreen(loan: loan, branches: branches))),
            child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('මෙම මූල්‍ය පහසුකම පිළිබඳ විමසීමට පිවිසෙන්න…')))
      ]));
}
