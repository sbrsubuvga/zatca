import 'package:uuid/uuid.dart';
import 'package:zatca/models/address.dart';
import 'package:zatca/models/egs_unit.dart';

/// Pre-filled test values for ZATCA Sandbox. These are known-good
/// values that let a developer go from "installed the package" to
/// "got a compliance certificate" in a single tap.
///
/// Do NOT use these values in simulation or production — they are
/// sandbox-only and will be rejected elsewhere.
class SandboxDefaults {
  /// The fixed OTP accepted by the ZATCA sandbox developer portal
  /// for any CSR. Simulation and production require real OTPs
  /// obtained from fatoora.zatca.gov.sa.
  static const String otp = '123456';

  /// A well-formed VAT number for sandbox use: 15 digits starting
  /// and ending with "3".
  static const String vatNumber = '399999999900003';

  static EGSUnitInfo egsUnitInfo() => EGSUnitInfo(
    uuid: const Uuid().v4(),
    taxpayerProvidedId: 'EGS1',
    model: 'Flutter',
    crnNumber: '454634645645654',
    taxpayerName: 'Test Taxpayer',
    vatNumber: vatNumber,
    branchName: 'Main Branch',
    branchIndustry: 'Food',
    location: Location(
      city: 'Khobar',
      citySubdivision: 'West',
      street: 'King Fahd Rd',
      plotIdentification: '0000',
      building: '0000',
      postalZone: '31952',
    ),
  );
}
