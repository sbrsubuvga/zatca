import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../bloc/invoice/invoice_bloc.dart';
import '../bloc/invoice/invoice_event.dart';
import '../bloc/invoice/invoice_state.dart';
import '../widgets/copyable_block.dart';

/// Displays the full outcome of a successful invoice submission:
/// scannable QR, TLV breakdown, hash, signature, UBL XML, and the
/// ZATCA API response.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice result'),
        actions: [
          IconButton(
            tooltip: 'Create another invoice',
            icon: const Icon(Icons.add),
            onPressed: () {
              context.read<InvoiceBloc>()
                ..add(const InvoiceDismissed())
                ..add(const InvoiceStarted());
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<InvoiceBloc, InvoiceState>(
        builder: (context, state) {
          if (state.qrString == null) {
            return const Center(child: Text('No invoice submitted yet.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _statusBanner(context, state),
                const SizedBox(height: 16),
                _qrSection(context, state),
                const SizedBox(height: 16),
                _sectionTitle('QR code TLV breakdown'),
                _tlvBreakdown(context, state),
                const SizedBox(height: 16),
                _sectionTitle('Cryptographic outputs'),
                CopyableBlock(
                  title: 'Invoice hash (SHA-256 of XML)',
                  subtitle: 'Goes into QR Tag 6 and ds:DigestValue',
                  content: state.invoiceHash ?? '',
                ),
                CopyableBlock(
                  title: 'Digital signature (ECDSA)',
                  subtitle:
                      'secp256k1 signature over the invoice hash. '
                      'Goes into QR Tag 7 and ds:SignatureValue.',
                  content: state.digitalSignature ?? '',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _sectionTitle('Signed UBL XML'),
                CopyableBlock(
                  title: 'Final signed XML sent to ZATCA',
                  subtitle:
                      'Paste into ZATCA\'s XML validator at '
                      'zatca.gov.sa to verify externally',
                  content: state.ublXml ?? '',
                  maxLines: 15,
                ),
                const SizedBox(height: 16),
                _sectionTitle('Next steps'),
                _nextStepsCard(context),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusBanner(BuildContext context, InvoiceState state) {
    final theme = Theme.of(context);
    final ok = state.status == InvoiceStatus.success;
    final color = ok
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.errorContainer;
    final onColor = ok
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onErrorContainer;
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.error_outline,
              color: onColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ok
                        ? (state.kind.isStandard
                              ? 'Cleared by ZATCA'
                              : 'Reported to ZATCA')
                        : 'Submission failed',
                    style: theme.textTheme.titleLarge?.copyWith(color: onColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.submission?.apiEndpoint ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(color: onColor),
                  ),
                  if (state.submission?.infoMessages.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        state.submission!.infoMessages.join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(color: onColor),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qrSection(BuildContext context, InvoiceState state) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Print this QR on the receipt', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              'For simplified (B2C) invoices, customers scan this to verify with ZATCA.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: QrImageView(
                data: state.qrString!,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${state.qrString!.length} chars',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tlvBreakdown(BuildContext context, InvoiceState state) {
    // Decode the QR (Base64 of TLV) and re-parse it to show each tag.
    final tags = _decodeTlv(state.qrString!);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            for (final entry in tags.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${entry.key}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tagName(entry.key),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            entry.value.length > 80
                                ? '${entry.value.substring(0, 80)}…'
                                : entry.value,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _nextStepsCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _step(
              theme,
              '1.',
              'Persist the signed XML in your database — ZATCA requires 6-year archival.',
            ),
            _step(
              theme,
              '2.',
              'Print/display the QR on the invoice receipt.',
            ),
            _step(
              theme,
              '3.',
              'For production, upgrade to a production cert (Onboarding tab) '
                  'and switch the environment to production.',
            ),
            _step(
              theme,
              '4.',
              'Chain invoices: the next invoice\'s PIH is this invoice\'s hash. '
                  'The example handles that automatically via SharedPreferences.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(ThemeData theme, String num, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(num, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    ),
  );

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 8),
    child: Text(
      t.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    ),
  );

  String _tagName(int tag) => switch (tag) {
    1 => 'Seller name',
    2 => 'Seller VAT registration',
    3 => 'Invoice timestamp',
    4 => 'Total with VAT',
    5 => 'VAT amount',
    6 => 'Invoice XML hash',
    7 => 'ECDSA signature',
    8 => 'ECDSA public key',
    9 => 'Certificate signature',
    _ => 'Tag $tag',
  };

  /// Decode a Base64-encoded TLV into a {tag: human-readable value} map
  /// for display. Binary tags (8, 9) are shown as hex.
  Map<int, String> _decodeTlv(String qr) {
    try {
      final bytes = base64.decode(qr);
      final out = <int, String>{};
      int i = 0;
      while (i < bytes.length) {
        final tag = bytes[i++];
        if (i >= bytes.length) break;
        final length = bytes[i++];
        if (i + length > bytes.length) break;
        final value = bytes.sublist(i, i + length);
        i += length;
        // Tags 1-7 are ASCII/UTF-8 text in this package's encoding;
        // 8 and 9 are raw binary, so show them as hex.
        if (tag >= 1 && tag <= 7) {
          try {
            out[tag] = utf8.decode(value);
          } catch (_) {
            out[tag] = _hex(value);
          }
        } else {
          out[tag] = _hex(value);
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
}
