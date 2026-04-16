import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zatca/models/address.dart';
import 'package:zatca/models/egs_unit.dart';
import 'package:zatca/resources/enums.dart';

import '../bloc/onboarding/onboarding_bloc.dart';
import '../bloc/onboarding/onboarding_event.dart';
import '../bloc/onboarding/onboarding_state.dart';
import '../ui/breakpoints.dart';
import '../ui/section_card.dart';
import '../util/validators.dart';
import '../widgets/copyable_block.dart';
import '../widgets/env_info_card.dart';
import '../widgets/onboarding_stepper.dart';

/// Walks the user through registering an EGS device with ZATCA.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _taxpayerName = TextEditingController();
  final _vatNumber = TextEditingController();
  final _crn = TextEditingController();
  final _branchName = TextEditingController();
  final _branchIndustry = TextEditingController();
  final _taxpayerProvidedId = TextEditingController();
  final _model = TextEditingController(text: 'Flutter');
  final _otp = TextEditingController();
  final _street = TextEditingController();
  final _building = TextEditingController();
  final _plot = TextEditingController();
  final _city = TextEditingController();
  final _citySubdivision = TextEditingController();
  final _postalZone = TextEditingController();

  bool _prefilled = false;

  @override
  void dispose() {
    for (final c in [
      _taxpayerName,
      _vatNumber,
      _crn,
      _branchName,
      _branchIndustry,
      _taxpayerProvidedId,
      _model,
      _otp,
      _street,
      _building,
      _plot,
      _city,
      _citySubdivision,
      _postalZone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _hydrate(OnboardingState state) {
    final egs = state.egs;
    if (egs == null) return;
    _taxpayerName.text = egs.taxpayerName;
    _vatNumber.text = egs.vatNumber;
    _crn.text = egs.crnNumber;
    _branchName.text = egs.branchName;
    _branchIndustry.text = egs.branchIndustry;
    _taxpayerProvidedId.text = egs.taxpayerProvidedId;
    _model.text = egs.model;
    _street.text = egs.location.street;
    _building.text = egs.location.building;
    _plot.text = egs.location.plotIdentification;
    _city.text = egs.location.city;
    _citySubdivision.text = egs.location.citySubdivision;
    _postalZone.text = egs.location.postalZone;
    if (_otp.text.isEmpty) _otp.text = state.otp;
  }

  EGSUnitInfo _buildEgs(OnboardingState state) => EGSUnitInfo(
    uuid: state.egs?.uuid ?? const Uuid().v4(),
    taxpayerProvidedId: _taxpayerProvidedId.text,
    model: _model.text,
    crnNumber: _crn.text,
    taxpayerName: _taxpayerName.text,
    vatNumber: _vatNumber.text,
    branchName: _branchName.text,
    branchIndustry: _branchIndustry.text,
    location: Location(
      city: _city.text,
      citySubdivision: _citySubdivision.text,
      street: _street.text,
      building: _building.text,
      plotIdentification: _plot.text.isEmpty ? _building.text : _plot.text,
      postalZone: _postalZone.text,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen:
          (prev, curr) =>
              prev.egs?.vatNumber != curr.egs?.vatNumber ||
              prev.otp != curr.otp ||
              (prev.egs == null && curr.egs != null),
      listener: (context, state) {
        if (state.egs != null && !_prefilled) {
          _hydrate(state);
          _prefilled = true;
        } else if (state.egs != null && state.otp == '123456') {
          _hydrate(state);
        }
      },
      builder: (context, state) {
        final twoColumn = Breakpoints.useTwoColumn(context);
        return PageShell(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child:
                twoColumn
                    ? _twoColumnLayout(context, state)
                    : _singleColumnLayout(context, state),
          ),
        );
      },
    );
  }

  Widget _singleColumnLayout(BuildContext context, OnboardingState state) =>
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heroHeader(context, state),
            Gaps.hMd,
            _envSection(context, state),
            Gaps.hMd,
            _egsSection(context, state),
            Gaps.hMd,
            _addressSection(context, state),
            Gaps.hMd,
            _otpSection(context, state),
            Gaps.hMd,
            _progressSection(context, state),
            if (state.errorMessage != null) ...[
              Gaps.hMd,
              _errorBanner(state.errorMessage!),
            ],
            Gaps.hMd,
            _actionButtons(context, state),
            Gaps.hMd,
            if (state.csrPem != null || state.complianceCertPem != null)
              _outputsSection(context, state),
            Gaps.hXl,
          ],
        ),
      );

  Widget _twoColumnLayout(BuildContext context, OnboardingState state) =>
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heroHeader(context, state),
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
                      _envSection(context, state),
                      Gaps.hMd,
                      _egsSection(context, state),
                      Gaps.hMd,
                      _addressSection(context, state),
                      Gaps.hMd,
                      _otpSection(context, state),
                      if (state.errorMessage != null) ...[
                        Gaps.hMd,
                        _errorBanner(state.errorMessage!),
                      ],
                      Gaps.hMd,
                      _actionButtons(context, state),
                    ],
                  ),
                ),
                Gaps.wLg,
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _progressSection(context, state),
                      if (state.csrPem != null ||
                          state.complianceCertPem != null) ...[
                        Gaps.hMd,
                        _outputsSection(context, state),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Gaps.hXl,
          ],
        ),
      );

  Widget _heroHeader(BuildContext context, OnboardingState state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Gaps.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.tertiaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set up your EGS device',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Gaps.hXs,
                Text(
                  'Register once per device: generate a key pair, sign a CSR, '
                  'and exchange it for a compliance certificate with ZATCA.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(
                      alpha: 0.85,
                    ),
                  ),
                ),
                Gaps.hMd,
                Wrap(
                  spacing: Gaps.sm,
                  runSpacing: Gaps.sm,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () {
                        context.read<OnboardingBloc>().add(
                          const OnboardingPrefilledWithSandboxData(),
                        );
                        _prefilled = false;
                      },
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text('Fill with sandbox data'),
                    ),
                    if (state.isReadyToInvoice)
                      OutlinedButton.icon(
                        onPressed: () => _confirmReset(context),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset onboarding'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (Breakpoints.useTwoColumn(context))
            Padding(
              padding: const EdgeInsets.only(left: Gaps.md),
              child: _progressBadge(context, state),
            ),
        ],
      ),
    );
  }

  Widget _progressBadge(BuildContext context, OnboardingState state) {
    final theme = Theme.of(context);
    final steps = [
      state.privateKeyPem != null,
      state.csrPem != null,
      state.hasComplianceCertificate,
    ];
    final done = steps.where((s) => s).length;
    return Container(
      padding: const EdgeInsets.all(Gaps.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: done / 3,
                  strokeWidth: 6,
                  backgroundColor: theme.colorScheme.outlineVariant,
                  color: theme.colorScheme.primary,
                ),
              ),
              Text(
                '$done/3',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Gaps.hSm,
          Text('Setup steps', style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _envSection(BuildContext context, OnboardingState state) =>
      SectionCard(
        icon: Icons.public,
        title: 'Environment',
        description: 'Choose which ZATCA endpoint to call.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _envSelector(context, state),
            Gaps.hMd,
            EnvironmentInfoCard(environment: state.environment),
          ],
        ),
      );

  Widget _egsSection(
    BuildContext context,
    OnboardingState state,
  ) => SectionCard(
    icon: Icons.badge_outlined,
    title: 'Taxpayer & EGS device',
    description: 'Identifying info that goes into the certificate.',
    child: Column(
      children: [
        _field(
          _taxpayerName,
          'Taxpayer name',
          helper: 'Legal entity name as registered with ZATCA',
          validator: (v) => Validators.required(v, label: 'Taxpayer name'),
        ),
        Gaps.hSm,
        _field(
          _vatNumber,
          'VAT number',
          helper: '15 digits, starts & ends with 3. Sandbox: 399999999900003',
          validator: Validators.vatNumber,
          keyboardType: TextInputType.number,
        ),
        Gaps.hSm,
        _field(
          _crn,
          'Commercial registration number (CRN)',
          helper: 'Any numeric string works for sandbox',
          validator: (v) => Validators.required(v, label: 'CRN'),
          keyboardType: TextInputType.number,
        ),
        Gaps.hMd,
        const Subheading('Branch'),
        Row(
          children: [
            Expanded(
              child: _field(
                _branchName,
                'Branch name',
                helper: 'Becomes the OU in the cert',
                validator: (v) => Validators.required(v, label: 'Branch name'),
              ),
            ),
            Gaps.wSm,
            Expanded(
              child: _field(
                _branchIndustry,
                'Branch industry',
                helper: 'e.g. Food, Retail',
                validator:
                    (v) => Validators.required(v, label: 'Branch industry'),
              ),
            ),
          ],
        ),
        Gaps.hMd,
        const Subheading('Device'),
        Row(
          children: [
            Expanded(
              child: _field(
                _taxpayerProvidedId,
                'EGS device ID',
                helper: 'Free text, e.g. POS-01',
                validator: (v) => Validators.required(v, label: 'Device ID'),
              ),
            ),
            Gaps.wSm,
            Expanded(
              child: _field(
                _model,
                'Device model',
                helper: 'Free text, e.g. iOS, Android',
                validator: (v) => Validators.required(v, label: 'Model'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _addressSection(BuildContext context, OnboardingState state) =>
      SectionCard(
        icon: Icons.location_on_outlined,
        title: 'Branch address',
        description: 'Physical address embedded in the certificate subject.',
        child: Column(
          children: [
            _field(
              _street,
              'Street',
              validator: (v) => Validators.required(v, label: 'Street'),
            ),
            Gaps.hSm,
            Row(
              children: [
                Expanded(
                  child: _field(
                    _building,
                    'Building #',
                    validator: (v) => Validators.required(v, label: 'Building'),
                  ),
                ),
                Gaps.wSm,
                Expanded(child: _field(_plot, 'Plot ID (optional)')),
              ],
            ),
            Gaps.hSm,
            Row(
              children: [
                Expanded(
                  child: _field(
                    _city,
                    'City',
                    validator: (v) => Validators.required(v, label: 'City'),
                  ),
                ),
                Gaps.wSm,
                Expanded(child: _field(_citySubdivision, 'City subdivision')),
              ],
            ),
            Gaps.hSm,
            _field(
              _postalZone,
              'Postal zone',
              keyboardType: TextInputType.number,
              validator: (v) => Validators.required(v, label: 'Postal zone'),
            ),
          ],
        ),
      );

  Widget _otpSection(BuildContext context, OnboardingState state) =>
      SectionCard(
        icon: Icons.lock_outline,
        title: 'One-Time Password',
        description: _otpHelper(state.environment),
        child: _field(
          _otp,
          'OTP',
          validator: Validators.otp,
          keyboardType: TextInputType.number,
        ),
      );

  Widget _progressSection(BuildContext context, OnboardingState state) =>
      SectionCard(
        icon: Icons.timeline,
        title: 'Progress',
        description: 'Each step in the ZATCA onboarding pipeline.',
        child: OnboardingStepper(state: state),
      );

  Widget _outputsSection(BuildContext context, OnboardingState state) =>
      SectionCard(
        icon: Icons.description_outlined,
        title: 'Generated artifacts',
        description: 'Copy these to verify or archive.',
        child: Column(
          children: [
            if (state.csrPem != null)
              CopyableBlock(
                title: 'Certificate Signing Request',
                subtitle: 'Sent to ZATCA to request a compliance cert.',
                content: state.csrPem!,
                maxLines: 4,
              ),
            if (state.complianceCertPem != null)
              CopyableBlock(
                title: 'Compliance certificate',
                subtitle: 'Request ID: ${state.complianceRequestId}',
                content: state.complianceCertPem!,
                maxLines: 4,
              ),
            if (state.productionCertPem != null)
              CopyableBlock(
                title: 'Production certificate',
                content: state.productionCertPem!,
                maxLines: 4,
              ),
          ],
        ),
      );

  String _otpHelper(ZatcaEnvironment env) => switch (env) {
    ZatcaEnvironment.sandbox =>
      'Sandbox uses the fixed OTP 123456 — any CSR will be accepted.',
    ZatcaEnvironment.simulation =>
      'Get an OTP from fatoora.zatca.gov.sa → Onboard new device.',
    ZatcaEnvironment.production =>
      '⚠️ Production. Get OTP from Fatoora portal — real invoices will be signed.',
  };

  Widget _envSelector(BuildContext context, OnboardingState state) {
    return SegmentedButton<ZatcaEnvironment>(
      segments: const [
        ButtonSegment(
          value: ZatcaEnvironment.sandbox,
          label: Text('Sandbox'),
          icon: Icon(Icons.science_outlined),
        ),
        ButtonSegment(
          value: ZatcaEnvironment.simulation,
          label: Text('Simulation'),
          icon: Icon(Icons.computer),
        ),
        ButtonSegment(
          value: ZatcaEnvironment.production,
          label: Text('Production'),
          icon: Icon(Icons.public),
        ),
      ],
      selected: {state.environment},
      onSelectionChanged:
          (s) => context.read<OnboardingBloc>().add(
            OnboardingEnvironmentChanged(s.first),
          ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? helper,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      helperMaxLines: 3,
    ),
    validator: validator,
  );

  Widget _errorBanner(String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Gaps.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          Gaps.wSm,
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context, OnboardingState state) {
    final isSubmitting = state.status == OnboardingStatus.submitting;
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed:
                isSubmitting
                    ? null
                    : () {
                      if (!_formKey.currentState!.validate()) return;
                      context.read<OnboardingBloc>()
                        ..add(OnboardingEgsChanged(_buildEgs(state)))
                        ..add(OnboardingOtpChanged(_otp.text))
                        ..add(const OnboardingSubmitted());
                    },
            icon:
                isSubmitting
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.verified_user),
            label: Text(
              state.hasComplianceCertificate
                  ? 'Re-issue compliance certificate'
                  : 'Generate keypair, CSR & request compliance cert',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (state.hasComplianceCertificate &&
            !state.hasProductionCertificate) ...[
          Gaps.hSm,
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed:
                  isSubmitting
                      ? null
                      : () => context.read<OnboardingBloc>().add(
                        const OnboardingProductionUpgradeRequested(),
                      ),
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade to production certificate (optional)'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Reset onboarding?'),
            content: const Text(
              'This deletes the private key, certificate, and all saved progress '
              '(including ICV counter and previous invoice hash). You\'ll need '
              'a new OTP to request a new compliance certificate.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Reset'),
              ),
            ],
          ),
    );
    if (ok == true && context.mounted) {
      context.read<OnboardingBloc>().add(const OnboardingReset());
      _prefilled = false;
    }
  }
}
