import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/inquiry.dart';

class InquiryApiException implements Exception {
  final String code;
  final Map<String, String> fields;
  const InquiryApiException(this.code, [this.fields = const {}]);
}

String newSubmissionKey() {
  final random = Random.secure();
  return List.generate(
      24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

Uri inquiryEndpoint() => apiEndpoint('/api/v1/inquiries');

Uri apiEndpoint(String path) {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isEmpty) {
    if (kIsWeb && (kDebugMode || Uri.base.scheme == 'https')) {
      return Uri.base.resolve(path);
    }
    throw const InquiryApiException('CONFIGURATION');
  }
  final base = Uri.parse(configured);
  const local = ['localhost', '127.0.0.1', '10.0.2.2'];
  if (!base.hasAuthority ||
      (base.scheme != 'https' &&
          !(kDebugMode &&
              base.scheme == 'http' &&
              local.contains(base.host))) ||
      base.userInfo.isNotEmpty ||
      base.hasQuery ||
      base.hasFragment) {
    throw const InquiryApiException('CONFIGURATION');
  }
  return Uri.parse('${configured.replaceAll(RegExp(r'/+$'), '')}$path');
}

class InquiryApi {
  final http.Client _client;
  final Uri? endpoint;
  final Duration timeout;
  InquiryApi(
      {http.Client? client,
      this.endpoint,
      this.timeout = const Duration(seconds: 20)})
      : _client = client ?? http.Client();
  Future<InquiryReceipt> submit(InquiryRequest request, String key) async {
    try {
      final response = await _client
          .post(endpoint ?? inquiryEndpoint(),
              headers: {
                'Content-Type': 'application/json',
                'Idempotency-Key': key
              },
              body: jsonEncode(request.toJson()))
          .timeout(timeout);
      final dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw const InquiryApiException('INVALID_RESPONSE');
      }
      if (data is! Map<String, dynamic>) {
        throw const InquiryApiException('INVALID_RESPONSE');
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        final receipt = data['inquiry'];
        if (receipt is! Map ||
            receipt['status'] != 'received' ||
            receipt['reference'] is! String ||
            (receipt['reference'] as String).isEmpty) {
          throw const InquiryApiException('INVALID_RESPONSE');
        }
        return InquiryReceipt(receipt['reference'] as String);
      }
      final error = data['error'];
      final fields = error is Map ? error['fields'] : null;
      throw InquiryApiException(
          error is Map && error['code'] is String
              ? error['code'] as String
              : 'SERVER_ERROR',
          fields is Map
              ? fields.map((k, v) => MapEntry(k.toString(), v.toString()))
              : const {});
    } on TimeoutException {
      throw const InquiryApiException('TIMEOUT');
    } on http.ClientException {
      throw const InquiryApiException('NETWORK');
    }
  }

  void close() => _client.close();
}
