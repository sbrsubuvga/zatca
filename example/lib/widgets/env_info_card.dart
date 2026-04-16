import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zatca/resources/enums.dart';

/// Expandable card explaining the three ZATCA environments and
/// how to get valid credentials for each.
class EnvironmentInfoCard extends StatelessWidget {
  final ZatcaEnvironment environment;
  const EnvironmentInfoCard({super.key, required this.environment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('How do I get test credentials?'),
        subtitle: Text(
          'Current environment: ${environment.value}',
          style: theme.textTheme.bodySmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _envRow(
            context,
            name: 'Sandbox (Developer Portal)',
            purpose: 'Free, instant test — no registration.',
            otp: 'OTP: 123456 (fixed — works for any CSR)',
            vat: 'Invent any valid VAT: 15 digits starting & ending with 3',
            link:
                'https://sandbox.zatca.gov.sa/IntegrationSandbox',
            linkLabel: 'Developer Portal',
            isActive: environment == ZatcaEnvironment.sandbox,
          ),
          const Divider(),
          _envRow(
            context,
            name: 'Simulation (Pre-production)',
            purpose: 'Test with real ZATCA validation.',
            otp: 'OTP: from fatoora.zatca.gov.sa → "Onboard Solution/Device"',
            vat: 'Your real registered VAT number',
            link: 'https://fatoora.zatca.gov.sa',
            linkLabel: 'Fatoora Portal',
            isActive: environment == ZatcaEnvironment.simulation,
          ),
          const Divider(),
          _envRow(
            context,
            name: 'Production',
            purpose: 'Live invoices. Finish simulation first.',
            otp: 'OTP: from Fatoora portal for each EGS device',
            vat: 'Your real registered VAT number',
            link: 'https://fatoora.zatca.gov.sa',
            linkLabel: 'Fatoora Portal',
            isActive: environment == ZatcaEnvironment.production,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Full technical guidelines:',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _open(
                'https://zatca.gov.sa/en/E-Invoicing/Introduction/Guidelines/Pages/default.aspx',
              ),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('ZATCA E-Invoicing Guidelines'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _envRow(
    BuildContext context, {
    required String name,
    required String purpose,
    required String otp,
    required String vat,
    required String link,
    required String linkLabel,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: isActive
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(purpose, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            _bullet(context, Icons.lock_outline, otp),
            _bullet(context, Icons.badge_outlined, vat),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _open(link),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: Text(linkLabel),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 28),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: link)),
                  icon: const Icon(Icons.copy, size: 14),
                  tooltip: 'Copy URL',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Theme.of(context).hintColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
