import 'package:flutter/material.dart';
import 'models/catalogue.dart';
import 'l10n/app_strings.dart';
import 'loan_options_screen.dart';
import 'inquiry_form_screen.dart';
import 'widgets/app_page.dart';

class GuidanceScreen extends StatefulWidget {
  final Catalogue catalogue;
  const GuidanceScreen({super.key, required this.catalogue});
  @override
  State<GuidanceScreen> createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen> {
  String _purpose = '', _stage = 'unsure';
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final tip = _stage == 'new'
        ? 'newTip'
        : _stage == 'existing'
            ? 'existingTip'
            : 'unsureTip';
    return AppPage(
        title: strings.t('guideTitle'),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(strings.t('guideNotice')),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
              key: const ValueKey('guide-purpose'),
              value: _purpose,
              isExpanded: true,
              decoration: InputDecoration(labelText: strings.t('purpose')),
              items: [
                DropdownMenuItem(value: '', child: Text(strings.t('unsure'))),
                for (var i = 1; i <= 4; i++)
                  DropdownMenuItem(
                      value: 'category-$i',
                      child: Text(strings.t('category$i')))
              ],
              onChanged: (value) => setState(() {
                    _purpose = value ?? '';
                  })),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
              key: const ValueKey('guide-stage'),
              value: _stage,
              isExpanded: true,
              decoration: InputDecoration(labelText: strings.t('stage')),
              items: [
                DropdownMenuItem(
                    value: 'unsure', child: Text(strings.t('unsure'))),
                DropdownMenuItem(
                    value: 'new', child: Text(strings.t('newBusiness'))),
                DropdownMenuItem(
                    value: 'existing',
                    child: Text(strings.t('existingBusiness')))
              ],
              onChanged: (value) => setState(() {
                    _stage = value ?? 'unsure';
                  })),
          const SizedBox(height: 24),
          Text(strings.t(tip)),
          const SizedBox(height: 24),
          ElevatedButton(
              key: const ValueKey('guide-explore'),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => LoanOptionsScreen(
                          loans: widget.catalogue.loans,
                          branches: widget.catalogue.branches,
                          initialCategoryId: _purpose))),
              child: Text(strings.t('viewMatches'))),
          TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => InquiryFormScreen(
                          branches: widget.catalogue.branches))),
              child: Text(strings.t('general'))),
        ]));
  }
}
