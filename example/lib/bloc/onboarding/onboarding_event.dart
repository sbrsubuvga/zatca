import 'package:equatable/equatable.dart';
import 'package:zatca/models/egs_unit.dart';
import 'package:zatca/resources/enums.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

/// Fired on app start — hydrate saved state from storage.
class OnboardingLoadRequested extends OnboardingEvent {
  const OnboardingLoadRequested();
}

/// Fill the form with sandbox test data so a first-time developer
/// can get going without reading the docs.
class OnboardingPrefilledWithSandboxData extends OnboardingEvent {
  const OnboardingPrefilledWithSandboxData();
}

/// User switched environment (sandbox / simulation / production).
class OnboardingEnvironmentChanged extends OnboardingEvent {
  final ZatcaEnvironment environment;
  const OnboardingEnvironmentChanged(this.environment);
  @override
  List<Object?> get props => [environment];
}

/// User edited the EGS form.
class OnboardingEgsChanged extends OnboardingEvent {
  final EGSUnitInfo egs;
  const OnboardingEgsChanged(this.egs);
  @override
  List<Object?> get props => [egs];
}

/// User edited the OTP field.
class OnboardingOtpChanged extends OnboardingEvent {
  final String otp;
  const OnboardingOtpChanged(this.otp);
  @override
  List<Object?> get props => [otp];
}

/// Run the full onboarding flow: keypair → CSR → compliance cert.
class OnboardingSubmitted extends OnboardingEvent {
  const OnboardingSubmitted();
}

/// Optional step: upgrade compliance cert to production cert.
class OnboardingProductionUpgradeRequested extends OnboardingEvent {
  const OnboardingProductionUpgradeRequested();
}

/// Clear everything and start over.
class OnboardingReset extends OnboardingEvent {
  const OnboardingReset();
}
