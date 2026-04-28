import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zatca/simple_zatca_manager.dart';

import '../widgets/copyable_block.dart';

/// A self-contained demo of the ZATCA Phase-1 (Generation) QR API.
///
/// Phase-1 works for merchants that have not been onboarded to FATOORA
/// integration: no certificates, no signing, no ZATCA API calls — just a
/// TLV QR with 5 tags. Works the same for simplified (B2C) and
/// standard (B2B) invoices.
class Phase1Screen extends StatefulWidget {
  const Phase1Screen({super.key});

  @override
  State<Phase1Screen> createState() => _Phase1ScreenState();
}

class _Phase1ScreenState extends State<Phase1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _sellerName = TextEditingController(text: 'Demo Shop');
  final _sellerTRN = TextEditingController(text: '300000000000003');
  final _total = TextEditingController(text: '115.00');
  final _vat = TextEditingController(text: '15.00');
  DateTime _issueDateTime = DateTime.now();

  String? _qrString;
  String? _error;

  @override
  void dispose() {
    _sellerName.dispose();
    _sellerTRN.dispose();
    _total.dispose();
    _vat.dispose();
    super.dispose();
  }

  void _generate() {
    setState(() {
      _qrString = null;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;

    try {
      SimpleZatcaManager.instance.initialize(
        sellerName: _sellerName.text,
        sellerTRN: _sellerTRN.text,
      );
      final qr = SimpleZatcaManager.instance.generateQrString(
        issueDateTime: _issueDateTime,
        totalWithVat: double.parse(_total.text),
        vatTotal: double.parse(_vat.text),
      );
      setState(() => _qrString = qr);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _issueDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_issueDateTime),
    );
    if (t == null) return;
    setState(() {
      _issueDateTime = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text('SimpleZatcaManager',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontFamily: 'monospace',
                              )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Basic TLV QR (tags 1-5). Same format for B2C '
                        'and B2B. No certificates, no signing, no API.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _sellerName,
                          decoration: const InputDecoration(
                              labelText: 'Seller name'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _sellerTRN,
                          decoration: const InputDecoration(
                            labelText: 'VAT registration number (15 digits)',
                          ),
                          validator: (v) =>
                              RegExp(r'^3\d{13}3$').hasMatch(v ?? '')
                                  ? null
                                  : '15 digits, starts & ends with 3',
                        ),
                        const SizedBox(height: 12),
                        InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'Issue date/time'),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat("yyyy-MM-dd'T'HH:mm:ss")
                                      .format(_issueDateTime),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _pickDateTime,
                                icon: const Icon(Icons.event),
                                label: const Text('Pick'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _total,
                                decoration: const InputDecoration(
                                    labelText: 'Total (with VAT)'),
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true),
                                validator: _numberValidator,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _vat,
                                decoration: const InputDecoration(
                                    labelText: 'VAT total'),
                                keyboardType: const TextInputType
                                    .numberWithOptions(decimal: true),
                                validator: _numberValidator,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _generate,
                          icon: const Icon(Icons.qr_code_2),
                          label: const Text('Generate Phase-1 QR'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                          color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ),
              ],
              if (_qrString != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('QR Code', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: Colors.white,
                          child: QrImageView(
                            data: _qrString!,
                            size: 220,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CopyableBlock(
                          title: 'Base64 QR string',
                          content: _qrString!,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 12),
                        _TlvBreakdown(qrString: _qrString!),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _numberValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final d = double.tryParse(v);
    if (d == null) return 'Invalid number';
    if (d < 0) return 'Must be >= 0';
    return null;
  }
}

class _TlvBreakdown extends StatelessWidget {
  final String qrString;
  const _TlvBreakdown({required this.qrString});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = _decode(qrString);
    if (tags.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('TLV breakdown', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final t in tags)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              'Tag ${t.$1} (${_tagLabel(t.$1)}): ${t.$2}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
      ],
    );
  }

  static String _tagLabel(int tag) => switch (tag) {
        1 => 'Seller name',
        2 => 'VAT number',
        3 => 'Timestamp',
        4 => 'Invoice total',
        5 => 'VAT total',
        _ => 'Unknown',
      };

  static List<(int, String)> _decode(String base64Qr) {
    try {
      final bytes = base64.decode(base64Qr);
      final out = <(int, String)>[];
      var i = 0;
      while (i < bytes.length) {
        final tag = bytes[i++];
        final len = bytes[i++];
        final val = utf8.decode(bytes.sublist(i, i + len), allowMalformed: true);
        out.add((tag, val));
        i += len;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}
