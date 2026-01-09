import 'dart:io';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:zatca/resources/api/api.dart';
import 'package:zatca/resources/cirtificate/templates/csr_template.dart';

import 'resources/enums.dart';
import 'resources/cirtificate/certficate_util.dart';
import 'models/compliance_certificate.dart';

/// The `CertificateManager` class is a singleton that manages the generation of key pairs, CSRs, and the issuance of compliance and production certificates.
class CertificateManager {
  ZatcaEnvironment env = ZatcaEnvironment.sandbox;
  CertificateManager._();

  /// The single instance of the `CertificateManager` class.
  static CertificateManager instance = CertificateManager._();

  /// Generates a key pair for the EGS unit.
  Map<String, dynamic> generateKeyPair() {
    {
      final keyPair = CryptoUtils.generateEcKeyPair(curve: 'secp256k1');

      final privateKey = keyPair.privateKey as ECPrivateKey;
      // final publicKey = keyPair.publicKey as ECPublicKey;

      final privatePem = CryptoUtils.encodeEcPrivateKeyToPem(privateKey);
      return {'privateKeyPem': privatePem};
    }
  }

  /// Generates a CSR (Certificate Signing Request) using the provided private key and CSR configuration properties.
  Future<String> generateCSR(
    String privateKeyPem,
    CSRConfigProps csrProps,
    String path,
  ) {
    /// Check if the platform is desktop (Windows, Linux, or macOS)
    bool isDeskTop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    /// If the platform is desktop, generate the CSR using OpenSSL
    if (isDeskTop) {
      return generateCSRInDeskTop(privateKeyPem, csrProps, path);
    } else {
      /// If the platform is not desktop, throw an exception
      throw Exception(
        "CSR generation is not supported on this platform. Please use a desktop platform (Windows, Linux, or macOS) to generate the CSR.",
      );
    }
  }

  /// Generates a CSR (Certificate Signing Request) using the provided private key and CSR configuration properties.
  Future<String> generateCSRInDeskTop(
    String privateKeyPem,
    CSRConfigProps csrProps,
    String path,
  ) async {
    // Directory supDir = await getApplicationSupportDirectory();
    // String dbPath = supDir.path;
    // final privateKeyFile = '$dbPath/${Uuid().v4()}.pem';
    // final csrConfigFile = '$dbPath/${Uuid().v4()}.cnf';

    final privateKeyFile = '$path/${Uuid().v4()}.pem';
    final csrConfigFile = '$path/${Uuid().v4()}.cnf';

    // final privateKeyFile =
    //     '${Platform.environment['TEMP_FOLDER'] ?? "/tmp/"}${Uuid().v4()}.pem';
    // final csrConfigFile =
    //     '${Platform.environment['TEMP_FOLDER'] ?? "/tmp/"}${Uuid().v4()}.cnf';

    try {
      File(privateKeyFile).writeAsStringSync(privateKeyPem);
      File(csrConfigFile).writeAsStringSync(csrProps.toTemplate());

      final opensslCheckProcess = await Process.run('openssl', ['version']);
      if (opensslCheckProcess.exitCode == 0) {
        debugPrint('OpenSSL is installed: ${opensslCheckProcess.stdout}');
      } else {
        if (Platform.isWindows) {
          await _installAndSetupOpenSSLInWindows();
        } else {
          throw Exception('Error: no CSR found in OpenSSL output.');
        }
      }

      /// Execute the OpenSSL command
      final process = await Process.start('openssl', [
        'req',
        '-new',
        '-sha256',
        '-key',
        privateKeyFile,
        '-config',
        csrConfigFile,
      ]);

      /// Capture the output
      final output = await process.stdout.transform(utf8.decoder).join();
      final errorOutput = await process.stderr.transform(utf8.decoder).join();

      /// Check for errors
      if (errorOutput.isNotEmpty) {
        if (errorOutput.contains('Operation not permitted')) {
          throw Exception(
            'Permission denied: Unable to execute OpenSSL. Please ensure the application has the necessary permissions to execute external processes.',
          );
        }
        throw Exception('OpenSSL error: $errorOutput');
      }

      /// Check if the CSR is present in the output
      if (!output.contains('-----BEGIN CERTIFICATE REQUEST-----')) {
        throw Exception('Error: no CSR found in OpenSSL output.');
      }

      /// Extract the CSR
      final csr =
          '-----BEGIN CERTIFICATE REQUEST-----${output.split('-----BEGIN CERTIFICATE REQUEST-----')[1]}'
              .trim();

      /// Perform cleanup if necessary
      File(privateKeyFile).deleteSync();
      File(csrConfigFile).deleteSync();

      return csr;
    } catch (e) {
      debugPrint("Error during CSR generation: $e");

      // Perform cleanup in case of an error
      if (File(privateKeyFile).existsSync()) {
        File(privateKeyFile).deleteSync();
      }
      if (File(csrConfigFile).existsSync()) {
        File(csrConfigFile).deleteSync();
      }

      // Rethrow the exception for further handling
      rethrow;
    }
  }

