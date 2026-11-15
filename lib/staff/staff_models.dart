class StaffSession {
  final String id, name, role;
  const StaffSession(
      {required this.id, required this.name, required this.role});
  bool get isAdmin => role == 'admin';
  factory StaffSession.fromJson(Map<String, dynamic> json) => StaffSession(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String);
}

class StaffInstitution {
  final String id, name;
  const StaffInstitution(this.id, this.name);
}

class InquiryEvent {
  final String actorName, action, status;
  final DateTime? at;
  InquiryEvent.fromJson(Map<String, dynamic> json)
      : actorName = json['actorName'] as String? ?? '',
        action = json['action'] as String? ?? '',
        status = json['status'] as String? ?? '',
        at = DateTime.tryParse(json['at'] as String? ?? '');
}

class StaffInquiry {
  final String reference, name, loan, branch, status, telephone, email, message;
  final String? institutionId;
  final int version;
  final DateTime? createdAt;
  final List<InquiryEvent> history;
  StaffInquiry.fromJson(Map<String, dynamic> json)
      : reference = json['reference'] as String,
        name = json['name'] as String? ?? '',
        loan = json['loan'] as String? ?? '',
        branch = json['branch'] as String? ?? '',
        status = json['status'] as String,
        version = json['version'] as int,
        institutionId = json['institutionId'] as String?,
        telephone = json['telephone'] as String? ?? '',
        email = json['email'] as String? ?? '',
        message = json['message'] as String? ?? '',
        createdAt = DateTime.tryParse(json['createdAt'] as String? ?? ''),
        history = List.unmodifiable((json['history'] as List? ?? [])
            .map((x) => InquiryEvent.fromJson(x as Map<String, dynamic>)));
}

class InboxPage {
  final List<StaffInquiry> inquiries;
  final String? nextCursor;
  const InboxPage(this.inquiries, this.nextCursor);
}
