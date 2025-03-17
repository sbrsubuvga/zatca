import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:xml/xml.dart';
import 'package:intl/intl.dart';
import 'package:xml/xpath.dart';
import '../siging/signing.dart';


class QRParams {
  final XmlDocument invoice_xml;
  final String digital_signature;
  final Uint8List public_key;
  final Uint8List certificate_signature;

  QRParams({
    required this.invoice_xml,
    required this.digital_signature,
    required this.public_key,
    required this.certificate_signature,
  });
}

/// Generates QR for a given invoice. According to ZATCA BR-KSA-27
/// @param invoice_xml XMLDocument.
/// @param digital_signature String base64 encoded digital signature.
/// @param public_key Uint8List certificate public key.
/// @param certificate_signature Uint8List certificate signature.
/// @returns String base64 encoded QR data.
String generateQR(QRParams params) {
// Hash
  final invoice_hash = getInvoiceHash(params.invoice_xml);
  print('invoice_hash_qr: $invoice_hash');
// Extract required tags
  final seller_name = params.invoice_xml
      .xpath(
      'Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName')
      .firstOrNull
      ?.innerText;
  final VAT_number = params.invoice_xml
      .xpath(
      'Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID')
      .firstOrNull
      ?.innerText;
  var invoice_total = params.invoice_xml
      .xpath('Invoice/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount')
      .firstOrNull?.innerText;

  var VAT_total = params.invoice_xml
      .xpath('Invoice/cac:TaxTotal')
      .firstOrNull?.xpath('cbc:TaxAmount')?.firstOrNull?.innerText;

  final issue_date =
      params.invoice_xml.xpath('Invoice/cbc:IssueDate').firstOrNull?.innerText;
  final issue_time =
      params.invoice_xml.xpath('Invoice/cbc:IssueTime').firstOrNull?.innerText;
// Detect if simplified invoice or not (not used currently assuming all simplified tax invoice)
  final invoice_type = params.invoice_xml
      .xpath('Invoice/cbc:InvoiceTypeCode')
      .firstOrNull
      ?.innerText.toString();
  final datetime = '$issue_date $issue_time';
  final formatted_datetime = DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.parse(datetime)) + 'Z';
  final qr_tlv = TLV([
    seller_name,
    VAT_number,
    formatted_datetime,
    invoice_total,
    VAT_total,
    invoice_hash,
    Uint8List.fromList(params.digital_signature.codeUnits),
    params.public_key,
    params.certificate_signature,
  ]);
  return base64Encode(qr_tlv);
}

/// Generates a QR for phase one given an invoice.
/// This is a temporary function for backwards compatibility while phase two is not fully deployed.
/// @param invoice_xml XMLDocument.
/// @returns String base64 encoded QR data.
String generatePhaseOneQR({ required XmlDocument invoice_xml}) {
// Extract required tags
  final seller_name = invoice_xml
      .findAllElements(
      'Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:RegistrationName')
      .first
      .text;
  final VAT_number = invoice_xml
      .findAllElements(
      'Invoice/cac:AccountingSupplierParty/cac:Party/cac:PartyTaxScheme/cbc:CompanyID')
      .first
      .text;
  final invoice_total = invoice_xml
      .findAllElements('Invoice/cac:LegalMonetaryTotal/cbc:TaxInclusiveAmount')
      .first
      .text;
  final VAT_total = invoice_xml
      .findAllElements('Invoice/cac:TaxTotal')
      .first
      .findElements('cbc:TaxAmount')
      .first
      .text;
  final issue_date =
      invoice_xml.findAllElements('Invoice/cbc:IssueDate').first.text;
  final issue_time =
      invoice_xml.findAllElements('Invoice/cbc:IssueTime').first.text;
  final datetime = '$issue_date $issue_time';
  final formatted_datetime =
      DateFormat('yyyy-MM-ddTHH:mm:ss').format(DateTime.parse(datetime)) + 'Z';
  final qr_tlv = TLV([
    seller_name,
    VAT_number,
    formatted_datetime,
    invoice_total,
    VAT_total,
  ]);
  return base64.encode(qr_tlv);
}

Uint8List TLV(List<dynamic> tags) {
  List<int> tlvBytes = [];

  for (int i = 0; i < tags.length; i++) {
    List<int> tagValue;

    if (tags[i] is String) {
      tagValue = utf8.encode(tags[i]); // Convert string to bytes
    } else if (tags[i] is Uint8List) {
      tagValue = tags[i]; // Use Uint8List directly
    } else {
      tagValue = utf8.encode(tags[i].toString());
    }

    tlvBytes.add(i + 1); // Tag index (1-based)
    tlvBytes.add(tagValue.length); // Length of value
    tlvBytes.addAll(tagValue); // Value itself
  }

  return Uint8List.fromList(tlvBytes);
}