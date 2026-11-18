import 'package:flutter/material.dart';
import '../widgets/app_page.dart';
import 'staff_api.dart';
import 'staff_models.dart';
import 'staff_inquiry_screen.dart';

class StaffPortalScreen extends StatefulWidget {
  final StaffApi? api;
  const StaffPortalScreen({super.key, this.api});
  @override
  State<StaffPortalScreen> createState() => _StaffPortalScreenState();
}

class _StaffPortalScreenState extends State<StaffPortalScreen> {
  late final _api = widget.api ?? StaffApi();
  final _email = TextEditingController(),
      _password = TextEditingController(),
      _reference = TextEditingController();
  final _loginForm = GlobalKey<FormState>();
  StaffSession? _session;
  List<StaffInstitution> _institutions = [];
  List<StaffInquiry> _inquiries = [];
  String? _cursor, _error;
  String _status = '', _institution = '';
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    _restore();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _reference.dispose();
    if (widget.api == null) _api.close();
    super.dispose();
  }

  void _failure(Object error) {
    if (!mounted) return;
    setState(() {
      if (error is StaffApiException && error.code == 'UNAUTHENTICATED') {
        _session = null;
        _inquiries = [];
        _institutions = [];
        _cursor = null;
        _status = '';
        _institution = '';
        _reference.clear();
      }
      _error = error is StaffApiException
          ? error.message
          : 'Unable to load the inbox. Please try again.';
    });
  }

  Future<void> _restore() async {
    try {
      final session = await _api.session();
      if (!mounted) return;
      _session = session;
      await _load();
    } on StaffApiException catch (error) {
      if (error.code != 'UNAUTHENTICATED') _failure(error);
    } catch (error) {
      _failure(error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (_busy || !_loginForm.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await _api.login(_email.text, _password.text);
      if (!mounted) return;
      _password.clear();
      setState(() {
        _session = session;
      });
      await _load();
    } catch (error) {
      _failure(error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.logout();
      if (!mounted) return;
      setState(() {
        _session = null;
        _inquiries = [];
        _institutions = [];
        _reference.clear();
        _status = '';
        _institution = '';
      });
    } catch (error) {
      _failure(error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _load({bool more = false}) async {
    if (!mounted || _session == null) return;
    if (mounted) {
      setState(() {
        _busy = true;
        _error = null;
        if (!more) {
          _inquiries = [];
          _cursor = null;
        }
      });
    }
    try {
      final institutions = await _api.institutions();
      final page = await _api.inbox(
          status: _status,
          institutionId: _session!.isAdmin ? _institution : null,
          reference: _reference.text.trim(),
          before: more ? _cursor : null);
      if (!mounted) return;
      setState(() {
        _institutions = institutions;
        _inquiries = more ? [..._inquiries, ...page.inquiries] : page.inquiries;
        _cursor = page.nextCursor;
      });
    } catch (error) {
      _failure(error);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _open(StaffInquiry inquiry) async {
    await Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => StaffInquiryScreen(
                reference: inquiry.reference,
                api: _api,
                session: _session!,
                institutions: _institutions)));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'Officer inbox',
      child: ListView(padding: const EdgeInsets.all(16), children: [
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        if (_session == null) ...[
          const Text('Staff sign-in', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 12),
          const Text(
              'Authorized staff only. Accounts are provisioned by your administrator.'),
          const SizedBox(height: 16),
          Form(
              key: _loginForm,
              child: Column(children: [
                TextFormField(
                    key: const ValueKey('staff-email'),
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(labelText: 'Staff email'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter your email'
                        : null),
                TextFormField(
                    key: const ValueKey('staff-password'),
                    controller: _password,
                    enabled: !_busy,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your password' : null,
                    onFieldSubmitted: (_) => _login()),
                const SizedBox(height: 16),
                ElevatedButton(
                    key: const ValueKey('staff-login'),
                    onPressed: _busy ? null : _login,
                    child: const Text('Sign in')),
              ])),
        ] else ...[
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                    '${_session!.name} · ${_session!.isAdmin ? 'Administrator' : 'Officer'}'),
                TextButton(
                    onPressed: _busy ? null : _logout,
                    child: const Text('Sign out')),
              ]),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
              key: const ValueKey('staff-status-filter'),
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                const DropdownMenuItem(value: '', child: Text('All statuses')),
                for (final status in ['new', 'assigned', 'contacted', 'closed'])
                  DropdownMenuItem(value: status, child: Text(status))
              ],
              onChanged: _busy
                  ? null
                  : (v) {
                      _status = v ?? '';
                      _load();
                    }),
          if (_session!.isAdmin)
            DropdownButtonFormField<String>(
                value: _institution,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Institution'),
                items: [
                  const DropdownMenuItem(
                      value: '', child: Text('All institutions')),
                  const DropdownMenuItem(
                      value: 'unassigned', child: Text('Unassigned')),
                  if (_institution.isNotEmpty &&
                      _institution != 'unassigned' &&
                      !_institutions.any((x) => x.id == _institution))
                    DropdownMenuItem(
                        value: _institution,
                        child: const Text('Inactive institution')),
                  for (final institution in _institutions)
                    DropdownMenuItem(
                        value: institution.id, child: Text(institution.name))
                ],
                onChanged: _busy
                    ? null
                    : (v) {
                        _institution = v ?? '';
                        _load();
                      }),
          TextField(
              key: const ValueKey('staff-reference-filter'),
              controller: _reference,
              enabled: !_busy,
              decoration: InputDecoration(
                  labelText: 'Exact inquiry reference (optional)',
                  suffixIcon: IconButton(
                      tooltip: 'Search reference',
                      onPressed: _busy ? null : () => _load(),
                      icon: const Icon(Icons.search))),
              onSubmitted: (_) => _load()),
          TextButton.icon(
              onPressed: _busy ? null : () => _load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh inbox')),
          if (!_busy && _inquiries.isEmpty && _error == null)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No inquiries match these filters.')),
          for (final inquiry in _inquiries)
            Semantics(
                key: ValueKey('staff-case-${inquiry.reference}'),
                container: true,
                label:
                    '${inquiry.name}\n${inquiry.loan}\n${inquiry.branch} · ${inquiry.status}',
                button: true,
                enabled: !_busy,
                excludeSemantics: true,
                onTap: _busy ? null : () => _open(inquiry),
                child: Card(
                    child: ListTile(
                        isThreeLine: true,
                        title: Text(inquiry.name),
                        subtitle: Text(
                            '${inquiry.loan}\n${inquiry.branch} · ${inquiry.status}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _busy ? null : () => _open(inquiry)))),
          if (_cursor != null)
            TextButton(
                onPressed: _busy ? null : () => _load(more: true),
                child: const Text('Load more')),
        ],
      ]));
}
