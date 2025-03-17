import 'package:mustache_template/mustache_template.dart';
import 'package:xml/xml.dart';

import '../egs.dart';



const template = '''
<?xml version="1.0" encoding="UTF-8"?>
<Invoice xmlns="urn:oasis:names:specification:ubl:schema:xsd:Invoice-2" xmlns:cac="urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2" xmlns:cbc="urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2" xmlns:ext="urn:oasis:names:specification:ubl:schema:xsd:CommonExtensionComponents-2"><ext:UBLExtensions>SET_UBL_EXTENSIONS_STRING</ext:UBLExtensions>

<cbc:ProfileID>reporting:1.0</cbc:ProfileID>
<cbc:ID>{{{invoice_serial_number}}}</cbc:ID>
<cbc:UUID>{{{egs_info.uuid}}}</cbc:UUID>
<cbc:IssueDate>{{{issue_date}}}</cbc:IssueDate>
<cbc:IssueTime>{{{issue_time}}}</cbc:IssueTime>
<cbc:InvoiceTypeCode name="{{{invoice_code}}}">{{{invoice_type}}}</cbc:InvoiceTypeCode>
<cbc:DocumentCurrencyCode>SAR</cbc:DocumentCurrencyCode>
<cbc:TaxCurrencyCode>SAR</cbc:TaxCurrencyCode>
<cac:AdditionalDocumentReference>
<cbc:ID>ICV</cbc:ID>
<cbc:UUID>{{{invoice_counter_number}}}</cbc:UUID>
</cac:AdditionalDocumentReference>
<cac:AdditionalDocumentReference>
<cbc:ID>PIH</cbc:ID>
<cac:Attachment>
<cbc:EmbeddedDocumentBinaryObject mimeCode="text/plain">{{{previous_invoice_hash}}}</cbc:EmbeddedDocumentBinaryObject>
</cac:Attachment>
</cac:AdditionalDocumentReference>
<cac:AdditionalDocumentReference>
<cbc:ID>QR</cbc:ID>
<cac:Attachment>
<cbc:EmbeddedDocumentBinaryObject mimeCode="text/plain">SET_QR_CODE_DATA</cbc:EmbeddedDocumentBinaryObject>
</cac:Attachment>
</cac:AdditionalDocumentReference>
<cac:Signature>
<cbc:ID>urn:oasis:names:specification:ubl:signature:Invoice</cbc:ID>
<cbc:SignatureMethod>urn:oasis:names:specification:ubl:dsig:enveloped:xades</cbc:SignatureMethod>
</cac:Signature>
<cac:AccountingSupplierParty>
<cac:Party>
<cac:PartyIdentification>
<cbc:ID schemeID="CRN">{{{egs_info.CRN_number}}}</cbc:ID>
</cac:PartyIdentification>
<cac:PostalAddress>
{{#egs_info.location.street}}
<cbc:StreetName>{{{egs_info.location.street}}}</cbc:StreetName>
{{/egs_info.location.street}}
{{#egs_info.location.building}}
<cbc:BuildingNumber>{{{egs_info.location.building}}}</cbc:BuildingNumber>
{{/egs_info.location.building}}
{{#egs_info.location.plot_identification}}
<cbc:PlotIdentification>{{{egs_info.location.plot_identification}}}</cbc:PlotIdentification>
{{/egs_info.location.plot_identification}}
{{#egs_info.location.city_subdivision}}
<cbc:CitySubdivisionName>{{{egs_info.location.city_subdivision}}}</cbc:CitySubdivisionName>
{{/egs_info.location.city_subdivision}}
{{#egs_info.location.city}}
<cbc:CityName>{{{egs_info.location.city}}}</cbc:CityName>
{{/egs_info.location.city}}
{{#egs_info.location.postal_zone}}
<cbc:PostalZone>{{{egs_info.location.postal_zone}}}</cbc:PostalZone>
{{/egs_info.location.postal_zone}}
<cac:Country>
<cbc:IdentificationCode>SA</cbc:IdentificationCode>
</cac:Country>
</cac:PostalAddress>
<cac:PartyTaxScheme>
<cbc:CompanyID>{{{egs_info.VAT_number}}}</cbc:CompanyID>
<cac:TaxScheme>
<cbc:ID>VAT</cbc:ID>
</cac:TaxScheme>
</cac:PartyTaxScheme>
<cac:PartyLegalEntity>
<cbc:RegistrationName>{{{egs_info.VAT_name}}}</cbc:RegistrationName>
</cac:PartyLegalEntity>
</cac:Party>
</cac:AccountingSupplierParty>
<cac:AccountingCustomerParty>
{{#egs_info.customer_info}}
<cac:Party>
<cac:PartyIdentification>
<cbc:ID schemeID="CRN">{{{egs_info.customer_info.CRN_number}}}</cbc:ID>
</cac:PartyIdentification>
<cac:PostalAddress>
{{#egs_info.customer_info.street}}
<cbc:StreetName>{{{egs_info.customer_info.street}}}</cbc:StreetName>
{{/egs_info.customer_info.street}}
{{#egs_info.customer_info.additional_street}}
<cbc:AdditionalStreetName>{{{egs_info.customer_info.additional_street}}}</cbc:AdditionalStreetName>
{{/egs_info.customer_info.additional_street}}
{{#egs_info.customer_info.building}}
<cbc:BuildingNumber>{{{egs_info.customer_info.building}}}</cbc:BuildingNumber>
{{/egs_info.customer_info.building}}
{{#egs_info.customer_info.plot_identification}}
<cbc:PlotIdentification>{{{egs_info.customer_info.plot_identification}}}</cbc:PlotIdentification>
{{/egs_info.customer_info.plot_identification}}
{{#egs_info.customer_info.city_subdivision}}
<cbc:CitySubdivisionName>{{{egs_info.customer_info.city_subdivision}}}</cbc:CitySubdivisionName>
{{/egs_info.customer_info.city_subdivision}}
{{#egs_info.customer_info.city}}
<cbc:CityName>{{{egs_info.customer_info.city}}}</cbc:CityName>
{{/egs_info.customer_info.city}}
{{#egs_info.customer_info.postal_zone}}
<cbc:PostalZone>{{{egs_info.customer_info.postal_zone}}}</cbc:PostalZone>
{{/egs_info.customer_info.postal_zone}}
{{#egs_info.customer_info.country_sub_entity}}
<cbc:CountrySubentity>{{{egs_info.customer_info.country_sub_entity}}}</cbc:CountrySubentity>
{{/egs_info.customer_info.country_sub_entity}}
<cac:Country>
<cbc:IdentificationCode>SA</cbc:IdentificationCode>
</cac:Country>
</cac:PostalAddress>
{{#egs_info.customer_info.vat_number}}
<cac:PartyTaxScheme>
<cbc:CompanyID>{{{egs_info.customer_info.vat_number}}}</cbc:CompanyID>
<cac:TaxScheme>
<cbc:ID>VAT</cbc:ID>
</cac:TaxScheme>
</cac:PartyTaxScheme>
{{/egs_info.customer_info.vat_number}}
<cac:PartyLegalEntity>
<cbc:RegistrationName>{{{egs_info.customer_info.buyer_name}}}</cbc:RegistrationName>
</cac:PartyLegalEntity>
</cac:Party>
{{/egs_info.customer_info}}
</cac:AccountingCustomerParty>
{{#actual_delivery_date}}
<cac:Delivery>
<cbc:ActualDeliveryDate>{{{actual_delivery_date}}}</cbc:ActualDeliveryDate>
{{#latest_delivery_date}}
<cbc:LatestDeliveryDate>{{{latest_delivery_date}}}</cbc:LatestDeliveryDate>
{{/latest_delivery_date}}
</cac:Delivery>
{{/actual_delivery_date}}
</Invoice>''';