  Future<void> _installAndSetupOpenSSLInWindows() async {
    try {
      // Step 1: Download OpenSSL installer
      final downloadUrl =
          'https://slproweb.com/download/Win64OpenSSL-3_1_2.msi';
      final installerPath =
          'C:\\Users\\${Platform.environment['USERNAME']}\\Downloads\\OpenSSLInstaller.msi';

      debugPrint('Downloading OpenSSL installer...');
      final downloadProcess = await Process.start('powershell', [
        '-Command',
        'Invoke-WebRequest',
        '-Uri',
        downloadUrl,
        '-OutFile',
        installerPath,
      ]);
      await downloadProcess.exitCode;

      // Step 2: Install OpenSSL silently
      debugPrint('Installing OpenSSL...');
      final installProcess = await Process.start('msiexec', [
        '/i',
        installerPath,
        '/quiet',
        '/norestart',
      ]);
      await installProcess.exitCode;

      // Step 3: Add OpenSSL to PATH
      final openSslBinPath = 'C:\\Program Files\\OpenSSL-Win64\\bin';
      debugPrint('Adding OpenSSL to PATH...');
      final pathUpdateProcess = await Process.start('setx', [
        'PATH',
        '%PATH%;$openSslBinPath',
      ], runInShell: true);
      await pathUpdateProcess.exitCode;

      debugPrint('OpenSSL installation and setup completed successfully.');
    } catch (e) {
      debugPrint('Error during OpenSSL installation: $e');
    }
  }

  /// Issues a compliance certificate using the provided CSR and OTP.
  /// Issues a compliance certificate using the provided CSR and OTP.
  Future<ZatcaCertificate> issueComplianceCertificate(
    String csr,
    String otp, {
    ZatcaEnvironment? environment,
  }) async {
    final api = API(environment ?? env);
    final Map<String, dynamic> response = await api
        .compliance()
        .issueCertificate(csr, otp);
    return ZatcaCertificate.fromJson(response);
  }

  /// Issues a production certificate using the provided compliance certificate.
  Future<ZatcaCertificate> issueProductionCertificate(
    ZatcaCertificate certificate, {
    ZatcaEnvironment? environment,
  }) async {
    final api = API(environment ?? env); // ← Changed this line
    final String cleanPem = CertificateUtil.cleanCertificatePem(
      certificate.complianceCertificatePem,
    );
    final Map<String, dynamic> response = await api
        .production(cleanPem, certificate.complianceApiSecret)
        .issueCertificate(certificate.complianceRequestId);
    return ZatcaCertificate.fromJson(response);
  }

  /// Check invoice compliance
  Future<void> checkInvoiceCompliance({
    required ZatcaCertificate complianceCertificate,
    required String ublXml,
    required String invoiceHash,
    required String uuid,
    ZatcaEnvironment? environment, // ← Add this parameter
  }) async {
    final api = API(environment ?? env); // ← Changed this line
    final String cleanPem = CertificateUtil.cleanCertificatePem(
      complianceCertificate.complianceCertificatePem,
    );
    final Map<String, dynamic> response = await api
        .compliance(
          certificate: cleanPem,
          secret: complianceCertificate.complianceApiSecret,
        )
        .checkInvoiceCompliance(
          signedXmlString: ublXml,
          invoiceHash: invoiceHash,
          egsUuid: uuid,
        );
    debugPrint("Response: ${response.toString()}");
  }
}
