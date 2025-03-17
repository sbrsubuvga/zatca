import 'dart:convert';
import 'package:flutter_zatca/siging/signing.dart';
import 'package:http/http.dart' as http;

class ComplianceAPI {
  static String apiVersion='V2';
   static String sandboxBaseUrl='https://gw-fatoora.zatca.gov.sa/e-invoicing/developer-portal';


  Map<String, String> getAuthHeaders(String? certificate, String? secret) {
    if (certificate!=null && secret!=null) {

      final certificate_stripped = cleanUpCertificateString(certificate);
      final certificateStrippedBase64 = base64Encode(utf8.encode(certificate_stripped));
      final basic = base64Encode(utf8.encode('$certificateStrippedBase64:$secret'));
      return {
        "Authorization": "Basic $basic"
      };
    }
    return {};
  }


  Future<dynamic> checkInvoiceCompliance(String signedXmlString, String invoiceHash, String egsUuid, String certificate, String secret) async {

    final authHeaders = getAuthHeaders(certificate, secret);
    final baseUrl = sandboxBaseUrl;
    final headers = {
      "Accept-Version": apiVersion,
      "Accept-Language": "en",
      ...authHeaders,
    };
    try {
      print("***************start3");
      final response = await http.post(
        Uri.parse('$baseUrl/compliance/invoices'),
        headers: headers,
        body: jsonEncode({
          'invoiceHash': invoiceHash,
          'uuid': egsUuid,
          'invoice': base64Encode(utf8.encode(signedXmlString)),
        }),
      );
      print("***************start4");
      if (response.statusCode != 200 && response.statusCode != 202) {

        print("*statusCode******${response.statusCode}");
        throw Exception("Error in compliance check.");
      }
      print("response********$response");
      return jsonDecode(response.body);
    }
    catch(e){
      print("*******$e");
    }
    finally{
      print("***************start5");
    }
  }

}