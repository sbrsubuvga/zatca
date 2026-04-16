import 'package:equatable/equatable.dart';
import 'package:zatca/models/egs_unit.dart';
import 'package:zatca/resources/enums.dart';

enum OnboardingStatus {
  initial,
  loading,
  editing,
  submitting,
  csrGenerated,
  complianceIssued,
  productionIssued,
  failure,
}

class OnboardingState extends Equatable {
  final OnboardingStatus status;
  final ZatcaEnvironment environment;
  final EGSUnitInfo? egs;
  final String otp;
  final String? privateKeyPem;
  final String? csrPem;
  final String? complianceCertPem;
  final String? complianceSecret;
  final String? complianceRequestId;
  final String? productionCertPem;
  final String? productionSecret;
  final String? errorMessage;

  const OnboardingState({
    this.status = OnboardingStatus.initial,
    this.environment = ZatcaEnvironment.sandbox,
    this.egs,
    this.otp = '',
    this.privateKeyPem,
    this.csrPem,
    this.complianceCertPem,
    this.complianceSecret,
    this.complianceRequestId,
    this.productionCertPem,
    this.productionSecret,
    this.errorMessage,
  });

  bool get hasComplianceCertificate => complianceCertPem != null;
  bool get hasProductionCertificate => productionCertPem != null;

  /// True once the device is onboarded enough to issue test invoices.
  bool get isReadyToInvoice => hasComplianceCertificate && privateKeyPem != null;

  OnboardingState copyWith({
    OnboardingStatus? status,
    ZatcaEnvironment? environment,
    EGSUnitInfo? egs,
    String? otp,
    String? privateKeyPem,
    String? csrPem,
    String? complianceCertPem,
    String? complianceSecret,
    String? complianceRequestId,
    String? productionCertPem,
    String? productionSecret,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      environment: environment ?? this.environment,
      egs: egs ?? this.egs,
      otp: otp ?? this.otp,
      privateKeyPem: privateKeyPem ?? this.privateKeyPem,
      csrPem: csrPem ?? this.csrPem,
      complianceCertPem: complianceCertPem ?? this.complianceCertPem,
      complianceSecret: complianceSecret ?? this.complianceSecret,
      complianceRequestId: complianceRequestId ?? this.complianceRequestId,
      productionCertPem: productionCertPem ?? this.productionCertPem,
      productionSecret: productionSecret ?? this.productionSecret,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    environment,
    egs?.uuid,
    egs?.vatNumber,
    egs?.taxpayerName,
    otp,
    privateKeyPem,
    csrPem,
    complianceCertPem,
    complianceSecret,
    complianceRequestId,
    productionCertPem,
    productionSecret,
    errorMessage,
  ];
}
