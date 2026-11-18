import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_frontend/staff/staff_api.dart';
import 'package:flutter_frontend/staff/staff_portal_screen.dart';
import 'package:flutter_frontend/staff/staff_inquiry_screen.dart';
import 'package:flutter_frontend/staff/staff_models.dart';

const reference = '0123456789abcdef01234567';
Map<String, Object?> inquiry({int version = 0, String status = 'new'}) => {
      'reference': reference,
      'name': 'Synthetic Person',
      'loan': 'Test scheme',
      'branch': 'Test branch',
      'institutionId': 'institution-a',
      'status': status,
      'version': version,
      'createdAt': '2026-01-01T00:00:00Z',
      'telephone': '0771234567',
      'email': '',
      'message': 'Please call',
      'history': [],
    };
http.Response response(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);
void main() {
  test('invalid login keeps its credential error even for non-JSON replies',
      () async {
    final api = StaffApi(
        base: Uri.parse('https://test/api/v1/staff/'),
        client: MockClient((_) async => http.Response('Unauthorized', 401)));
    addTearDown(api.close);
    await expectLater(
        api.login('wrong@local.test', 'wrong-password'),
        throwsA(isA<StaffApiException>()
            .having((e) => e.code, 'code', 'INVALID_LOGIN')));
  });
  test('malformed staff success payloads produce a typed error', () async {
    for (final entry in <String, Object>{
      'session': {'staff': null, 'csrfToken': 'test-csrf'},
      'institutions': {
        'institutions': [null]
      },
      'inbox': {
        'inquiries': [
          {'reference': 42}
        ]
      },
      'detail': {
        'inquiry': {...inquiry(), 'version': 'wrong'}
      },
    }.entries) {
      final api = StaffApi(
          base: Uri.parse('https://test/api/v1/staff/'),
          client: MockClient((_) async => response(entry.value)));
      addTearDown(api.close);
      final Future<Object?> result;
      switch (entry.key) {
        case 'session':
          result = api.session();
          break;
        case 'institutions':
          result = api.institutions();
          break;
        case 'inbox':
          result = api.inbox();
          break;
        default:
          result = api.detail(reference);
      }
      await expectLater(
          result,
          throwsA(isA<StaffApiException>()
              .having((e) => e.code, 'code', 'INVALID_RESPONSE')),
          reason: entry.key);
    }
  });
  test('non-JSON unauthorized replies revoke client CSRF state', () async {
    final seen = <http.Request>[];
    final api = StaffApi(
        base: Uri.parse('https://test/api/v1/staff/'),
        client: MockClient((req) async {
          seen.add(req);
          if (req.url.path.endsWith('/login')) {
            return response({
              'staff': {'id': 'a', 'name': 'Officer', 'role': 'officer'},
              'csrfToken': 'test-csrf'
            });
          }
          return http.Response('<html>Session expired</html>', 401);
        }));
    addTearDown(api.close);
    await api.login('a@local.test', 'test-password');
    for (final call in [
      () => api.logout(),
      () => api.update(reference, 0, status: 'assigned')
    ]) {
      await expectLater(
          call(),
          throwsA(isA<StaffApiException>()
              .having((e) => e.code, 'code', 'UNAUTHENTICATED')));
    }
    expect(seen.last.headers.containsKey('X-CSRF-Token'), false);
  });
  testWidgets(
      'withdrawn inquiry access removes previously loaded contact details',
      (tester) async {
    var reads = 0;
    final api = StaffApi(
        base: Uri.parse('https://test/api/v1/staff/'),
        client: MockClient((_) async => ++reads == 1
            ? response({'inquiry': inquiry()})
            : response({
                'error': {'code': 'NOT_FOUND', 'message': 'Inquiry not found'}
              }, 404)));
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(
        home: StaffInquiryScreen(
            reference: reference,
            api: api,
            session:
                const StaffSession(id: 'a', name: 'Officer', role: 'officer'),
            institutions: const [])));
    await tester.pumpAndSettle();
    expect(find.text('0771234567'), findsOneWidget);
    await tester.tap(find.text('Refresh inquiry'));
    await tester.pumpAndSettle();
    expect(find.text('0771234567'), findsNothing);
    expect(find.text('Synthetic Person'), findsNothing);
    expect(find.text('Inquiry not found'), findsOneWidget);
  });
  test(
      'staff mutations include CSRF and expected version; conflicts remain visible',
      () async {
    final seen = <http.Request>[];
    final api = StaffApi(
        base: Uri.parse('https://test/api/v1/staff/'),
        client: MockClient((req) async {
          seen.add(req);
          if (req.url.path.endsWith('/login')) {
            return response({
              'staff': {'id': 'staff-a', 'name': 'Officer', 'role': 'officer'},
              'csrfToken': 'test-csrf'
            });
          }
          return response({
            'error': {
              'code': 'STALE_INQUIRY',
              'message': 'Refresh before saving'
            }
          }, 409);
        }));
    addTearDown(api.close);
    await api.login('officer@local.test', 'synthetic-password');
    await expectLater(
        api.update(reference, 3, status: 'assigned'),
        throwsA(isA<StaffApiException>()
            .having((e) => e.code, 'code', 'STALE_INQUIRY')));
    expect(seen.last.headers['X-CSRF-Token'], 'test-csrf');
    expect(jsonDecode(seen.last.body), {'version': 3, 'status': 'assigned'});
  });
  test('staff filters and pagination are encoded without broadening scope',
      () async {
    final seen = <http.Request>[];
    final api = StaffApi(
        base: Uri.parse('https://test/api/v1/staff/'),
        client: MockClient((req) async {
          seen.add(req);
          return response({
            'inquiries': [inquiry()],
            'nextCursor': reference
          });
        }));
    addTearDown(api.close);
    final page = await api.inbox(status: 'new', before: reference);
    expect(page.inquiries.single.reference, reference);
    expect(page.nextCursor, reference);
    expect(seen.single.url.queryParameters,
        {'status': 'new', 'before': reference});
  });
  test('expired sessions are explicit and malformed responses are not accepted',
      () async {
    final api = StaffApi(
        base: Uri.parse('https://test/api/v1/staff/'),
        client: MockClient((_) async => response({
              'error': {'code': 'UNAUTHENTICATED', 'message': 'Sign in'}
            }, 401)));
    addTearDown(api.close);
    await expectLater(
        api.session(),
        throwsA(isA<StaffApiException>()
            .having((e) => e.code, 'code', 'UNAUTHENTICATED')));
    final malformed = StaffApi(
        base: Uri.parse('https://test/api/v1/staff/'),
        client: MockClient(
            (_) async => http.Response('<html>Not the API</html>', 200)));
    addTearDown(malformed.close);
    await expectLater(
        malformed.session(),
        throwsA(isA<StaffApiException>()
            .having((e) => e.code, 'code', 'INVALID_RESPONSE')));
  });
  testWidgets(
      'officer can sign in, open an inquiry and update status on a narrow screen',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var signedIn = false, version = 0;
    final api = StaffApi(
        base: Uri.parse('https://test/api/v1/staff/'),
        client: MockClient((req) async {
          final path = req.url.path;
          if (path.endsWith('/login')) signedIn = true;
          if (path.endsWith('/session') || path.endsWith('/login')) {
            if (!signedIn) {
              return response({
                'error': {'code': 'UNAUTHENTICATED', 'message': 'Sign in'}
              }, 401);
            }
            return response({
              'staff': {
                'id': 'staff-a',
                'name': 'Test Officer',
                'role': 'officer'
              },
              'csrfToken': 'test-csrf'
            });
          }
          if (path.endsWith('/institutions')) {
            return response({
              'institutions': [
                {'id': 'institution-a', 'name': 'Institution A'}
              ]
            });
          }
          if (path.endsWith('/inquiries')) {
            return response({
              'inquiries': [
                inquiry(
                    version: version, status: version == 0 ? 'new' : 'assigned')
              ],
              'nextCursor': null
            });
          }
          if (path.endsWith('/$reference')) {
            if (req.method == 'PATCH') {
              expect(req.headers['X-CSRF-Token'], 'test-csrf');
              expect(jsonDecode(req.body)['version'], 0);
              version++;
            }
            return response({
              'inquiry': inquiry(
                  version: version, status: version == 0 ? 'new' : 'assigned')
            });
          }
          throw StateError('Unexpected test request');
        }));
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(home: StaffPortalScreen(api: api)));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('staff-email')), 'officer@local.test');
    await tester.enterText(
        find.byKey(const ValueKey('staff-password')), 'synthetic-password');
    await tester.tap(find.byKey(const ValueKey('staff-login')));
    await tester.pumpAndSettle();
    expect(find.text('Synthetic Person'), findsOneWidget);
    expect(find.text('Assigned institution'), findsNothing);
    await tester.ensureVisible(find.text('Synthetic Person'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Synthetic Person'));
    await tester.pumpAndSettle();
    expect(find.text('Please call'), findsOneWidget);
    expect(find.text('Assign institution'), findsNothing);
    final status = find.byKey(const ValueKey('status-0'));
    await tester.ensureVisible(status);
    await tester.pumpAndSettle();
    await tester.tap(status);
    await tester.pumpAndSettle();
    await tester.tap(find.text('assigned').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('staff-save-status')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('staff-save-status')));
    await tester.pumpAndSettle();
    expect(version, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'administrator assigns an unassigned inquiry without mixing in a status update',
      (tester) async {
    final requests = <http.Request>[];
    final api = StaffApi(
        base: Uri.parse('https://test/api/v1/staff/'),
        client: MockClient((req) async {
          requests.add(req);
          if (req.url.path.endsWith('/session')) {
            return response({
              'staff': {'id': 'admin', 'name': 'Admin', 'role': 'admin'},
              'csrfToken': 'test-csrf'
            });
          }
          return response({
            'inquiry': {
              ...inquiry(version: req.method == 'PATCH' ? 1 : 0),
              'institutionId': req.method == 'PATCH' ? 'institution-a' : null
            }
          });
        }));
    addTearDown(api.close);
    final session = await api.session();
    await tester.pumpWidget(MaterialApp(
        home: StaffInquiryScreen(
            reference: reference,
            api: api,
            session: session,
            institutions: const [
          StaffInstitution('institution-a', 'Institution A')
        ])));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('institution-0'));
    await tester.scrollUntilVisible(field, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Institution A').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Assign institution'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assign institution'));
    await tester.pumpAndSettle();
    final patch = requests.singleWhere((x) => x.method == 'PATCH');
    expect(jsonDecode(patch.body),
        {'version': 0, 'institutionId': 'institution-a'});
    expect(patch.headers['X-CSRF-Token'], 'test-csrf');
    expect(tester.takeException(), isNull);
  });
}
