import 'package:flutter/material.dart';

import '../bloc/onboarding/onboarding_state.dart';

/// Visual progress stepper for the onboarding flow. Each step
/// maps to one stage of the ZATCA device registration process.
class OnboardingStepper extends StatelessWidget {
  final OnboardingState state;
  const OnboardingStepper({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _step(
          context,
          number: 1,
          title: 'Generate keypair',
          description: 'ECDSA secp256k1 keypair, signs every future invoice.',
          status: _stepStatus(1),
          done: state.privateKeyPem != null,
        ),
        _step(
          context,
          number: 2,
          title: 'Build CSR',
          description:
              'Certificate Signing Request with your EGS identifying info, '
              'signed by your private key. Requires OpenSSL.',
          status: _stepStatus(2),
          done: state.csrPem != null,
        ),
        _step(
          context,
          number: 3,
          title: 'Request compliance certificate',
          description:
              'POST /compliance with CSR + OTP. ZATCA returns a certificate, '
              'a request ID, and a secret used for API auth.',
          status: _stepStatus(3),
          done: state.complianceCertPem != null,
        ),
        _step(
          context,
          number: 4,
          title: 'Upgrade to production certificate  (optional)',
          description:
              'POST /production/csids. After at least one successful '
              'compliance invoice check, trade in the compliance cert '
              'for a production cert usable with real reporting/clearance.',
          status: _stepStatus(4),
          done: state.productionCertPem != null,
        ),
      ],
    );
  }

  _StepStatus _stepStatus(int step) {
    if (state.status == OnboardingStatus.failure && _currentStep() == step) {
      return _StepStatus.failed;
    }
    if (_currentStep() == step &&
        state.status == OnboardingStatus.submitting) {
      return _StepStatus.active;
    }
    if (_currentStep() > step) return _StepStatus.done;
    if (step == 4 && state.hasProductionCertificate) return _StepStatus.done;
    if (state.status == OnboardingStatus.editing) return _StepStatus.pending;
    return _StepStatus.pending;
  }

  int _currentStep() {
    if (state.hasProductionCertificate) return 5;
    if (state.hasComplianceCertificate) return 4;
    if (state.csrPem != null) return 3;
    if (state.privateKeyPem != null) return 2;
    return 1;
  }

  Widget _step(
    BuildContext context, {
    required int number,
    required String title,
    required String description,
    required _StepStatus status,
    required bool done,
  }) {
    final theme = Theme.of(context);
    final color = switch (status) {
      _StepStatus.done => Colors.green,
      _StepStatus.active => theme.colorScheme.primary,
      _StepStatus.failed => theme.colorScheme.error,
      _StepStatus.pending => theme.hintColor,
    };

    final icon = switch (status) {
      _StepStatus.done => const Icon(Icons.check, color: Colors.white),
      _StepStatus.active => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      ),
      _StepStatus.failed => const Icon(Icons.close, color: Colors.white),
      _StepStatus.pending => Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: status == _StepStatus.pending
                        ? theme.hintColor
                        : null,
                  ),
                ),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepStatus { pending, active, done, failed }
