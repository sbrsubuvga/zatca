import 'package:zatca/models/address.dart';
import 'package:zatca/models/egs_unit.dart';

/// Helpers to serialize [EGSUnitInfo] to/from JSON for storage.
/// The package doesn't ship JSON helpers for this model.
extension EgsUnitJson on EGSUnitInfo {
  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'taxpayerProvidedId': taxpayerProvidedId,
    'model': model,
    'crnNumber': crnNumber,
    'taxpayerName': taxpayerName,
    'vatNumber': vatNumber,
    'branchName': branchName,
    'branchIndustry': branchIndustry,
    'location': {
      'city': location.city,
      'citySubdivision': location.citySubdivision,
      'street': location.street,
      'building': location.building,
      'plotIdentification': location.plotIdentification,
      'postalZone': location.postalZone,
      'countryCode': location.countryCode,
    },
  };

  static EGSUnitInfo fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>;
    return EGSUnitInfo(
      uuid: json['uuid'] as String,
      taxpayerProvidedId: json['taxpayerProvidedId'] as String,
      model: json['model'] as String,
      crnNumber: json['crnNumber'] as String,
      taxpayerName: json['taxpayerName'] as String,
      vatNumber: json['vatNumber'] as String,
      branchName: json['branchName'] as String,
      branchIndustry: json['branchIndustry'] as String,
      location: Location(
        city: loc['city'] as String,
        citySubdivision: loc['citySubdivision'] as String,
        street: loc['street'] as String,
        building: loc['building'] as String,
        plotIdentification: loc['plotIdentification'] as String,
        postalZone: loc['postalZone'] as String,
        countryCode: (loc['countryCode'] as String?) ?? 'SA',
      ),
    );
  }
}
