import 'dart:convert';
import 'package:flutter_zatca/calc.dart';
import 'package:flutter_zatca/siging/signing.dart';
import 'package:flutter_zatca/templates/simplified_tax_invoices.dart';
import 'package:xml/xml.dart' as xml;

class ZATCAInvoice {
  late xml.XmlDocument invoiceXml;

  ZATCAInvoice({
    String? invoiceXmlStr,
    ZATCAInvoiceProps? props,
    bool acceptWarning = false,
  }) {
    if (invoiceXmlStr != null) {
      invoiceXml = xml.XmlDocument.parse(invoiceXmlStr);
      if (invoiceXml.children.isEmpty) throw Error(); // Handle error if the parsing fails
    } else {
      if (props == null) throw Exception('Unable to create new XML invoice.');
      invoiceXml = xml.XmlDocument.parse(populate(props));

      // Parsing line items
      parseLineItems(props.line_items , props, acceptWarning);
    }
  }

  void parseLineItems(
      List<ZATCAInvoiceLineItem> lineItems,
      ZATCAInvoiceProps props,
      bool acceptWarning,
      ) {
    calc(lineItems, props, invoiceXml, acceptWarning);
  }

  xml.XmlDocument getXml() {
    return invoiceXml;
  }

  Map<String,dynamic> sign(String certificateString, String privateKeyString) {
    return generateSignedXMLString( invoiceXml, certificateString, privateKeyString);
  }
}