enum ZATCAPaymentMethods {
  CASH('10'),
  CREDIT('30'),
  BANK_ACCOUNT('42'),
  BANK_CARD('48');

  final String code;
  const ZATCAPaymentMethods(this.code);
}

enum ZATCAInvoiceTypes {
  INVOICE('388'),
  DEBIT_NOTE('383'),
  CREDIT_NOTE('381');

  final String code;
  const ZATCAInvoiceTypes(this.code);
}
class ZATCAInvoiceLineItemDiscount {
  final double amount;
  final String reason;

  ZATCAInvoiceLineItemDiscount({
    required this.amount,
    required this.reason,
  });
}

class ZATCAInvoiceLineItemTax {
  final double percent_amount;

  ZATCAInvoiceLineItemTax({
    required this.percent_amount,
  });
}

class InvoiceLineItem {
  final String id;
  final String name;
  final int quantity;
   double tax_exclusive_price;
  final List<ZATCAInvoiceLineItemTax>? other_taxes;
  final List<ZATCAInvoiceLineItemDiscount>? discounts;

  InvoiceLineItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.tax_exclusive_price,
    this.other_taxes,
    this.discounts,
  });
}

class VATCategory {
  final String code;
  final String? reason_code;
  final String? reason;

  VATCategory({
    required this.code,
    this.reason_code,
    this.reason,
  });
}

