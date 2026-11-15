import 'package:flutter/material.dart';
import 'models/catalogue.dart';
import 'models/inquiry.dart';
import 'services/inquiry_api.dart';
import 'services/validators.dart';
import 'widgets/app_page.dart';
import 'l10n/si.dart';

class InquiryFormScreen extends StatefulWidget {
  final LoanProduct? loan;
  final List<Branch> branches;
  final InquiryApi? api;
  const InquiryFormScreen(
      {super.key, this.loan, required this.branches, this.api});
  @override
  State<InquiryFormScreen> createState() => _InquiryFormScreenState();
}

class _InquiryFormScreenState extends State<InquiryFormScreen> {
  final _form = GlobalKey<FormState>();
  final _controllers = {
    for (final key in [
      'name',
      'age',
      'nic',
      'telephone',
      'address',
      'email',
      'message'
    ])
      key: TextEditingController()
  };
  late final InquiryApi _api = widget.api ?? InquiryApi();
  String? _sex;
  Branch? _branch;
  bool _consent = false, _submitting = false;
  String? _error;
  Map<String, String> _serverFields = {};
  String? _key;
  InquiryRequest? _pending;
  InquiryReceipt? _receipt;
  bool get _locked => _submitting || _pending != null || _receipt != null;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    if (widget.api == null) _api.close();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _receipt != null) return;
    setState(() {
      _serverFields = {};
      _error = null;
    });
    if (_pending == null) {
      if (!_form.currentState!.validate() || !_consent) {
        if (!_consent) {
          setState(() {
            _error = Si.consent;
          });
        }
        return;
      }
      _pending = InquiryRequest(
          name: _controllers['name']!.text,
          age: int.parse(_controllers['age']!.text.trim()),
          nic: _controllers['nic']!.text,
          sex: _sex!,
          telephone: _controllers['telephone']!.text,
          address: _controllers['address']!.text,
          email: _controllers['email']!.text,
          message: _controllers['message']!.text,
          loanId: widget.loan?.id ?? 'general',
          branchId: _branch!.id);
      _key = newSubmissionKey();
    }
    setState(() {
      _submitting = true;
    });
    try {
      final receipt = await _api.submit(_pending!, _key!);
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
      });
    } on InquiryApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _serverFields = error.fields;
        _error = error.code == 'RATE_LIMITED'
            ? 'මඳ වේලාවකින් නැවත උත්සාහ කරන්න.'
            : Si.failed;
        // A validation rejection cannot have persisted; allow correction.
        // Ambiguous failures retain exactly the same payload and key for retry.
        if (error.code == 'VALIDATION_ERROR') {
          _pending = null;
          _key = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = Si.failed;
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _field(String key, String label, String? Function(String?) validator,
          {int? maxLength, TextInputType? keyboardType, int maxLines = 1}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
              key: ValueKey(key),
              controller: _controllers[key],
              readOnly: _locked,
              decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  errorText:
                      _serverFields.containsKey(key) ? Si.invalid : null),
              maxLength: maxLength,
              maxLines: maxLines,
              keyboardType: keyboardType,
              validator: validator));

  Future<void> _chooseBranch() async {
    final selection = await showDialog<Branch>(
        context: context,
        builder: (_) => _BranchPicker(branches: widget.branches));
    if (mounted && selection != null) {
      setState(() {
        _branch = selection;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
      title: 'ඔබේ තොරතුරු පහත පුරවන්න',
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text(widget.loan?.name ?? 'සාමාන්‍ය විමසීම',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Form(
            key: _form,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _field('name', 'නම', Validators.name, maxLength: 60),
                  _field('age', 'වයස (අවු. 18–99)', Validators.age,
                      maxLength: 2, keyboardType: TextInputType.number),
                  _field('nic', 'ජාතික හැඳුනුම්පත් අංකය', Validators.nic,
                      maxLength: 12),
                  DropdownButtonFormField<String>(
                      key: const ValueKey('sex'),
                      value: _sex,
                      isExpanded: true,
                      decoration: const InputDecoration(
                          labelText: 'ස්ත්‍රී / පුරුෂ භාවය',
                          border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('පුරුෂ')),
                        DropdownMenuItem(
                            value: 'female', child: Text('ස්ත්‍රී'))
                      ],
                      onChanged: _locked
                          ? null
                          : (value) => setState(() {
                                _sex = value;
                              }),
                      validator: Validators.requiredText),
                  const SizedBox(height: 16),
                  _field('telephone', 'දුරකථන අංකය', Validators.telephone,
                      maxLength: 10, keyboardType: TextInputType.phone),
                  _field('address', 'ලිපිනය', Validators.requiredText,
                      maxLength: 120, maxLines: 2),
                  _field(
                      'email', 'විද්‍යුත් ලිපිනය (තිබේනම්)', Validators.email,
                      maxLength: 254, keyboardType: TextInputType.emailAddress),
                  _field('message', 'අමතර කරුණු / විමසීම්', (_) => null,
                      maxLength: 500, maxLines: 3),
                  FormField<Branch>(
                      validator: (_) => _branch == null ? Si.required : null,
                      builder: (state) => Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                OutlinedButton.icon(
                                    key: const ValueKey('branch'),
                                    onPressed: _locked ? null : _chooseBranch,
                                    icon: const Icon(Icons.search),
                                    label: Text(_branch?.name ??
                                        'ඔබට ළඟම බැංකු ශාඛාව තෝරන්න')),
                                if (state.hasError)
                                  Text(state.errorText!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error)),
                              ])),
                  const SizedBox(height: 16),
                  const Text(Si.contactNotice),
                  CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(Si.consent),
                      value: _consent,
                      onChanged: _locked
                          ? null
                          : (value) => setState(() {
                                _consent = value ?? false;
                              })),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(_error!, style: roleStyle(context))),
                  if (_receipt != null)
                    SelectableText('${Si.received} ${_receipt!.reference}'),
                  if (_receipt == null)
                    ElevatedButton(
                        key: const ValueKey('submit'),
                        onPressed: _submitting ? null : _submit,
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(_submitting
                                ? Si.submitting
                                : _pending != null
                                    ? 'නැවත උත්සාහ කරන්න'
                                    : Si.submit))),
                ])),
      ]));

  TextStyle roleStyle(BuildContext context) =>
      TextStyle(color: Theme.of(context).colorScheme.error);
}

class _BranchPicker extends StatefulWidget {
  final List<Branch> branches;
  const _BranchPicker({required this.branches});
  @override
  State<_BranchPicker> createState() => _BranchPickerState();
}

class _BranchPickerState extends State<_BranchPicker> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final branches = widget.branches
        .where((b) => b.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return AlertDialog(
        title: const Text('බැංකු ශාඛාව'),
        content: SizedBox(
            width: 400,
            height: 400,
            child: Column(children: [
              TextField(
                  decoration: const InputDecoration(labelText: 'ශාඛාව සොයන්න'),
                  onChanged: (value) => setState(() {
                        _query = value;
                      })),
              Expanded(
                  child: ListView.builder(
                      itemCount: branches.length,
                      itemBuilder: (context, i) => ListTile(
                          title: Text(branches[i].name),
                          onTap: () => Navigator.pop(context, branches[i]))))
            ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ආපසු'))
        ]);
  }
}
