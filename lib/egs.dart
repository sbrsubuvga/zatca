import 'package:flutter_zatca/zatca_invoice.dart';

class EGSUnitLocation {
  String? city;
  String? citySubdivision;
  String? street;
  String? plotIdentification;
  String? building;
  String? postalZone;

  EGSUnitLocation({
    this.city,
    this.citySubdivision,
    this.street,
    this.plotIdentification,
    this.building,
    this.postalZone,
  });

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'city_subdivision': citySubdivision,
      'street': street,
      'plot_identification': plotIdentification,
      'building': building,
      'postal_zone': postalZone,
    };
  }
}

class EGSUnitCustomerInfo {
  String? city;
  String? citySubdivision;
  String? street;
  String? additionalStreet;
  String? plotIdentification;
  String? building;
  String? postalZone;
  String? countrySubEntity;
  String buyerName;
  String? customerCrnNumber;
  String? vatNumber;

  EGSUnitCustomerInfo({
    this.city,
    this.citySubdivision,
    this.street,
    this.additionalStreet,
    this.plotIdentification,
    this.building,
    this.postalZone,
    this.countrySubEntity,
    required this.buyerName,
    this.customerCrnNumber,
    this.vatNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'city_subdivision': citySubdivision,
      'street': street,
      'additional_street': additionalStreet,
      'plot_identification': plotIdentification,
      'building': building,
      'postal_zone': postalZone,
      'country_sub_entity': countrySubEntity,
      'buyer_name': buyerName,
      'CRN_number': customerCrnNumber,
      'vat_number': vatNumber,
    };
  }

}

class EGSUnitInfo {
  String uuid;
  String customId;
  String model;
  String crnNumber;
  String vatName;
  String vatNumber;
  String branchName;
  String branchIndustry;
  EGSUnitLocation? location;
  EGSUnitCustomerInfo? customerInfo;
  String? privateKey;
  String? complianceCertificate;
  String? complianceApiSecret;
  String? productionCertificate;
  String? productionApiSecret;

  EGSUnitInfo({
    required this.uuid,
    required this.customId,
    required this.model,
    required this.crnNumber,
    required this.vatName,
    required this.vatNumber,
    required this.branchName,
    required this.branchIndustry,
    this.location,
    this.customerInfo,
    this.privateKey,
    this.complianceCertificate,
    this.complianceApiSecret,
    this.productionCertificate,
    this.productionApiSecret,
  });

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'custom_id': customId,
      'model': model,
      'CRN_number': crnNumber,
      'VAT_name': vatName,
      'VAT_number': vatNumber,
      'branch_name': branchName,
      'branch_industry': branchIndustry,
      'location': location?.toJson(),
      'customer_info': customerInfo?.toJson(),
      'private_key': privateKey,
      'compliance_certificate': complianceCertificate,
      'compliance_api_secret': complianceApiSecret,
      'production_certificate': productionCertificate,
      'production_api_secret': productionApiSecret,
    };
  }
}
class EGS {
  EGSUnitInfo egsUnitInfo;

  EGS({
    required this.egsUnitInfo,
  });

  Map<String,dynamic> signInvoice({required ZATCAInvoice invoice,  bool production=false}) {
    var certificate =egsUnitInfo.complianceCertificate;
    return invoice.sign(certificate!, egsUnitInfo.privateKey!);
  }

}