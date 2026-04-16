import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zatca/models/address.dart';
import 'package:zatca/models/egs_unit.dart';
import 'package:zatca/resources/enums.dart';

import '../bloc/onboarding/onboarding_bloc.dart';
import '../bloc/onboarding/onboarding_event.dart';
import '../bloc/onboarding/onboarding_state.dart';
import '../util/validators.dart';
import '../widgets/copyable_block.dart';
import '../widgets/env_info_card.dart';
import '../widgets/onboarding_stepper.dart';

/// Walks the user through registering an EGS device with ZATCA:
/// pick env, fill form, generate keypair, CSR, compliance cert,
/// (optionally) upgrade to production cert.
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
      listenWhen: (prev, curr) =>
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
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context, state),
                  const SizedBox(height: 8),
                  EnvironmentInfoCard(environment: state.environment),
                  _envSelector(context, state),
                  const SizedBox(height: 8),
                  _prefillButton(context),
                  const SizedBox(height: 16),
                  _sectionTitle('Taxpayer & EGS device'),
                  _field(
                    _taxpayerName,
                    'Taxpayer name',
                    helper: 'Legal entity name as registered with ZATCA',
                    validator: (v) =>
                        Validators.required(v, label: 'Taxpayer name'),
                  ),
                  _field(
                    _vatNumber,
                    'VAT number',
                    helper: '15 digits, starts & ends with 3. '
                        'Sandbox sample: 399999999900003',
                    validator: Validators.vatNumber,
                    keyboardType: TextInputType.number,
                  ),
                  _field(
                    _crn,
                    'Commercial registration number (CRN)',
                    helper: 'Any numeric string works for sandbox',
                    validator: (v) => Validators.required(v, label: 'CRN'),
                    keyboardType: TextInputType.number,
                  ),
                  _field(
                    _branchName,
                    'Branch name',
                    helper: 'Becomes the Organizational Unit in the certificate',
                    validator: (v) =>
                        Validators.required(v, label: 'Branch name'),
                  ),
                  _field(
                    _branchIndustry,
                    'Branch industry',
                    helper: 'e.g. Food, Retail, Services',
                    validator: (v) =>
                        Validators.required(v, label: 'Branch industry'),
                  ),
                  _field(
                    _taxpayerProvidedId,
                    'EGS device ID',
                    helper: 'Free text — identifies this specific device',
                    validator: (v) => Validators.required(v, label: 'Device ID'),
                  ),
                  _field(
                    _model,
                    'Device model',
                    helper: 'e.g. Flutter, iOS, Android, Web, POS-1',
                    validator: (v) => Validators.required(v, label: 'Model'),
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle('Branch address'),
                  _field(
                    _street,
                    'Street',
                    validator: (v) => Validators.required(v, label: 'Street'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _building,
                          'Building #',
                          validator: (v) =>
                              Validators.required(v, label: 'Building'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _field(_plot, 'Plot ID (optional)'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _city,
                          'City',
                          validator: (v) => Validators.required(v, label: 'City'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _field(_citySubdivision, 'City subdivision'),
                      ),
                    ],
                  ),
                  _field(
                    _postalZone,
                    'Postal zone',
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        Validators.required(v, label: 'Postal zone'),
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle('OTP'),
                  _field(
                    _otp,
                    'One-Time Password',
                    helper: _otpHelper(state.environment),
                    validator: Validators.otp,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Progress'),
                  OnboardingStepper(state: state),
                  const SizedBox(height: 16),
                  if (state.errorMessage != null) _errorBanner(state.errorMessage!),
                  _actionButtons(context, state),
                  if (state.csrPem != null)
                    CopyableBlock(
                      title: 'Generated CSR',
                      subtitle: 'Sent to ZATCA in step 3',
                      content: state.csrPem!,
                      maxLines: 6,
                    ),
                  if (state.complianceCertPem != null)
                    CopyableBlock(
                      title: 'Compliance certificate',
                      subtitle:
                          'Request ID: ${state.complianceRequestId}',
                      content: state.complianceCertPem!,
                      maxLines: 6,
                    ),
                  if (state.productionCertPem != null)
                    CopyableBlock(
                      title: 'Production certificate',
                      content: state.productionCertPem!,
                      maxLines: 6,
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _otpHelper(ZatcaEnvironment env) => switch (env) {
    ZatcaEnvironment.sandbox =>
      'Sandbox uses the fixed OTP 123456 — any CSR will be accepted.',
    ZatcaEnvironment.simulation =>
      'Get an OTP from fatoora.zatca.gov.sa → Onboard new solution/device.',
    ZatcaEnvironment.production =>
      '⚠️ Production. Get OTP from Fatoora portal — real invoices will be signed.',
  };

  Widget _header(BuildContext context, OnboardingState state) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Set up your EGS device',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (state.isReadyToInvoice)
              TextButton.icon(
                onPressed: () => _confirmReset(context),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset'),
              ),
          ],
        ),
        Text(
          'Once per device: generate a key pair, sign a CSR, and exchange it for a '
          'compliance certificate with ZATCA.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

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
      onSelectionChanged: (s) {
        context.read<OnboardingBloc>().add(
          OnboardingEnvironmentChanged(s.first),
        );
      },
    );
  }

  Widget _prefillButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        context.read<OnboardingBloc>().add(
          const OnboardingPrefilledWithSandboxData(),
        );
        _prefilled = false;
      },
      icon: const Icon(Icons.bolt),
      label: const Text('Fill form with known-good sandbox data'),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    String? helper,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: validator,
      ),
    );
  }

  Widget _errorBanner(String message) => Card(
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
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _actionButtons(BuildContext context, OnboardingState state) {
    final isSubmitting = state.status == OnboardingStatus.submitting;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isSubmitting
                ? null
                : () {
                    if (!_formKey.currentState!.validate()) return;
                    context.read<OnboardingBloc>()
                      ..add(OnboardingEgsChanged(_buildEgs(state)))
                      ..add(OnboardingOtpChanged(_otp.text))
                      ..add(const OnboardingSubmitted());
                  },
            icon: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_user),
            label: Text(
              state.hasComplianceCertificate
                  ? 'Re-issue compliance certificate'
                  : 'Generate keypair, CSR & request compliance cert',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (state.hasComplianceCertificate && !state.hasProductionCertificate)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () => context.read<OnboardingBloc>().add(
                        const OnboardingProductionUpgradeRequested(),
                      ),
                icon: const Icon(Icons.upgrade),
                label: const Text(
                  'Upgrade to production certificate (optional)',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset onboarding?'),
        content: const Text(
          'This deletes the private key, certificate, and all saved progress '
          '(including ICV counter and previous invoice hash). You\'ll need to '
          'request a new compliance certificate with a fresh OTP.',
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
