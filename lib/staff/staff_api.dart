import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/inquiry_api.dart';
import 'staff_client.dart';
import 'staff_models.dart';

class StaffApiException implements Exception {
  final String code, message;
  const StaffApiException(this.code, this.message);
}

class StaffApi {
  final http.Client _client;
  final Uri? base;
  String? _csrf;
  StaffApi({http.Client? client, this.base})
      : _client = client ?? createStaffClient();
  Future<Map<String, dynamic>> _request(String method, String path,
      {Map<String, Object?>? body, Map<String, String>? query}) async {
    try {
      final root = base ?? apiEndpoint('/api/v1/staff/');
      final url = root.resolve(path).replace(queryParameters: query);
      final request = http.Request(method, url)
        ..headers['Content-Type'] = 'application/json';
      if (_csrf != null && method != 'GET') {
        request.headers['X-CSRF-Token'] = _csrf!;
      }
      if (body != null) request.body = jsonEncode(body);
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 204) return {};
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) throw const FormatException();
      if (response.statusCode >= 200 && response.statusCode < 300) return data;
      final error = data['error'];
      final code = error is Map ? error['code'] : null;
      final message = error is Map ? error['message'] : null;
      if (response.statusCode == 401) _csrf = null;
      throw StaffApiException(code is String ? code : 'SERVER_ERROR',
          message is String ? message : 'Request failed. Try again.');
    } on TimeoutException {
      throw const StaffApiException('NETWORK',
          'Request timed out. Retry or refresh before making another change.');
    } on http.ClientException {
      throw const StaffApiException(
          'NETWORK', 'Could not connect. Check your connection and try again.');
    } on FormatException {
      throw const StaffApiException('INVALID_RESPONSE',
          'Unexpected server response. Check the API configuration.');
    } on InquiryApiException {
      throw const StaffApiException(
          'CONFIGURATION', 'The staff API URL is not configured correctly.');
    }
  }

  StaffSession _session(Map<String, dynamic> data) {
    _csrf = data['csrfToken'] as String;
    return StaffSession.fromJson(data['staff'] as Map<String, dynamic>);
  }

  Future<StaffSession> session() async =>
      _session(await _request('GET', 'session'));
  Future<StaffSession> login(String email, String password) async =>
      _session(await _request('POST', 'login',
          body: {'email': email.trim(), 'password': password}));
  Future<void> logout() async {
    await _request('POST', 'logout', body: {});
    _csrf = null;
  }

  Future<List<StaffInstitution>> institutions() async {
    final data = await _request('GET', 'institutions');
    return (data['institutions'] as List)
        .map((x) => StaffInstitution(x['id'] as String, x['name'] as String))
        .toList();
  }

  Future<InboxPage> inbox(
      {String? status,
      String? institutionId,
      String? reference,
      String? before}) async {
    final data = await _request('GET', 'inquiries', query: {
      if (status != null && status.isNotEmpty) 'status': status,
      if (institutionId != null && institutionId.isNotEmpty)
        'institutionId': institutionId,
      if (reference != null && reference.isNotEmpty) 'reference': reference,
      if (before != null) 'before': before,
    });
    return InboxPage(
        (data['inquiries'] as List)
            .map((x) => StaffInquiry.fromJson(x as Map<String, dynamic>))
            .toList(),
        data['nextCursor'] as String?);
  }

  Future<StaffInquiry> detail(String reference) async => StaffInquiry.fromJson(
      (await _request('GET', 'inquiries/$reference'))['inquiry']
          as Map<String, dynamic>);
  Future<StaffInquiry> update(String reference, int version,
          {String? status,
          String? institutionId,
          bool changeInstitution = false}) async =>
      StaffInquiry.fromJson(
          (await _request('PATCH', 'inquiries/$reference', body: {
        'version': version,
        if (status != null) 'status': status,
        if (changeInstitution) 'institutionId': institutionId
      }))['inquiry'] as Map<String, dynamic>);
  void close() => _client.close();
}