class ZATCAInvoiceLineItem extends InvoiceLineItem {
  final double VAT_percent;
  final VATCategory? vat_category;

  ZATCAInvoiceLineItem({
    required String id,
    required String name,
    required int quantity,
    required double tax_exclusive_price,
    List<ZATCAInvoiceLineItemTax>? other_taxes,
    List<ZATCAInvoiceLineItemDiscount>? discounts,
    this.VAT_percent=0,
    this.vat_category,
  }) : super(
    id: id,
    name: name,
    quantity: quantity,
    tax_exclusive_price: tax_exclusive_price,
    other_taxes: other_taxes,
    discounts: discounts,
  );
}


class ZATCAInvoiceCancelation {
  final String canceled_serial_invoice_number;
  final ZATCAPaymentMethods payment_method;
  final String reason;

  ZATCAInvoiceCancelation({
    required this.canceled_serial_invoice_number,
    required this.payment_method,
    required this.reason,
  });
}

class ZatcaInvoice {
  final EGSUnitInfo egs_info;
  final int invoice_counter_number;
  final String invoice_serial_number;
  final String issue_date;
  final String issue_time;
  final String previous_invoice_hash;
  final List<ZATCAInvoiceLineItem> line_items;

  ZatcaInvoice({
    required this.egs_info,
    required this.invoice_counter_number,
    required this.invoice_serial_number,
    required this.issue_date,
    required this.issue_time,
    required this.previous_invoice_hash,
    required this.line_items,
  });


  Map<String, dynamic> toJson() {
    return {
      'egs_info': egs_info.toJson(),
      'invoice_counter_number': invoice_counter_number,
      'invoice_serial_number': invoice_serial_number,
      'issue_date': issue_date,
      'issue_time': issue_time,
      'previous_invoice_hash': previous_invoice_hash,
    };
  }
}

class CreditDebitInvoice extends ZatcaInvoice {
  final ZATCAInvoiceTypes invoice_type;
  final ZATCAInvoiceCancelation cancelation;

  CreditDebitInvoice({
    required EGSUnitInfo egs_info,
    required int invoice_counter_number,
    required String invoice_serial_number,
    required String issue_date,
    required String issue_time,
    required String previous_invoice_hash,
    required List<ZATCAInvoiceLineItem> line_items,
    required this.invoice_type,
    required this.cancelation,
  }) : super(
    egs_info: egs_info,
    invoice_counter_number: invoice_counter_number,
    invoice_serial_number: invoice_serial_number,
    issue_date: issue_date,
    issue_time: issue_time,
    previous_invoice_hash: previous_invoice_hash,
    line_items: line_items,
  );


  @override
  Map<String, dynamic> toJson() {
    final jsonMap = super.toJson();
    jsonMap['invoice_type'] = invoice_type;
    jsonMap['cancelation'] = cancelation;
    return jsonMap;
  }
}

