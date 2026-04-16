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
import '../ui/breakpoints.dart';
import '../ui/section_card.dart';
import '../widgets/line_item_editor.dart';
import 'result_screen.dart';

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
        final twoColumn = Breakpoints.useTwoColumn(context);
        return PageShell(
          child: twoColumn
              ? _twoColumnLayout(context, state, onboarding)
              : _singleColumnLayout(context, state, onboarding),
        );
      },
    );
  }

  Widget _singleColumnLayout(
    BuildContext context,
    InvoiceState state,
    OnboardingState onboarding,
  ) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _identityBanner(context, onboarding),
        Gaps.hMd,
        _typeSection(context, state),
        Gaps.hMd,
        _detailsSection(context, state),
        if (state.kind.isStandard) ...[
          Gaps.hMd,
          _customerSection(context, state),
        ],
        if (state.kind.isCreditOrDebitNote) ...[
          Gaps.hMd,
          _cancellationSection(context, state),
        ],
        Gaps.hMd,
        _linesSection(context, state),
        Gaps.hMd,
        _totalsCard(context, state),
        Gaps.hMd,
        if (state.errorMessage != null) ...[
          _errorBanner(context, state.errorMessage!),
          Gaps.hMd,
        ],
        _submitButton(context, state),
        Gaps.hXl,
      ],
    ),
  );

  Widget _twoColumnLayout(
    BuildContext context,
    InvoiceState state,
    OnboardingState onboarding,
  ) => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _identityBanner(context, onboarding),
        Gaps.hMd,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _typeSection(context, state),
                  Gaps.hMd,
                  _detailsSection(context, state),
                  if (state.kind.isStandard) ...[
                    Gaps.hMd,
                    _customerSection(context, state),
                  ],
                  if (state.kind.isCreditOrDebitNote) ...[
                    Gaps.hMd,
                    _cancellationSection(context, state),
                  ],
                  Gaps.hMd,
                  _linesSection(context, state),
                ],
              ),
            ),
            Gaps.wLg,
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _totalsCard(context, state),
                  Gaps.hMd,
                  if (state.errorMessage != null) ...[
                    _errorBanner(context, state.errorMessage!),
                    Gaps.hMd,
                  ],
                  _submitButton(context, state),
                ],
              ),
            ),
          ],
        ),
        Gaps.hXl,
      ],
    ),
  );

  Widget _notOnboardedPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 36,
                  color: theme.hintColor,
                ),
              ),
              Gaps.hMd,
              Text(
                'Set up your EGS device first',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              Gaps.hSm,
              Text(
                'Issue a compliance certificate before creating invoices. '
                'Go to the "Onboarding" tab to get started.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identityBanner(BuildContext context, OnboardingState onboarding) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Gaps.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.1,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.verified,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          Gaps.wMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  onboarding.egs!.taxpayerName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'VAT ${onboarding.egs!.vatNumber}  •  '
                  '${onboarding.environment.value.toUpperCase()}  •  '
                  '${onboarding.hasProductionCertificate ? "Production cert" : "Compliance cert"}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.75,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeSection(BuildContext context, InvoiceState state) => SectionCard(
    icon: Icons.description_outlined,
    title: 'Invoice type',
    description:
        'Simplified = B2C (reporting flow). Standard = B2B (clearance flow).',
    child: DropdownButtonFormField<InvoiceKind>(
      initialValue: state.kind,
      decoration: const InputDecoration(labelText: 'Type'),
      items: InvoiceKind.values
          .map(
            (k) => DropdownMenuItem(
              value: k,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(k.label),
                  const SizedBox(width: 8),
                  _audienceChip(context, k),
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
    ),
  );

  Widget _audienceChip(BuildContext context, InvoiceKind k) {
    final color = k.isStandard ? Colors.orange : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
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
    );
  }

  Widget _detailsSection(BuildContext context, InvoiceState state) =>
      SectionCard(
        icon: Icons.tag,
        title: 'Invoice details',
        child: Column(
          children: [
            TextField(
              controller: _invoiceNumber,
              decoration: const InputDecoration(
                labelText: 'Invoice number',
                helperText: 'Sequential ID visible to the customer',
              ),
              onChanged: (v) =>
                  context.read<InvoiceBloc>().add(InvoiceNumberChanged(v)),
            ),
            Gaps.hSm,
            DropdownButtonFormField<ZATCAPaymentMethods>(
              initialValue: state.paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment method'),
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
                  context.read<InvoiceBloc>().add(
                    InvoicePaymentMethodChanged(p),
                  );
                }
              },
            ),
          ],
        ),
      );

  Widget _customerSection(BuildContext context, InvoiceState state) =>
      SectionCard(
        icon: Icons.person_outline,
        title: 'Customer (B2B)',
        description: 'Required for standard invoices.',
        child: _customerForm(context, state),
      );

  Widget _cancellationSection(BuildContext context, InvoiceState state) =>
      SectionCard(
        icon: Icons.cancel_outlined,
        title: 'Cancellation details',
        description: 'Credit/debit notes must reference the original invoice.',
        child: _cancellationForm(context, state),
      );

  Widget _linesSection(BuildContext context, InvoiceState state) =>
      SectionCard(
        icon: Icons.list_alt,
        title: 'Line items',
        description: '${state.lines.length} item${state.lines.length == 1 ? "" : "s"}',
        trailing: FilledButton.tonalIcon(
          onPressed: () =>
              context.read<InvoiceBloc>().add(const InvoiceLineAdded()),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 36),
          ),
        ),
        child: Column(
          children: [
            for (final entry in state.lines.asMap().entries)
              LineItemEditor(
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
          ],
        ),
      );

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
              building: _custBuilding.text.isEmpty
                  ? '00'
                  : _custBuilding.text,
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
          ),
          onChanged: (_) => emit(),
        ),
        Gaps.hSm,
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _custVat,
                decoration: const InputDecoration(
                  labelText: 'Customer VAT number',
                  helperText: 'Required for B2B',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => emit(),
              ),
            ),
            Gaps.wSm,
            Expanded(
              child: TextField(
                controller: _custBusinessId,
                decoration: const InputDecoration(
                  labelText: 'Customer CRN (opt)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => emit(),
              ),
            ),
          ],
        ),
        Gaps.hSm,
        TextField(
          controller: _custStreet,
          decoration: const InputDecoration(labelText: 'Street'),
          onChanged: (_) => emit(),
        ),
        Gaps.hSm,
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _custBuilding,
                decoration: const InputDecoration(labelText: 'Building #'),
                onChanged: (_) => emit(),
              ),
            ),
            Gaps.wSm,
            Expanded(
              child: TextField(
                controller: _custCity,
                decoration: const InputDecoration(labelText: 'City'),
                onChanged: (_) => emit(),
              ),
            ),
            Gaps.wSm,
            Expanded(
              child: TextField(
                controller: _custPostal,
                decoration: const InputDecoration(labelText: 'Postal'),
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
    void emit() => context.read<InvoiceBloc>().add(
      InvoiceCancellationChanged(
        reason: _cancelReason.text,
        canceledSerialInvoiceNumber: _canceledNumber.text,
      ),
    );
    return Column(
      children: [
        TextField(
          controller: _canceledNumber,
          decoration: const InputDecoration(
            labelText: 'Original invoice number being corrected',
          ),
          onChanged: (_) => emit(),
        ),
        Gaps.hSm,
        TextField(
          controller: _cancelReason,
          decoration: const InputDecoration(
            labelText: 'Reason',
            helperText: 'Required by ZATCA for credit/debit notes',
          ),
          onChanged: (_) => emit(),
        ),
      ],
    );
  }

  Widget _totalsCard(BuildContext context, InvoiceState state) {
    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.calculate_outlined,
      title: 'Totals',
      description: 'Calculated from line items above.',
      child: Column(
        children: [
          _totalRow(theme, 'Subtotal', state.subtotal, Icons.shopping_cart_outlined),
          _totalRow(theme, 'VAT', state.taxTotal, Icons.percent),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Gaps.sm),
            child: Divider(height: 1, color: theme.dividerColor),
          ),
          _totalRow(
            theme,
            'Total',
            state.grandTotal,
            Icons.receipt_long,
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    ThemeData theme,
    String label,
    double value,
    IconData icon, {
    bool emphasized = false,
  }) {
    final style = emphasized
        ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: emphasized ? theme.colorScheme.primary : theme.hintColor,
          ),
          Gaps.wSm,
          Expanded(child: Text(label, style: style)),
          Text('${value.toStringAsFixed(2)} SAR', style: style),
        ],
      ),
    );
  }

  Widget _errorBanner(BuildContext context, String msg) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Gaps.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
          ),
          Gaps.wSm,
          Expanded(
            child: Text(
              msg,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton(BuildContext context, InvoiceState state) {
    final submitting = state.status == InvoiceStatus.submitting;
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: submitting
            ? null
            : () => context.read<InvoiceBloc>().add(const InvoiceSubmitted()),
        icon: submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send),
        label: Text(
          state.kind.isStandard
              ? 'Sign & submit for clearance'
              : 'Sign & report to ZATCA',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
