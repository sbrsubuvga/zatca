import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zatca/models/address.dart';
import 'package:zatca/models/customer.dart';
import 'package:zatca/resources/enums.dart';

import '../bloc/invoice/invoice_bloc.dart';
import '../bloc/invoice/invoice_event.dart';
import '../bloc/invoice/invoice_state.dart';
import '../bloc/onboarding/onboarding_bloc.dart';
import '../bloc/onboarding/onboarding_state.dart';
import '../widgets/line_item_editor.dart';
import 'result_screen.dart';

/// Compose and submit a test invoice. Wraps every invoice variant
/// the package supports under a single dropdown.
class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _invoiceNumber = TextEditingController();
  final _custName = TextEditingController();
  final _custVat = TextEditingController();
  final _custBusinessId = TextEditingController();
  final _custStreet = TextEditingController();
  final _custBuilding = TextEditingController();
  final _custCity = TextEditingController();
  final _custPostal = TextEditingController();
  final _cancelReason = TextEditingController();
  final _canceledNumber = TextEditingController();

  bool _startedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.read<InvoiceBloc>().state.lines.isEmpty) {
        context.read<InvoiceBloc>().add(const InvoiceStarted());
      }
    });
  }

  @override
  void dispose() {
    for (final c in [
      _invoiceNumber,
      _custName,
      _custVat,
      _custBusinessId,
      _custStreet,
      _custBuilding,
      _custCity,
      _custPostal,
      _cancelReason,
      _canceledNumber,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvoiceBloc, InvoiceState>(
      listener: (context, state) {
        if (state.status == InvoiceStatus.submitting) return;
        if (!_startedOnce && state.invoiceNumber.isNotEmpty) {
          _invoiceNumber.text = state.invoiceNumber;
          _startedOnce = true;
        }
        if (state.status == InvoiceStatus.success) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ResultScreen()),
          );
        }
      },
      builder: (context, state) {
        final onboarding = context.watch<OnboardingBloc>().state;
        if (!onboarding.isReadyToInvoice) {
          return _notOnboardedPlaceholder(context);
        }
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context, state, onboarding),
                const SizedBox(height: 16),
                _kindSelector(context, state),
                const SizedBox(height: 16),
                _sectionTitle('Invoice details'),
                TextField(
                  controller: _invoiceNumber,
                  decoration: const InputDecoration(
                    labelText: 'Invoice number',
                    helperText: 'Sequential ID visible to the customer',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => context.read<InvoiceBloc>().add(
                    InvoiceNumberChanged(v),
                  ),
                ),
                const SizedBox(height: 12),
                _paymentMethodDropdown(context, state),
                if (state.kind.isStandard) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Customer (B2B)'),
                  _customerForm(context, state),
                ],
                if (state.kind.isCreditOrDebitNote) ...[
                  const SizedBox(height: 16),
                  _sectionTitle('Cancellation'),
                  _cancellationForm(context, state),
                ],
                const SizedBox(height: 16),
                _sectionTitle('Line items'),
                ...state.lines.asMap().entries.map(
                  (entry) => LineItemEditor(
                    index: entry.key,
                    draft: entry.value,
                    canRemove: state.lines.length > 1,
                    onChanged: (draft) => context.read<InvoiceBloc>().add(
                      InvoiceLineUpdated(entry.key, draft),
                    ),
                    onRemove: () => context.read<InvoiceBloc>().add(
                      InvoiceLineRemoved(entry.key),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.read<InvoiceBloc>().add(
                      const InvoiceLineAdded(),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add line'),
                  ),
                ),
                const SizedBox(height: 16),
                _totalsCard(context, state),
                const SizedBox(height: 16),
                if (state.errorMessage != null)
                  _errorBanner(context, state.errorMessage!),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.status == InvoiceStatus.submitting
                        ? null
                        : () => _onSubmit(context, state),
                    icon: state.status == InvoiceStatus.submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                      state.kind.isStandard
                          ? 'Sign, generate QR & submit for clearance'
                          : 'Sign, generate QR & report to ZATCA',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _notOnboardedPlaceholder(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Set up your EGS device first',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Issue a compliance certificate before creating invoices. '
            'Go to the "Onboarding" tab to get started.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _header(
    BuildContext context,
    InvoiceState state,
    OnboardingState onboarding,
  ) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signed in as ${onboarding.egs!.taxpayerName}',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    'VAT ${onboarding.egs!.vatNumber} • '
                    '${onboarding.environment.value.toUpperCase()} • '
                    '${onboarding.hasProductionCertificate ? "Production cert" : "Compliance cert"}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kindSelector(BuildContext context, InvoiceState state) {
    return DropdownButtonFormField<InvoiceKind>(
      initialValue: state.kind,
      decoration: const InputDecoration(
        labelText: 'Invoice type',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: InvoiceKind.values
          .map(
            (k) => DropdownMenuItem(
              value: k,
              child: Row(
                children: [
                  Text(k.label),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: k.isStandard ? Colors.orange : Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      k.audience,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (k) {
        if (k != null) {
          context.read<InvoiceBloc>().add(InvoiceKindChanged(k));
        }
      },
    );
  }

  Widget _paymentMethodDropdown(BuildContext context, InvoiceState state) {
    return DropdownButtonFormField<ZATCAPaymentMethods>(
      initialValue: state.paymentMethod,
      decoration: const InputDecoration(
        labelText: 'Payment method',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: ZATCAPaymentMethods.values
          .map(
            (p) => DropdownMenuItem(
              value: p,
              child: Text('${p.name} (code ${p.value})'),
            ),
          )
          .toList(),
      onChanged: (p) {
        if (p != null) {
          context.read<InvoiceBloc>().add(InvoicePaymentMethodChanged(p));
        }
      },
    );
  }

  Widget _customerForm(BuildContext context, InvoiceState state) {
    void emit() {
      context.read<InvoiceBloc>().add(
        InvoiceCustomerChanged(
          Customer(
            companyID: _custVat.text,
            registrationName: _custName.text.isEmpty
                ? 'Customer'
                : _custName.text,
            businessID: _custBusinessId.text.isEmpty
                ? null
                : _custBusinessId.text,
            address: Address(
              street: _custStreet.text,
              building: _custBuilding.text.isEmpty ? '00' : _custBuilding.text,
              citySubdivision: '',
              city: _custCity.text,
              postalZone: _custPostal.text,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        TextField(
          controller: _custName,
          decoration: const InputDecoration(
            labelText: 'Customer legal name',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => emit(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _custVat,
          decoration: const InputDecoration(
            labelText: 'Customer VAT number',
            helperText: '15 digits — required for B2B',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => emit(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _custBusinessId,
          decoration: const InputDecoration(
            labelText: 'Customer CRN (optional)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) => emit(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _custStreet,
          decoration: const InputDecoration(
            labelText: 'Street',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => emit(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _custBuilding,
                decoration: const InputDecoration(
                  labelText: 'Building #',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => emit(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _custCity,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => emit(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _custPostal,
                decoration: const InputDecoration(
                  labelText: 'Postal zone',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => emit(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cancellationForm(BuildContext context, InvoiceState state) {
    void emit() {
      context.read<InvoiceBloc>().add(
        InvoiceCancellationChanged(
          reason: _cancelReason.text,
          canceledSerialInvoiceNumber: _canceledNumber.text,
        ),
      );
    }

    return Column(
      children: [
        TextField(
          controller: _canceledNumber,
          decoration: const InputDecoration(
            labelText: 'Original invoice number being corrected',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => emit(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _cancelReason,
          decoration: const InputDecoration(
            labelText: 'Reason',
            helperText: 'Required by ZATCA for credit/debit notes',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => emit(),
        ),
      ],
    );
  }

  Widget _totalsCard(BuildContext context, InvoiceState state) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _totalRow(theme, 'Subtotal', state.subtotal),
            _totalRow(theme, 'VAT (15%)', state.taxTotal),
            const Divider(),
            _totalRow(
              theme,
              'Total',
              state.grandTotal,
              emphasized: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(ThemeData theme, String label, double value, {bool emphasized = false}) {
    final style = emphasized
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${value.toStringAsFixed(2)} SAR', style: style),
        ],
      ),
    );
  }

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

  Widget _errorBanner(BuildContext context, String msg) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _onSubmit(BuildContext context, InvoiceState state) {
    context.read<InvoiceBloc>().add(const InvoiceSubmitted());
  }
}
