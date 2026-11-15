class InquiryRequest {
  final String name,
      nic,
      sex,
      telephone,
      address,
      email,
      message,
      loanId,
      branchId;
  final int age;
  const InquiryRequest(
      {required this.name,
      required this.age,
      required this.nic,
      required this.sex,
      required this.telephone,
      required this.address,
      required this.email,
      required this.message,
      required this.loanId,
      required this.branchId});
  Map<String, Object> toJson() => {
        'name': name.trim(),
        'age': age,
        'nic': nic.trim(),
        'sex': sex,
        'telephone': telephone.trim(),
        'address': address.trim(),
        'email': email.trim(),
        'message': message.trim(),
        'loanId': loanId,
        'branchId': branchId,
        'consent': true
      };
}

class InquiryReceipt {
  final String reference;
  const InquiryReceipt(this.reference);
}
