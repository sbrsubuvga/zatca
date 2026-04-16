import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../bloc/invoice/invoice_bloc.dart';
import '../bloc/invoice/invoice_event.dart';
import '../bloc/invoice/invoice_state.dart';
import '../ui/breakpoints.dart';
import '../ui/section_card.dart';
import '../widgets/copyable_block.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice result'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          FilledButton.tonalIcon(
            onPressed: () {
              context.read<InvoiceBloc>()
                ..add(const InvoiceDismissed())
                ..add(const InvoiceStarted());
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New invoice'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: BlocBuilder<InvoiceBloc, InvoiceState>(
        builder: (context, state) {
          if (state.qrString == null) {
            return const Center(child: Text('No invoice submitted yet.'));
          }
          final twoColumn = Breakpoints.useTwoColumn(context);
          return PageShell(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _statusBanner(context, state),
                  Gaps.hMd,
                  twoColumn
                      ? _twoColumnContent(context, state)
                      : _singleColumnContent(context, state),
                  Gaps.hXl,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _twoColumnContent(BuildContext context, InvoiceState state) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _qrSection(context, state),
            Gaps.hMd,
            _tlvSection(context, state),
          ],
        ),
      ),
      Gaps.wLg,
      Expanded(
        flex: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _cryptoSection(context, state),
            Gaps.hMd,
            _xmlSection(context, state),
            Gaps.hMd,
            _nextStepsCard(context),
          ],
        ),
      ),
    ],
  );

  Widget _singleColumnContent(BuildContext context, InvoiceState state) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _qrSection(context, state),
          Gaps.hMd,
          _tlvSection(context, state),
          Gaps.hMd,
          _cryptoSection(context, state),
          Gaps.hMd,
          _xmlSection(context, state),
          Gaps.hMd,
          _nextStepsCard(context),
        ],
      );

  Widget _statusBanner(BuildContext context, InvoiceState state) {
    final theme = Theme.of(context);
    final ok = state.status == InvoiceStatus.success;
    final color = ok
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.all(Gaps.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              ok ? Icons.check_circle : Icons.error_outline,
              color: color,
              size: 32,
            ),
          ),
          Gaps.wMd,
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
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Gaps.hXs,
                Text(
                  state.submission?.apiEndpoint ?? '',
                  style: theme.textTheme.bodyMedium,
                ),
                if (state.submission?.infoMessages.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      state.submission!.infoMessages.join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrSection(BuildContext context, InvoiceState state) {
    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.qr_code_2,
      title: 'Scannable QR',
      description: 'Print this on the receipt for B2C customers.',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(Gaps.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: QrImageView(
              data: state.qrString!,
              version: QrVersions.auto,
              size: 260,
              backgroundColor: Colors.white,
            ),
          ),
          Gaps.hSm,
          Text(
            '${state.qrString!.length} chars — Base64 of TLV',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _tlvSection(BuildContext context, InvoiceState state) {
    final tags = _decodeTlv(state.qrString!);
    return SectionCard(
      icon: Icons.grid_view,
      title: 'QR code TLV breakdown',
      description: 'Each ZATCA-defined tag carried inside the QR.',
      child: Column(
        children: [
          for (final entry in tags.entries) _tlvRow(context, entry),
        ],
      ),
    );
  }

  Widget _tlvRow(BuildContext context, MapEntry<int, String> entry) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '${entry.key}',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Gaps.wSm,
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
                const SizedBox(height: 2),
                Text(
                  entry.value.length > 80
                      ? '${entry.value.substring(0, 80)}…'
                      : entry.value,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cryptoSection(BuildContext context, InvoiceState state) =>
      SectionCard(
        icon: Icons.vpn_key_outlined,
        title: 'Cryptographic outputs',
        description:
            'Hash goes into QR Tag 6 & ds:DigestValue; signature into '
            'Tag 7 & ds:SignatureValue.',
        child: Column(
          children: [
            CopyableBlock(
              title: 'Invoice hash (SHA-256 of XML)',
              content: state.invoiceHash ?? '',
            ),
            CopyableBlock(
              title: 'Digital signature (ECDSA secp256k1)',
              content: state.digitalSignature ?? '',
              maxLines: 3,
            ),
          ],
        ),
      );

  Widget _xmlSection(BuildContext context, InvoiceState state) => SectionCard(
    icon: Icons.code,
    title: 'Signed UBL XML',
    description:
        'Paste into ZATCA\'s XML validator to verify externally.',
    child: CopyableBlock(
      title: 'Final XML sent to ZATCA',
      content: state.ublXml ?? '',
      maxLines: 15,
    ),
  );

  Widget _nextStepsCard(BuildContext context) => SectionCard(
    icon: Icons.lightbulb_outline,
    title: 'What next?',
    description: 'Things to wire up in a real integration.',
    child: Column(
      children: [
        _step(
          context,
          1,
          'Persist the signed XML in your database — ZATCA requires 6-year archival.',
        ),
        _step(
          context,
          2,
          'Print or display the QR on the invoice receipt for B2C customers.',
        ),
        _step(
          context,
          3,
          'For production, upgrade to a production cert (Onboarding tab) '
              'and switch the environment to production.',
        ),
        _step(
          context,
          4,
          'Chain invoices: the next invoice\'s PIH is this invoice\'s hash. '
              'The example handles that automatically via SharedPreferences.',
        ),
      ],
    ),
  );

  Widget _step(BuildContext context, int num, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$num',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          Gaps.wSm,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }

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
