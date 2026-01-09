import '../resources/cirtificate/templates/csr_template.dart';
import '../resources/enums.dart';
import 'address.dart';

/// Represents an EGS unit information.
class EGSUnitInfo {
  /// The UUID of the EGS unit.
  final String uuid;

  /// The taxpayer-provided ID of the EGS unit.
  final String taxpayerProvidedId;

  /// The model of the EGS unit.
  final String model;

  /// The CRN number of the EGS unit.
  final String crnNumber;

  /// The name of the taxpayer.
  final String taxpayerName;

  /// The VAT number of the EGS unit.
  final String vatNumber;

  /// The name of the branch.
  final String branchName;

  /// The industry of the branch.
  final String branchIndustry;

  /// The location of the EGS unit.
  final Location location;

  EGSUnitInfo({
    required this.uuid,
    required this.taxpayerProvidedId,
    required this.model,
    required this.crnNumber,
    required this.taxpayerName,
    required this.vatNumber,
    required this.branchName,
    required this.branchIndustry,
    required this.location,
  });

  CSRConfigProps toCsrProps(
    String solutionName, {
    ZatcaEnvironment environment = ZatcaEnvironment.sandbox,
  }) {
    return CSRConfigProps(
      egsModel: model,
      egsSerialNumber: uuid,
      solutionName: solutionName,
      vatNumber: vatNumber,
      branchLocation: location.branchLocation,
      branchIndustry: branchIndustry,
      branchName: branchName,
      taxpayerName: taxpayerName,
      taxpayerProvidedId: taxpayerProvidedId,
      environment: environment,
    );
  }
}
