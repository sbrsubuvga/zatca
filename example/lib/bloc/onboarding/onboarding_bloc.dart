import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zatca/certificate_manager.dart';
import 'package:zatca/models/compliance_certificate.dart';

import '../../data/egs_json.dart';
import '../../data/sandbox_defaults.dart';
import '../../data/storage.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnboardingStorage storage;
  final CertificateManager certificateManager;

  OnboardingBloc({
    required this.storage,
    CertificateManager? certificateManager,
  }) : certificateManager = certificateManager ?? CertificateManager.instance,
       super(const OnboardingState()) {
    on<OnboardingLoadRequested>(_onLoad);
    on<OnboardingPrefilledWithSandboxData>(_onPrefill);
    on<OnboardingEnvironmentChanged>(_onEnvChanged);
    on<OnboardingEgsChanged>(_onEgsChanged);
    on<OnboardingOtpChanged>(_onOtpChanged);
    on<OnboardingSubmitted>(_onSubmitted);
    on<OnboardingProductionUpgradeRequested>(_onProductionUpgrade);
    on<OnboardingReset>(_onReset);
  }

  Future<void> _onLoad(
    OnboardingLoadRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(status: OnboardingStatus.loading));

    final env = await storage.loadEnvironment();
    final egsJson = await storage.loadEgs();
    final privateKey = await storage.loadPrivateKey();
    final compliance = await storage.loadComplianceCertificate();
    final production = await storage.loadProductionCertificate();

    final egs = egsJson != null ? EgsUnitJson.fromJson(egsJson) : null;

    final status = production != null
        ? OnboardingStatus.productionIssued
        : compliance != null
        ? OnboardingStatus.complianceIssued
        : OnboardingStatus.editing;

    emit(
      state.copyWith(
        status: status,
        environment: env,
        egs: egs,
        privateKeyPem: privateKey,
        complianceCertPem: compliance?.pem,
        complianceSecret: compliance?.secret,
        complianceRequestId: compliance?.requestId,
        productionCertPem: production?.pem,
        productionSecret: production?.secret,
        clearError: true,
      ),
    );
  }

  Future<void> _onPrefill(
    OnboardingPrefilledWithSandboxData event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(
      state.copyWith(
        status: OnboardingStatus.editing,
        egs: SandboxDefaults.egsUnitInfo(),
        otp: SandboxDefaults.otp,
        clearError: true,
      ),
    );
  }

  Future<void> _onEnvChanged(
    OnboardingEnvironmentChanged event,
    Emitter<OnboardingState> emit,
  ) async {
    await storage.saveEnvironment(event.environment);
    emit(state.copyWith(environment: event.environment, clearError: true));
  }

  void _onEgsChanged(
    OnboardingEgsChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(
      state.copyWith(
        egs: event.egs,
        status: OnboardingStatus.editing,
        clearError: true,
      ),
    );
  }

  void _onOtpChanged(
    OnboardingOtpChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(state.copyWith(otp: event.otp, clearError: true));
  }

  Future<void> _onSubmitted(
    OnboardingSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    final egs = state.egs;
    if (egs == null) {
      emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: 'Please fill in the EGS information first.',
        ),
      );
      return;
    }
    if (state.otp.trim().isEmpty) {
      emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage:
              'OTP is required. Use 123456 for sandbox, or get one from '
              'fatoora.zatca.gov.sa for simulation/production.',
        ),
      );
      return;
    }

    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage:
              'CSR generation requires OpenSSL and only runs on '
              'desktop platforms (macOS / Linux / Windows). Use a '
              'desktop build for this example.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: OnboardingStatus.submitting, clearError: true));
    try {
      certificateManager.env = state.environment;

      final keyPair = certificateManager.generateKeyPair();
      final privateKeyPem = keyPair['privateKeyPem'] as String;

      emit(
        state.copyWith(
          privateKeyPem: privateKeyPem,
          status: OnboardingStatus.submitting,
        ),
      );

      final tempDir = await getApplicationDocumentsDirectory();
      final csrProps = egs.toCsrProps(
        'flutter-example',
        environment: state.environment,
      );
      final csr = await certificateManager.generateCSR(
        privateKeyPem,
        csrProps,
        tempDir.path,
      );

      emit(
        state.copyWith(csrPem: csr, status: OnboardingStatus.csrGenerated),
      );

      final ZatcaCertificate compliance = await certificateManager
          .issueComplianceCertificate(
            csr,
            state.otp.trim(),
            environment: state.environment,
          );

      await storage.saveEnvironment(state.environment);
      await storage.saveEgs(egs.toJson());
      await storage.savePrivateKey(privateKeyPem);
      await storage.saveComplianceCertificate(
        pem: compliance.complianceCertificatePem,
        secret: compliance.complianceApiSecret,
        requestId: compliance.complianceRequestId,
      );

      emit(
        state.copyWith(
          status: OnboardingStatus.complianceIssued,
          complianceCertPem: compliance.complianceCertificatePem,
          complianceSecret: compliance.complianceApiSecret,
          complianceRequestId: compliance.complianceRequestId,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: _humanize(e),
        ),
      );
    }
  }

  Future<void> _onProductionUpgrade(
    OnboardingProductionUpgradeRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    if (!state.hasComplianceCertificate) {
      emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: 'Issue a compliance certificate first.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: OnboardingStatus.submitting, clearError: true));

    try {
      certificateManager.env = state.environment;

      final compliance = ZatcaCertificate(
        complianceCertificatePem: state.complianceCertPem!,
        complianceApiSecret: state.complianceSecret!,
        complianceRequestId: state.complianceRequestId!,
      );

      final production = await certificateManager.issueProductionCertificate(
        compliance,
        environment: state.environment,
      );

      await storage.saveProductionCertificate(
        pem: production.complianceCertificatePem,
        secret: production.complianceApiSecret,
      );

      emit(
        state.copyWith(
          status: OnboardingStatus.productionIssued,
          productionCertPem: production.complianceCertificatePem,
          productionSecret: production.complianceApiSecret,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: _humanize(e),
        ),
      );
    }
  }

  Future<void> _onReset(
    OnboardingReset event,
    Emitter<OnboardingState> emit,
  ) async {
    await storage.clear();
    emit(const OnboardingState(status: OnboardingStatus.editing));
  }

  String _humanize(Object e) {
    final msg = e.toString();
    if (msg.contains('OpenSSL')) {
      return 'OpenSSL is required for CSR generation. '
          'Install it (brew install openssl on macOS, '
          'apt install openssl on Linux) and try again.';
    }
    if (msg.contains('compliance certificate')) {
      return 'ZATCA rejected the compliance request. '
          'Check that: (1) your OTP matches the environment '
          '(sandbox uses 123456); (2) your VAT number is 15 digits '
          'starting & ending with 3; (3) the environment matches '
          'where the OTP was issued.';
    }
    return msg;
  }
}
