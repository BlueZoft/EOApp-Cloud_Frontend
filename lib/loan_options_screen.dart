import 'package:flutter/material.dart';
import 'models/catalogue.dart';
import 'loan_details_screen.dart';
import 'loan_comparison_screen.dart';
import 'services/loan_discovery.dart';
import 'widgets/app_page.dart';
import 'l10n/app_strings.dart';

class LoanOptionsScreen extends StatefulWidget {
  final List<LoanProduct> loans;
  final List<Branch> branches;
  final String? initialCategoryId;
  const LoanOptionsScreen(
      {super.key,
      required this.loans,
      required this.branches,
      this.initialCategoryId});
  @override
  State<LoanOptionsScreen> createState() => _LoanOptionsScreenState();
}

class _LoanOptionsScreenState extends State<LoanOptionsScreen> {
  final _search = TextEditingController();
  final _selection = ComparisonSelection();
  late String _category = widget.initialCategoryId ?? '';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggle(LoanProduct loan, bool selected) {
    if (selected && !_selection.add(loan.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).t('compareLimit'))));
    } else if (!selected) {
      _selection.remove(loan.id);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final loans = LoanDiscovery.filter(widget.loans,
        query: _search.text, categoryId: _category);
    final selected = _selection.resolve(widget.loans);
    final categories = widget.loans.map((x) => x.categoryId).toSet().toList()
      ..sort();
    return AppPage(
        title: strings.t('schemes'),
        child: LayoutBuilder(builder: (context, constraints) {
          // Short screens and the on-screen keyboard need one scrolling flow.
          // Taller views retain their fixed search and comparison controls.
          final compact = constraints.maxHeight < 480;
          final header = Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                        key: const ValueKey('loan-search'),
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                            labelText: strings.t('search'),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                                tooltip: strings.t('clear'),
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _search.clear();
                                  setState(() {});
                                }))),
                    DropdownButtonFormField<String>(
                        key: const ValueKey('loan-category'),
                        value: _category,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                              value: '',
                              child: Text(strings.t('allCategories'))),
                          for (final category in categories)
                            DropdownMenuItem(
                                value: category,
                                child: Text(strings
                                    .t('category${category.split('-').last}')))
                        ],
                        onChanged: (value) => setState(() {
                              _category = value ?? '';
                            })),
                    if (strings.language != 'si')
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(strings.t('catalogueLanguage'))),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('${strings.t('results')}: ${loans.length}',
                            semanticsLabel:
                                '${strings.t('results')}: ${loans.length}')),
                  ]));
          final results = loans.isEmpty
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(strings.t('noResults'))))
              : ListView.builder(
                  key: const ValueKey('loan-results'),
                  shrinkWrap: compact,
                  physics:
                      compact ? const NeverScrollableScrollPhysics() : null,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: loans.length,
                  itemBuilder: (context, index) {
                    final loan = loans[index];
                    return Card(
                        key: ValueKey('loan-${loan.id}'),
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(loan.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  const SizedBox(height: 8),
                                  Text(loan.description),
                                  CheckboxListTile(
                                      key: ValueKey('compare-${loan.id}'),
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                          '${strings.t('selectCompare')}: ${loan.name}'),
                                      value: _selection.contains(loan.id),
                                      onChanged: (value) =>
                                          _toggle(loan, value ?? false)),
                                  TextButton(
                                      onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                              builder: (_) => LoanDetailsScreen(
                                                  loan: loan,
                                                  branches: widget.branches))),
                                      child: Text(strings.t('details'))),
                                ])));
                  });
          final footer = SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected.isNotEmpty)
                          SizedBox(
                              height: 48,
                              child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    for (final loan in selected)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: InputChip(
                                              label: Text(loan.name),
                                              deleteButtonTooltipMessage:
                                                  strings.t('remove'),
                                              onDeleted: () => setState(() {
                                                    _selection.remove(loan.id);
                                                  }))),
                                  ])),
                        Row(children: [
                          Expanded(child: Text(strings.t('compareHint'))),
                          const SizedBox(width: 8),
                          ElevatedButton(
                              key: const ValueKey('compare-open'),
                              onPressed: _selection.canCompare
                                  ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                          builder: (_) => LoanComparisonScreen(
                                              loans: selected,
                                              branches: widget.branches)))
                                  : null,
                              child: Text(
                                  '${strings.t('compare')} (${selected.length}/3)'))
                        ]),
                      ])));
          return compact
              ? ListView(children: [header, results, footer])
              : Column(children: [header, Expanded(child: results), footer]);
        }));
  }
}
