import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_frontend/services/inquiry_api.dart';
import 'package:flutter_frontend/services/validators.dart';
import 'package:flutter_frontend/models/inquiry.dart';
import 'package:flutter_frontend/models/catalogue.dart';
import 'package:flutter_frontend/inquiry_form_screen.dart';
import 'package:flutter_frontend/data/catalogue_repository.dart';

const request = InquiryRequest(
    name: 'Test Person',
    age: 30,
    nic: '199012345678',
    sex: 'female',
    telephone: '0771234567',
    address: 'Address',
    email: '',
    message: '',
    loanId: 'general',
    branchId: 'branch-001');
void main() {
  test('age validation rejects text and range errors without throwing', () {
    for (final value in ['', 'abc', '17', '100', '1.5']) {
      expect(Validators.age(value), isNotNull);
    }
    expect(Validators.age('18'), isNull);
    expect(Validators.age('99'), isNull);
    expect(Validators.nic('199012345678'), isNull);
    expect(Validators.telephone('0771234567'), isNull);
    expect(Validators.email(''), isNull);
    expect(Validators.email('wrong'), isNotNull);
  });
  test('arbitrary 200 error body is never a receipt', () async {
    final api = InquiryApi(
        client: MockClient(
            (_) async => http.Response('{"message":"validation failed"}', 200)),
        endpoint: Uri.parse('https://test/api'));
    addTearDown(api.close);
    await expectLater(
        api.submit(request, 'same-submission-key'),
        throwsA(isA<InquiryApiException>()
            .having((e) => e.code, 'code', 'INVALID_RESPONSE')));
  });
  test('retry sends same key and payload; receipt is parsed', () async {
    final seen = <http.Request>[];
    final api = InquiryApi(
        client: MockClient((req) async {
          seen.add(req);
          if (seen.length == 1) throw http.ClientException('offline');
          return http.Response(
              '{"inquiry":{"reference":"ref-1","status":"received"}}', 201);
        }),
        endpoint: Uri.parse('https://test/api'));
    addTearDown(api.close);
    await expectLater(api.submit(request, 'same-submission-key'),
        throwsA(isA<InquiryApiException>()));
    expect(
        (await api.submit(request, 'same-submission-key')).reference, 'ref-1');
    expect(
        seen[0].headers['Idempotency-Key'], seen[1].headers['Idempotency-Key']);
    expect(seen[0].body, seen[1].body);
    expect(jsonDecode(seen[0].body)['consent'], true);
  });
  test('timeout and field errors are explicit', () async {
    final api = InquiryApi(
        client: MockClient((_) => Completer<http.Response>().future),
        endpoint: Uri.parse('https://test/api'),
        timeout: const Duration(milliseconds: 5));
    addTearDown(api.close);
    await expectLater(
        api.submit(request, 'same-submission-key'),
        throwsA(isA<InquiryApiException>()
            .having((e) => e.code, 'code', 'TIMEOUT')));
    final invalid = InquiryApi(
        client: MockClient((_) async => http.Response(
            '{"error":{"code":"VALIDATION_ERROR","fields":{"age":"invalid"}}}',
            422)),
        endpoint: Uri.parse('https://test/api'));
    addTearDown(invalid.close);
    await expectLater(
        invalid.submit(request, 'same-submission-key'),
        throwsA(isA<InquiryApiException>()
            .having((e) => e.fields['age'], 'age', 'invalid')));
  });
  testWidgets('catalogue loads all original schemes and branches',
      (tester) async {
    final catalogue = await loadCatalogue();
    expect(catalogue.loans.length, 15);
    expect(catalogue.branches.length, 276);
    expect(catalogue.loans.map((x) => x.id).toSet().length, 15);
    expect(
        catalogue.loans.where((x) => x.categoryId == 'category-3').length, 5);
  });
  testWidgets(
      'narrow form validates and prevents repeated submission; retry keeps payload',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final seen = <http.Request>[];
    final pending = Completer<http.Response>();
    final api = InquiryApi(
        endpoint: Uri.parse('https://test/api'),
        client: MockClient((req) {
          seen.add(req);
          if (seen.length == 1) return pending.future;
          return Future.value(http.Response(
              '{"inquiry":{"reference":"ref-2","status":"received"}}', 200));
        }));
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(
        home: InquiryFormScreen(
            branches: const [Branch('branch-001', 'Test branch')], api: api)));
    final values = {
      'name': 'Test Person',
      'age': '30',
      'nic': '199012345678',
      'telephone': '0771234567',
      'address': 'Address'
    };
    for (final entry in values.entries) {
      final field = find.byKey(ValueKey(entry.key));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
      await tester.pump();
    }
    await tester.ensureVisible(find.byKey(const ValueKey('sex')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sex')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ස්ත්‍රී').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('branch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('branch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test branch'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pump();
    expect(seen.length, 1);
    expect(
        tester
            .widget<ElevatedButton>(find.byKey(const ValueKey('submit')))
            .onPressed,
        isNull);
    pending.completeError(http.ClientException('offline'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pumpAndSettle();
    expect(seen.length, 2);
    expect(seen[0].body, seen[1].body);
    expect(
        seen[0].headers['Idempotency-Key'], seen[1].headers['Idempotency-Key']);
    expect(find.textContaining('ref-2'), findsOneWidget);
    expect(find.byKey(const ValueKey('submit')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
