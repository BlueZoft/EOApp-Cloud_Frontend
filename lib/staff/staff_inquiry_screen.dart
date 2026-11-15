import 'package:flutter/material.dart';
import '../widgets/app_page.dart';
import 'staff_api.dart';
import 'staff_models.dart';

class StaffInquiryScreen extends StatefulWidget {
  final String reference;
  final StaffApi api;
  final StaffSession session;
  final List<StaffInstitution> institutions;
  const StaffInquiryScreen(
      {super.key,
      required this.reference,
      required this.api,
      required this.session,
      required this.institutions});
  @override
  State<StaffInquiryScreen> createState() => _StaffInquiryScreenState();
}

class _StaffInquiryScreenState extends State<StaffInquiryScreen> {
  StaffInquiry? _inquiry;
  String? _error, _nextStatus;
  String _institution = '';
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _setInquiry(StaffInquiry inquiry) {
    setState(() {
      _inquiry = inquiry;
      _nextStatus = null;
      _institution = inquiry.institutionId ?? '';
    });
  }

  Future<void> _reload() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final inquiry = await widget.api.detail(widget.reference);
      if (mounted) _setInquiry(inquiry);
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

  void _failure(Object error) {
    if (!mounted) return;
    setState(() {
      _error = error is StaffApiException
          ? error.message
          : 'Unable to load the inquiry. Try again.';
      if (error is StaffApiException && error.code == 'UNAUTHENTICATED') {
        _inquiry = null;
      }
    });
  }

  Future<void> _save({bool institution = false}) async {
    if (_busy || _inquiry == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final inquiry = await widget.api.update(
          widget.reference, _inquiry!.version,
          status: institution ? null : _nextStatus,
          changeInstitution: institution,
          institutionId: _institution.isEmpty ? null : _institution);
      if (mounted) _setInquiry(inquiry);
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

  @override
  Widget build(BuildContext context) {
    final inquiry = _inquiry;
    const transitions = {
      'new': ['assigned', 'closed'],
      'assigned': ['contacted', 'closed', 'new'],
      'contacted': ['closed', 'assigned'],
      'closed': ['assigned']
    };
    final options = inquiry == null
        ? <String>[]
        : transitions[inquiry.status] ?? <String>[];
    return AppPage(
        title: 'Inquiry details',
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error))),
          TextButton.icon(
              onPressed: _busy ? null : _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh inquiry')),
          if (inquiry != null) ...[
            SelectableText('Reference: ${inquiry.reference}'),
            DetailCard(label: 'Contact name', value: inquiry.name),
            DetailCard(label: 'Loan / scheme', value: inquiry.loan),
            DetailCard(label: 'Preferred branch', value: inquiry.branch),
            DetailCard(label: 'Telephone', value: inquiry.telephone),
            DetailCard(
                label: 'Email',
                value: inquiry.email.isEmpty ? 'Not provided' : inquiry.email),
            DetailCard(
                label: 'Inquiry',
                value:
                    inquiry.message.isEmpty ? 'Not provided' : inquiry.message),
            DetailCard(label: 'Status', value: inquiry.status),
            DropdownButtonFormField<String>(
                key: ValueKey('status-${inquiry.version}'),
                value: _nextStatus,
                decoration: const InputDecoration(labelText: 'Next status'),
                items: [
                  for (final status in options)
                    DropdownMenuItem(value: status, child: Text(status))
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                          _nextStatus = value;
                        })),
            ElevatedButton(
                key: const ValueKey('staff-save-status'),
                onPressed: _busy || _nextStatus == null ? null : () => _save(),
                child: const Text('Update status')),
            if (widget.session.isAdmin) ...[
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                  key: ValueKey('institution-${inquiry.version}'),
                  value: _institution,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Assigned institution'),
                  items: [
                    const DropdownMenuItem(
                        value: '', child: Text('Unassigned')),
                    if (inquiry.institutionId != null &&
                        !widget.institutions
                            .any((x) => x.id == inquiry.institutionId))
                      DropdownMenuItem(
                          value: inquiry.institutionId,
                          child: const Text('Inactive institution')),
                    for (final institution in widget.institutions)
                      DropdownMenuItem(
                          value: institution.id, child: Text(institution.name))
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() {
                            _institution = value ?? '';
                          })),
              ElevatedButton(
                  onPressed:
                      _busy || _institution == (inquiry.institutionId ?? '')
                          ? null
                          : () => _save(institution: true),
                  child: const Text('Assign institution')),
              const Text(
                  'Changing institution resets status to new. Already-sent email is not resent.'),
            ],
            const SizedBox(height: 24),
            Text('Recent activity',
                style: Theme.of(context).textTheme.titleLarge),
            if (inquiry.history.isEmpty) const Text('No staff updates yet.'),
            for (final event in inquiry.history.reversed)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${event.actorName} · ${event.status}'),
                  subtitle: Text(
                      '${event.action == 'institution_changed' ? 'Institution changed' : 'Status changed'} · ${event.at?.toLocal().toString() ?? ''}')),
          ],
        ]));
  }
}