class CashInvoice extends ZatcaInvoice {
  final ZATCAInvoiceTypes invoice_type;
  final String? actual_delivery_date;
  final String? latest_delivery_date;
  final ZATCAPaymentMethods? payment_method;

  CashInvoice({
    required EGSUnitInfo egs_info,
    required int invoice_counter_number,
    required String invoice_serial_number,
    required String issue_date,
    required String issue_time,
    required String previous_invoice_hash,
    required List<ZATCAInvoiceLineItem> line_items,
    required this.invoice_type,
    this.actual_delivery_date,
    this.latest_delivery_date,
    this.payment_method,
  }) : super(
    egs_info: egs_info,
    invoice_counter_number: invoice_counter_number,
    invoice_serial_number: invoice_serial_number,
    issue_date: issue_date,
    issue_time: issue_time,
    previous_invoice_hash: previous_invoice_hash,
    line_items: line_items,
  );

  @override
  Map<String, dynamic> toJson() {
    final jsonMap = super.toJson();
    jsonMap['invoice_type'] = invoice_type.code;
    jsonMap['actual_delivery_date'] = actual_delivery_date;
    jsonMap['latest_delivery_date'] = latest_delivery_date;
    jsonMap['payment_method'] = payment_method?.code.toString();
    return jsonMap;
  }
}

class TaxInvoice extends CashInvoice {
  final String invoice_code = "0100000";

  TaxInvoice({
    required EGSUnitInfo egs_info,
    required int invoice_counter_number,
    required String invoice_serial_number,
    required String issue_date,
    required String issue_time,
    required String previous_invoice_hash,
    required List<ZATCAInvoiceLineItem> line_items,
    required ZATCAInvoiceTypes invoice_type,
    String? actual_delivery_date,
    String? latest_delivery_date,
    ZATCAPaymentMethods? payment_method,
  }) : super(
    egs_info: egs_info,
    invoice_counter_number: invoice_counter_number,
    invoice_serial_number: invoice_serial_number,
    issue_date: issue_date,
    issue_time: issue_time,
    previous_invoice_hash: previous_invoice_hash,
    line_items: line_items,
    invoice_type: invoice_type,
    actual_delivery_date: actual_delivery_date,
    latest_delivery_date: latest_delivery_date,
    payment_method: payment_method,
  );

  @override
  Map<String, dynamic> toJson() {
    final jsonMap = super.toJson();
    jsonMap['invoice_code'] = invoice_code;
    return jsonMap;
  }
}

class SimplifiedInvoice extends CashInvoice {
  final String invoice_code = "0200000";

  SimplifiedInvoice({
    required EGSUnitInfo egs_info,
    required int invoice_counter_number,
    required String invoice_serial_number,
    required String issue_date,
    required String issue_time,
    required String previous_invoice_hash,
    required List<ZATCAInvoiceLineItem> line_items,
    required ZATCAInvoiceTypes invoice_type,
    String? actual_delivery_date,
    String? latest_delivery_date,
    ZATCAPaymentMethods? payment_method,
  }) : super(
    egs_info: egs_info,
    invoice_counter_number: invoice_counter_number,
    invoice_serial_number: invoice_serial_number,
    issue_date: issue_date,
    issue_time: issue_time,
    previous_invoice_hash: previous_invoice_hash,
    line_items: line_items,
    invoice_type: invoice_type,
    actual_delivery_date: actual_delivery_date,
    latest_delivery_date: latest_delivery_date,
    payment_method: payment_method,
  );

  @override
  Map<String, dynamic> toJson() {
    final jsonMap = super.toJson();
    jsonMap['invoice_code'] = invoice_code;
    return jsonMap;
  }
}

typedef ZATCAInvoiceProps = SimplifiedInvoice;


 String rendering(ZATCAInvoiceProps props) {
  var tTemplate =  Template(template);
  var output = tTemplate.renderString(props.toJson());
  return output;
}

String populate(ZATCAInvoiceProps props) {
  String populatedTemplate = rendering(props);
  return populatedTemplate;
}
