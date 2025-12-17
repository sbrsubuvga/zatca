import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../enums.dart';

class API {
  /// The environment for the API (sandbox(development), simulation, or production).
  final ZatcaEnvironment env;

  API(this.env);

  /// The base URL for the API endpoints.
  static const settings = {
    "API_VERSION": "V2",
    "SANDBOX_BASEURL":
        "https://gw-fatoora.zatca.gov.sa/e-invoicing/developer-portal",
    "SIMULATION_BASEURL":
        "https://gw-fatoora.zatca.gov.sa/e-invoicing/simulation",
    "PRODUCTION_BASEURL": "https://gw-fatoora.zatca.gov.sa/e-invoicing/core",
  };

  /// The base URL for the API endpoints based on the environment.
  String getBaseUrl() {
    if (env.value == "production") {
      return settings["PRODUCTION_BASEURL"]!;
    } else if (env.value == "simulation") {
      return settings["SIMULATION_BASEURL"]!;
    } else {
      return settings["SANDBOX_BASEURL"]!;
    }
  }

  /// Generates the authentication headers for the API requests.
  Map<String, String> getAuthHeaders(String? certificate, String? secret) {
    if (certificate != null && secret != null) {
      final basic = base64Encode(
        utf8.encode('${base64Encode(utf8.encode(certificate))}:$secret'),
      );
      return {"Authorization": "Basic $basic"};
    }
    return {};
  }

  /// Creates an instance of the ComplianceAPI class.
  ComplianceAPI compliance({String? certificate, String? secret}) {
    final authHeaders = getAuthHeaders(certificate, secret);
    final baseUrl = getBaseUrl();
    return ComplianceAPI(authHeaders, baseUrl);
  }

  /// Creates an instance of the ProductionAPI class.
  ProductionAPI production(String? certificate, String? secret) {
    final authHeaders = getAuthHeaders(certificate, secret);
    final baseUrl = getBaseUrl();
    return ProductionAPI(authHeaders, baseUrl);
  }
}

class ComplianceAPI {
  /// The authentication headers for the API requests.
  final Map<String, String> authHeaders;

  /// The base URL for the API endpoints.
  final String baseUrl;

  ComplianceAPI(this.authHeaders, this.baseUrl);

  /// Issues a compliance certificate using the provided CSR and OTP.
  Future<Map<String, dynamic>> issueCertificate(String csr, String otp) async {
    final headers = {
      "Accept-Version": API.settings["API_VERSION"]!,
      "OTP": otp,
      'Content-Type': 'application/json',
      ...authHeaders,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/compliance'),
        headers: headers,
        body: jsonEncode({"csr": base64Encode(utf8.encode(csr))}),
      );

      if (response.statusCode != 200) {
        debugPrint("Error: ${response.statusCode}, Body: ${response.body}");
        throw Exception("Error issuing a compliance certificate.");
      }

      final data = jsonDecode(response.body);
      final issuedCertificate = '''
-----BEGIN CERTIFICATE-----
${utf8.decode(base64Decode(data["binarySecurityToken"]))}
-----END CERTIFICATE-----
''';
      return {
        "issued_certificate": issuedCertificate,
        "api_secret": data["secret"],
        "request_id": data["requestID"],
      };
    } catch (e) {
      debugPrint("An error occurred: $e");
      rethrow;
    }
  }

  /// Reports an invoice using the provided signed XML string, invoice hash, and EGS UUID.
  Future<dynamic> checkInvoiceCompliance({
    required String signedXmlString,
    required String invoiceHash,
    required String egsUuid,
  }) async {
    final headers = {
      "Accept-Version": API.settings["API_VERSION"]!,
      "Accept-Language": "en",
      'Content-Type': 'application/json',
      ...authHeaders,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/compliance/invoices'),
      headers: headers,
      body: jsonEncode({
        "invoiceHash": invoiceHash,
        "uuid": egsUuid,
        "invoice": base64Encode(utf8.encode(signedXmlString)),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 202) {
      debugPrint("Response: ${response.statusCode}, Body: ${response.body}");
      throw Exception("Error in compliance check.");
    }

    return jsonDecode(response.body);
  }
}

class ProductionAPI {
  /// The authentication headers for the API requests.
  final Map<String, String> authHeaders;

  /// The base URL for the API endpoints.
  final String baseUrl;

  ProductionAPI(this.authHeaders, this.baseUrl);

  /// Issues a production certificate using the provided compliance request ID.
  Future<Map<String, dynamic>> issueCertificate(
    String complianceRequestId,
  ) async {
    final headers = {
      "Accept-Version": API.settings["API_VERSION"]!,
      'Content-Type': 'application/json',
      ...authHeaders,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/production/csids'),
      headers: headers,
      body: jsonEncode({"compliance_request_id": complianceRequestId}),
    );

    if (response.statusCode != 200) {
      throw Exception("Error issuing a production certificate.");
    }

    final data = jsonDecode(response.body);
    final issuedCertificate = '''
-----BEGIN CERTIFICATE-----
${utf8.decode(base64Decode(data["binarySecurityToken"]))}
-----END CERTIFICATE-----
''';
    return {
      "issued_certificate": issuedCertificate,
      "api_secret": data["secret"],
      "request_id": data["requestID"],
    };
  }

  /// Reports an invoice using the provided signed XML string, invoice hash, and EGS UUID.
  Future<dynamic> reportInvoice(
    String signedXmlString,
    String invoiceHash,
    String egsUuid,
  ) async {
    final headers = {
      "Accept-Version": API.settings["API_VERSION"]!,
      "Accept-Language": "en",
      "Clearance-Status": "0",
      ...authHeaders,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/invoices/reporting/single'),
      headers: headers,
      body: jsonEncode({
        "invoiceHash": invoiceHash,
        "uuid": egsUuid,
        "invoice": base64Encode(utf8.encode(signedXmlString)),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception("Error in reporting invoice.");
    }

    return jsonDecode(response.body);
  }

  /// Reports an invoice using the provided signed XML string, invoice hash, and EGS UUID.
  Future<dynamic> clearanceInvoice(
    String signedXmlString,
    String invoiceHash,
    String egsUuid,
  ) async {
    final headers = {
      "Accept-Version": API.settings["API_VERSION"]!,
      "Accept-Language": "en",
      "Clearance-Status": "1",
      ...authHeaders,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/invoices/clearance/single'),
      headers: headers,
      body: jsonEncode({
        "invoiceHash": invoiceHash,
        "uuid": egsUuid,
        "invoice": base64Encode(utf8.encode(signedXmlString)),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception("Error in clearance invoice.");
    }

    return jsonDecode(response.body);
  }
}
