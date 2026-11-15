class LoanProduct {
  final String id,
      categoryId,
      name,
      description,
      audience,
      interestRate,
      maximumAmount,
      repaymentPeriod,
      eligibleActivities;
  const LoanProduct(
      {required this.id,
      required this.categoryId,
      required this.name,
      required this.description,
      required this.audience,
      required this.interestRate,
      required this.maximumAmount,
      required this.repaymentPeriod,
      required this.eligibleActivities});
  factory LoanProduct.fromJson(Map<String, dynamic> json) => LoanProduct(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      name: json['lName'] as String,
      description: json['sDes'] as String,
      audience: json['forWho'] as String,
      interestRate: json['iRate'] as String,
      maximumAmount: json['maxLimit'] as String,
      repaymentPeriod: json['maxRepay'] as String,
      eligibleActivities: json['eligibles'] as String);
}

class Branch {
  final String id, name;
  const Branch(this.id, this.name);
}

class Catalogue {
  final List<LoanProduct> loans;
  final List<Branch> branches;
  const Catalogue(this.loans, this.branches);
  factory Catalogue.fromJson(Map<String, dynamic> json) => Catalogue(
      List.unmodifiable((json['loans'] as List)
          .map((x) => LoanProduct.fromJson(x as Map<String, dynamic>))),
      List.unmodifiable((json['branches'] as List)
          .map((x) => Branch(x['id'] as String, x['name'] as String))));
}
