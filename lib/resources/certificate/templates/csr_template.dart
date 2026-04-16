import 'package:zatca/resources/enums.dart';

const String template = '''
# ------------------------------------------------------------------
# Default section for "req" command options
# ------------------------------------------------------------------
[req]

# Password for reading in existing private key file
# input_password = SET_PRIVATE_KEY_PASS

# Prompt for DN field values and CSR attributes in ASCII
prompt = no
utf8 = no

# Section pointer for DN field options
distinguished_name = my_req_dn_prompt

# Extensions
req_extensions = v3_req

[ v3_req ]
#basicConstraints=CA:FALSE
#keyUsage = digitalSignature, keyEncipherment
# Production or Testing Template (TSTZATCA-Code-Signing - PREZATCA-Code-Signing - ZATCA-Code-Signing)
1.3.6.1.4.1.311.20.2 = ASN1:UTF8String:SET_ENVIRONMENT_VALUE
subjectAltName=dirName:dir_sect

[ dir_sect ]
# EGS Serial number (1-SolutionName|2-ModelOrVersion|3-serialNumber)
SN = SET_EGS_SERIAL_NUMBER
# VAT Registration number of TaxPayer (Organization identifier [15 digits begins with 3 and ends with 3])
UID = SET_VAT_REGISTRATION_NUMBER
# Invoice type (TSCZ)(1 = supported, 0 not supported) (Tax, Simplified, future use, future use)
title = 1100
# Location (branch address or website)
registeredAddress = SET_BRANCH_LOCATION
# Industry (industry sector name)
businessCategory = SET_BRANCH_INDUSTRY

# ------------------------------------------------------------------
# Section for prompting DN field values to create "subject"
# ------------------------------------------------------------------
[my_req_dn_prompt]
# Common name (EGS TaxPayer PROVIDED ID [FREE TEXT])
commonName = SET_COMMON_NAME

# Organization Unit (Branch name)
organizationalUnitName = SET_BRANCH_NAME

# Organization name (Tax payer name)
organizationName = SET_TAXPAYER_NAME

# ISO2 country code is required with US as default
countryName = SA
''';

class CSRConfigProps {
  final String? privateKeyPass;
  final ZatcaEnvironment environment;
  final String egsModel;
  final String egsSerialNumber;
  final String solutionName;
  final String vatNumber;
  final String branchLocation;
  final String branchIndustry;
  final String branchName;
  final String taxpayerName;
  final String taxpayerProvidedId;

  CSRConfigProps({
    this.privateKeyPass,
    this.environment = ZatcaEnvironment.sandbox,
    required this.egsModel,
    required this.egsSerialNumber,
    required this.solutionName,
    required this.vatNumber,
    required this.branchLocation,
    required this.branchIndustry,
    required this.branchName,
    required this.taxpayerName,
    required this.taxpayerProvidedId,
  });

  String _getAsnTemplate() {
    switch (environment) {
      case ZatcaEnvironment.sandbox:
        return 'TSTZATCA-Code-Signing';
      case ZatcaEnvironment.simulation:
        return 'PREZATCA-Code-Signing';
      case ZatcaEnvironment.production:
        return 'ZATCA-Code-Signing';
    }
  }

  String toTemplate() {
    String populatedTemplate = template;
    populatedTemplate = populatedTemplate.replaceAll(
      "SET_PRIVATE_KEY_PASS",
      privateKeyPass ?? "SET_PRIVATE_KEY_PASS",
    );
    populatedTemplate = populatedTemplate.replaceAll(
      "SET_ENVIRONMENT_VALUE",
      _getAsnTemplate(),
    );
    populatedTemplate = populatedTemplate.replaceAll(
      "SET_EGS_SERIAL_NUMBER",
      "1-$solutionName|2-$egsModel|3-$egsSerialNumber",
    );
    populatedTemplate = populatedTemplate.replaceAll(
      "SET_VAT_REGISTRATION_NUMBER",
      vatNumber,
    );
    populatedTemplate = populatedTemplate.replaceAll(
      "SET_BRANCH_LOCATION",
      branchLocation,
    );
    populatedTemplate = populatedTemplate.replaceAll(
      "SET_BRANCH_INDUSTRY",
      branchIndustry,
    );
    populatedTemplate = populatedTemplate.replaceAll(
      "SET_COMMON_NAME",
      taxpayerProvidedId,
    );
    populatedTemplate = populatedTemplate.replaceAll(
      "SET_BRANCH_NAME",
      branchName,
    );
    populatedTemplate = populatedTemplate.replaceAll(
      "SET_TAXPAYER_NAME",
      taxpayerName,
    );

    return populatedTemplate;
  }
}
