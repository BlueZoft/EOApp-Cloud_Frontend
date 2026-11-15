import '../models/catalogue.dart';
import '../l10n/translations.dart';

class LoanDiscovery {
  static List<LoanProduct> filter(List<LoanProduct> loans,
      {String query = '', String? categoryId}) {
    final terms = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((x) => x.isNotEmpty);
    return loans.where((loan) {
      if (categoryId != null &&
          categoryId.isNotEmpty &&
          loan.categoryId != categoryId) return false;
      final categoryKey = 'category${loan.categoryId.split('-').last}';
      final text = [
        loan.name,
        loan.description,
        loan.audience,
        loan.eligibleActivities,
        loan.interestRate,
        loan.maximumAmount,
        loan.repaymentPeriod,
        for (final strings in uiTranslations.values) strings[categoryKey] ?? '',
      ].join(' ').toLowerCase();
      return terms.every(text.contains);
    }).toList();
  }
}

class ComparisonSelection {
  static const maximum = 3;
  final List<String> _ids = [];
  List<String> get ids => List.unmodifiable(_ids);
  bool get canCompare => _ids.length >= 2;
  bool contains(String id) => _ids.contains(id);
  bool add(String id) {
    if (_ids.contains(id)) return true;
    if (_ids.length == maximum) return false;
    _ids.add(id);
    return true;
  }

  void remove(String id) => _ids.remove(id);
  void clear() => _ids.clear();
  List<LoanProduct> resolve(List<LoanProduct> loans) => [
        for (final id in _ids) ...loans.where((loan) => loan.id == id),
      ];
}
