import 'package:flutter/material.dart';

import '../ui/breakpoints.dart';

/// Landing screen — explains the two ZATCA phases and lets the user
/// jump to the matching demo flow.
class HomeScreen extends StatelessWidget {
  /// Called when the user taps the "Try Phase-1" CTA.
  final VoidCallback onTryPhase1;

  /// Called when the user taps the "Try Phase-2" CTA.
  /// Should route to the Phase-2 onboarding step.
  final VoidCallback onTryPhase2;

  const HomeScreen({
    super.key,
    required this.onTryPhase1,
    required this.onTryPhase2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Gaps.md),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(theme: theme),
              const SizedBox(height: Gaps.lg),
              _phaseCardsRow(context),
              const SizedBox(height: Gaps.lg),
              _ComparisonCard(theme: theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phaseCardsRow(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= Breakpoints.medium;
    final p1 = _PhaseCard(
      tag: 'PHASE-1',
      tagColor: Theme.of(context).colorScheme.primary,
      title: 'Generation',
      apiClass: 'SimpleZatcaManager',
      description:
          'For merchants not yet onboarded to FATOORA. Produces a basic '
          'TLV QR (tags 1–5). No certificates, no signing, no API calls.',
      bullets: const [
        'Just seller name + VAT to start',
        'One method call to generate the QR',
        'Same QR for B2C and B2B',
      ],
      ctaLabel: 'Try Phase-1 demo',
      onPressed: onTryPhase1,
    );
    final p2 = _PhaseCard(
      tag: 'PHASE-2',
      tagColor: Theme.of(context).colorScheme.tertiary,
      title: 'Integration',
      apiClass: 'ZatcaManager',
      description:
          'For merchants onboarded to FATOORA with compliance + production '
          'CSIDs. Full pipeline: signed UBL XML, full 9-tag QR, ZATCA API.',
      bullets: const [
        'Two-step demo: Onboarding → Create Invoice',
        'ECDSA secp256k1 signing',
        'Submits invoices to ZATCA sandbox',
      ],
      ctaLabel: 'Try Phase-2 demo',
      onPressed: onTryPhase2,
    );

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [p1, const SizedBox(height: Gaps.md), p2],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: p1),
          const SizedBox(width: Gaps.md),
          Expanded(child: p2),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final ThemeData theme;
  const _Hero({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gaps.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: theme.colorScheme.primary),
                const SizedBox(width: Gaps.sm),
                Text(
                  'ZATCA E-Invoicing demo',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Gaps.sm),
            Text(
              'This package supports both ZATCA phases. One terminal '
              '(or one merchant account) runs in exactly one phase at a '
              'time — pick the one that matches your tenant below.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final String title;
  final String apiClass;
  final String description;
  final List<String> bullets;
  final String ctaLabel;
  final VoidCallback onPressed;

  const _PhaseCard({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.apiClass,
    required this.description,
    required this.bullets,
    required this.ctaLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gaps.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tagColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tagColor,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: Gaps.sm),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: Gaps.xs),
            Text(
              apiClass,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Gaps.md),
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: Gaps.md),
            for (final b in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: Gaps.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 8),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: tagColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(child: Text(b, style: theme.textTheme.bodySmall)),
                  ],
                ),
              ),
            const Spacer(),
            const SizedBox(height: Gaps.md),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward),
              label: Text(ctaLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  final ThemeData theme;
  const _ComparisonCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final rows = const <(String, String, String)>[
      ('When to use', 'Not yet onboarded', 'Onboarded with CSID'),
      ('QR code', 'Basic TLV (tags 1–5)', 'Full TLV (tags 1–9)'),
      ('Signing', 'None', 'ECDSA secp256k1'),
      ('Certificates', 'Not required', 'Compliance + Production'),
      ('ZATCA API', 'None', 'Reporting / Clearance'),
      ('B2B vs B2C', 'Same basic QR', 'UBL XML differs'),
    ];
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueStyle = theme.textTheme.bodySmall;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gaps.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Gaps.sm),
              child: Text(
                'At a glance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  children: [
                    _cell(' ', headerStyle),
                    _cell('Phase-1', headerStyle),
                    _cell('Phase-2', headerStyle),
                  ],
                ),
                for (final r in rows)
                  TableRow(
                    children: [
                      _cell(r.$1, headerStyle, padRight: true),
                      _cell(r.$2, valueStyle),
                      _cell(r.$3, valueStyle),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, TextStyle? style, {bool padRight = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 8, padRight ? 16 : 8, 8),
      child: Text(text, style: style),
    );
  }
}
