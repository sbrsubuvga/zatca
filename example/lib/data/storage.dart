import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zatca/resources/enums.dart';

/// Wrapper around SharedPreferences to persist onboarding data
/// between launches, so integrators don't have to re-generate a
/// certificate every time.
///
/// ⚠️ SECURITY NOTE FOR PRODUCTION USE ⚠️
///
/// This example uses [SharedPreferences] for simplicity. In a real
/// integration, the private key is a sensitive credential and should
/// NEVER be stored in plain SharedPreferences. Use the
/// `flutter_secure_storage` package instead:
///
///   dependencies:
///     flutter_secure_storage: ^9.2.2
///
///   final storage = FlutterSecureStorage();
///   await storage.write(key: 'zatca_private_key', value: privateKeyPem);
///   final pk = await storage.read(key: 'zatca_private_key');
///
/// `flutter_secure_storage` stores values in the iOS Keychain and
/// the Android EncryptedSharedPreferences, which are much safer
/// than plain preferences.
class OnboardingStorage {
  static const _kEgs = 'zatca_egs';
  static const _kEnv = 'zatca_env';
  static const _kPrivateKey = 'zatca_private_key';
  static const _kComplianceCert = 'zatca_compliance_cert';
  static const _kComplianceSecret = 'zatca_compliance_secret';
  static const _kComplianceRequestId = 'zatca_compliance_request_id';
  static const _kProductionCert = 'zatca_production_cert';
  static const _kProductionSecret = 'zatca_production_secret';
  static const _kIcv = 'zatca_icv';
  static const _kPih = 'zatca_pih';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> saveEgs(Map<String, dynamic> json) async {
    final prefs = await _prefs;
    await prefs.setString(_kEgs, jsonEncode(json));
  }

  Future<Map<String, dynamic>?> loadEgs() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kEgs);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveEnvironment(ZatcaEnvironment env) async {
    final prefs = await _prefs;
    await prefs.setString(_kEnv, env.value);
  }

  Future<ZatcaEnvironment> loadEnvironment() async {
    final prefs = await _prefs;
    final value = prefs.getString(_kEnv);
    return ZatcaEnvironment.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ZatcaEnvironment.sandbox,
    );
  }

  Future<void> savePrivateKey(String pem) async {
    final prefs = await _prefs;
    await prefs.setString(_kPrivateKey, pem);
  }

  Future<String?> loadPrivateKey() async {
    final prefs = await _prefs;
    return prefs.getString(_kPrivateKey);
  }

  Future<void> saveComplianceCertificate({
    required String pem,
    required String secret,
    required String requestId,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_kComplianceCert, pem);
    await prefs.setString(_kComplianceSecret, secret);
    await prefs.setString(_kComplianceRequestId, requestId);
  }

  Future<({String pem, String secret, String requestId})?>
  loadComplianceCertificate() async {
    final prefs = await _prefs;
    final pem = prefs.getString(_kComplianceCert);
    final secret = prefs.getString(_kComplianceSecret);
    final requestId = prefs.getString(_kComplianceRequestId);
    if (pem == null || secret == null || requestId == null) return null;
    return (pem: pem, secret: secret, requestId: requestId);
  }

  Future<void> saveProductionCertificate({
    required String pem,
    required String secret,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_kProductionCert, pem);
    await prefs.setString(_kProductionSecret, secret);
  }

  Future<({String pem, String secret})?> loadProductionCertificate() async {
    final prefs = await _prefs;
    final pem = prefs.getString(_kProductionCert);
    final secret = prefs.getString(_kProductionSecret);
    if (pem == null || secret == null) return null;
    return (pem: pem, secret: secret);
  }

  Future<int> loadIcv() async {
    final prefs = await _prefs;
    return prefs.getInt(_kIcv) ?? 0;
  }

  Future<void> saveIcv(int icv) async {
    final prefs = await _prefs;
    await prefs.setInt(_kIcv, icv);
  }

  Future<String> loadPih() async {
    final prefs = await _prefs;
    return prefs.getString(_kPih) ??
        'NWZlY2ViNjZmZmM4NmYzOGQ5NTI3ODZjNmQ2OTZjNzljMmRiYzIzOWRkNGU5MWI0NjcyOWQ3M2EyN2ZiNTdlOQ==';
  }

  Future<void> savePih(String pih) async {
    final prefs = await _prefs;
    await prefs.setString(_kPih, pih);
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
