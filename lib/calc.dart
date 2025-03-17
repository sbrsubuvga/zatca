
import 'package:flutter_zatca/parse/xml_extionsion.dart';
import 'package:flutter_zatca/parse/xml_parse.dart';
import 'package:flutter_zatca/templates/simplified_tax_invoices.dart';
import 'package:xml/xml.dart';

class CACTaxableAmount {
  double taxAmount;
  double taxableAmount;
  bool exist;

  CACTaxableAmount({this.taxAmount = 0, this.taxableAmount = 0, this.exist = false});
}



String roundingNumber(bool acceptWarning, double number) {
  try {
    if (!acceptWarning) {
      return number.toStringAsFixed(2);
    } else {
      String formatted = number.toStringAsFixed(2);
      return formatted.contains('.') ? formatted.replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '') : formatted;
    }
  } catch (e) {
    throw e;
  }
}

Map<String, dynamic> constructLineItemTotals(
    ZATCAInvoiceLineItem lineItem, bool acceptWarning)
{
  double lineDiscounts = 0;
  List<Map<String, dynamic>> cacAllowanceCharges = [];
  List<Map<String, dynamic>> cacClassifiedTaxCategories = [];
  Map<String, dynamic> cacTaxTotal;

  Map<String, dynamic> VAT = {
    "cbc:ID": lineItem.VAT_percent != null
        ? "S"
        : lineItem?.vat_category?.code??'S',
    "cbc:Percent": lineItem.VAT_percent != null
        ? roundingNumber(acceptWarning, (lineItem.VAT_percent * 100))
        : 0.0,
    "cac:TaxScheme": {
      "cbc:ID": "VAT",
    },
  };
  cacClassifiedTaxCategories.add(VAT);

  lineItem.discounts?.forEach((discount) {
    lineDiscounts += discount.amount;
    cacAllowanceCharges.add({
      "cbc:ChargeIndicator": "false",
      "cbc:AllowanceChargeReason": discount.reason,
      "cbc:Amount": {
        "@currencyID": "SAR",
        "#text": double.parse(discount.amount.toString())
            .toStringAsFixed(14),
      },
      "cbc:BaseAmount": {
        "@currencyID": "SAR",
        "#text": lineItem.tax_exclusive_price.toString(),
      },
    });
  });

  lineDiscounts = double.parse(lineDiscounts.toString()).toDouble();
  double lineExtensionAmount = double.parse(
      roundingNumber(acceptWarning, lineItem.quantity *
          (lineItem.tax_exclusive_price - lineDiscounts))
          .toString()
  ).toDouble();
  double lineItemTotalTaxes = double.parse(
      roundingNumber(acceptWarning, lineExtensionAmount * lineItem.VAT_percent)
          .toString()
  ).toDouble();



  cacTaxTotal = {
    "cbc:TaxAmount": {
      "@currencyID": "SAR",
      "#text": double.parse(lineItemTotalTaxes.toString()).toStringAsFixed(2),
    },
    "cbc:RoundingAmount": {
      "@currencyID": "SAR",
      "#text": double.parse(
          (lineExtensionAmount + lineItemTotalTaxes).toString()
      ).toStringAsFixed(2),
    },
  };

  return {
    'cacAllowanceCharges': cacAllowanceCharges,
    'cacClassifiedTaxCategories': cacClassifiedTaxCategories,
    'cacTaxTotal': cacTaxTotal,
    'lineItemTotalTaxes': lineItemTotalTaxes,
    'lineDiscounts': lineDiscounts,
    'lineExtensionAmount': lineExtensionAmount,
  };
}

Map<String, dynamic> constructLineItem(
    ZATCAInvoiceLineItem lineItem, bool acceptWarning) {
  var lineItemTotals = constructLineItemTotals(lineItem, acceptWarning);

  return {
    'lineItemXml': {
      "cbc:ID": lineItem.id,
      "cbc:InvoicedQuantity": {
        "@unitCode": "PCE",
        "#text": lineItem.quantity.toString(),
      },
      "cbc:LineExtensionAmount": {
        "@currencyID": "SAR",
        "#text": double.parse(lineItemTotals['lineExtensionAmount'].toString()).toStringAsFixed(2),
      },
      "cac:TaxTotal": lineItemTotals['cacTaxTotal'],
      "cac:Item": {
        "cbc:Name": lineItem.name,
        "cac:ClassifiedTaxCategory": lineItemTotals['cacClassifiedTaxCategories'],
      },
      "cac:Price": {
        "cbc:PriceAmount": {
          "@currencyID": "SAR",
          "#text": double.parse(
              (lineItem.tax_exclusive_price - lineItemTotals['lineDiscounts'])
                  .toString())
              .toStringAsFixed(14),
        },
        "cac:AllowanceCharge": lineItemTotals['cacAllowanceCharges'],
      },
    },
    'lineItemTotals': {
      'taxesTotal': lineItemTotals['lineItemTotalTaxes'],
      'discountsTotal': lineItemTotals['lineDiscounts'],
      'extensionAmount': lineItemTotals['lineExtensionAmount'],
    },
  };
}

Map<String, dynamic> constructTaxTotal(
    List<ZATCAInvoiceLineItem> lineItems, bool acceptWarning)
{
  List<Map<String, dynamic>> cacTaxSubtotal = [];
  List<Map<String, dynamic>> zeroTaxSubtotal = [];

  var withoutTaxItems =
  lineItems.where((item) => item.VAT_percent == 0).toList();

  Map<String, dynamic> modifiedZeroTaxSubTotal(List<ZATCAInvoiceLineItem> items) {
    var zeroTaxObj = <String, Map<String, dynamic>>{};

    items.forEach((item) {
      if (item.VAT_percent != 0) return;
      double totalLineItemDiscount =
          item.discounts?.fold(0, (p, c) => p! + c.amount) ?? 0;

      double taxableAmount = double.parse(
          ((item.tax_exclusive_price - totalLineItemDiscount) * item.quantity)
              .toString())
          .toDouble();

      double taxAmount = double.parse(
        (item.VAT_percent * taxableAmount).toString(),
      ).toDouble();

      if(item.vat_category!=null) {
        var code = item.vat_category!.code;
        if (zeroTaxObj.containsKey(code)) {
          zeroTaxObj[code]!['totalTaxAmount'] += taxAmount;
          zeroTaxObj[code]!['totalTaxableAmount'] += taxableAmount;
        } else {
          zeroTaxObj[code] = {
            'totalTaxAmount': taxAmount,
            'totalTaxableAmount': taxableAmount,
            'reason': item.vat_category!.reason ?? '',
            'reasonCode': item.vat_category!.reason_code ?? '',
          };
        }
      }
    });

    return zeroTaxObj;
  }

  if (withoutTaxItems.isNotEmpty) {
    var zeroTaxTotals = modifiedZeroTaxSubTotal(withoutTaxItems);
    zeroTaxTotals.forEach((key, value) {
      zeroTaxSubtotal.add({
        "cbc:TaxableAmount": {
          "@currencyID": "SAR",
          "#text": roundingNumber(
              acceptWarning,
              value['totalTaxableAmount']
          ),
        },
        "cbc:TaxAmount": {
          "@currencyID": "SAR",
          "#text": double.parse(value['totalTaxAmount'].toString()).toString(),
        },
        "cac:TaxCategory": {
          "cbc:ID": {
            "@schemeAgencyID": 6,
            "@schemeID": "UN/ECE 5305",
            "#text": key,
          },
          "cbc:Percent": 0.0,
          "cbc:TaxExemptionReasonCode": value['reasonCode'],
          "cbc:TaxExemptionReason": value['reason'],
          "cac:TaxScheme": {
            "cbc:ID": {
              "@schemeAgencyID": "6",
              "@schemeID": "UN/ECE 5153",
              "#text": "VAT",
            },
          },
        },
      });
    });
  }


  final CACTaxableAmount fiveTaxSubTotal = CACTaxableAmount();
  final CACTaxableAmount fifteenTaxSubTotal = CACTaxableAmount();

  void addTaxSubtotal({
    required double taxableAmount,
    required double taxAmount,
    required double taxPercent,
  }) {
    if (taxPercent == 0) return;

    if (taxPercent == 0.05) {
      fiveTaxSubTotal.taxableAmount += taxableAmount;
      fiveTaxSubTotal.taxAmount += taxAmount;
      fiveTaxSubTotal.exist = true;
    } else if (taxPercent == 0.15) {
      fifteenTaxSubTotal.taxableAmount += taxableAmount;
      fifteenTaxSubTotal.taxAmount += taxAmount;
      fifteenTaxSubTotal.exist = true;
    }
  }


  // similar logic for other tax categories, like `fiveTaxSubTotal` and `fifteenTaxSubTotal`
  double taxesTotal = 0;

  lineItems.forEach((lineItem) {
    double totalLineItemDiscount =
        lineItem.discounts?.fold(0, (p, c) => p! + c.amount) ?? 0;

    totalLineItemDiscount = double.parse(totalLineItemDiscount.toString()).toDouble();
    double taxableAmount = double.parse(
        roundingNumber(
            acceptWarning,
            (lineItem.tax_exclusive_price - totalLineItemDiscount) *
                lineItem.quantity)
            .toString())
        .toDouble();

    double taxAmount = double.parse(
      roundingNumber(acceptWarning, lineItem.VAT_percent * taxableAmount)
          .toString(),
    ).toDouble();


    addTaxSubtotal(taxableAmount: taxableAmount, taxAmount: taxAmount, taxPercent: lineItem.VAT_percent);

    taxesTotal += taxAmount;

    lineItem.other_taxes?.map((tax) {
    taxAmount = tax.percent_amount * taxableAmount;
    addTaxSubtotal(taxableAmount: taxableAmount, taxAmount: taxAmount, taxPercent: tax.percent_amount);
    taxesTotal += taxAmount;
  });

  });

  if (fifteenTaxSubTotal.exist) {
    cacTaxSubtotal.add({
      "cbc:TaxableAmount": {
        "@currencyID": "SAR",
        "#text": roundingNumber(
            acceptWarning,
            fifteenTaxSubTotal.taxableAmount
        ),
      },
      "cbc:TaxAmount": {
        "@currencyID": "SAR",
        "#text": roundingNumber(acceptWarning, fifteenTaxSubTotal.taxAmount),
      },
      "cac:TaxCategory": {
        "cbc:ID": {
          "@schemeAgencyID": 6,
          "@schemeID": "UN/ECE 5305",
          "#text": "S",
        },
        "cbc:Percent": 15,
        "cac:TaxScheme": {
          "cbc:ID": {
            "@schemeAgencyID": "6",
            "@schemeID": "UN/ECE 5153",
            "#text": "VAT",
          },
        },
      },
    });
  }
  if (fiveTaxSubTotal.exist) {
    cacTaxSubtotal.add({
      "cbc:TaxableAmount": {
        "@currencyID": "SAR",
        "#text": roundingNumber(acceptWarning, fiveTaxSubTotal.taxableAmount),
      },
      "cbc:TaxAmount": {
        "@currencyID": "SAR",
        "#text": fiveTaxSubTotal.taxAmount.toStringAsFixed(2),
      },
      "cac:TaxCategory": {
        "cbc:ID": {
          "@schemeAgencyID": 6,
          "@schemeID": "UN/ECE 5305",
          "#text": "S",
        },
        "cbc:Percent": 5,
        "cac:TaxScheme": {
          "cbc:ID": {
            "@schemeAgencyID": "6",
            "@schemeID": "UN/ECE 5153",
            "#text": "VAT",
          },
        },
      },
    });
  }

  return {
    'cacTaxTotal': [
      {
        "cbc:TaxAmount": {
          "@currencyID": "SAR",
          "#text": taxesTotal.toStringAsFixed(2),
        },
        "cac:TaxSubtotal": [...cacTaxSubtotal, ...zeroTaxSubtotal],
      },
      {
        "cbc:TaxAmount": {
          "@currencyID": "SAR",
          "#text": taxesTotal.toStringAsFixed(2),
        },
      },
    ],
    'taxesTotal': taxesTotal,
  };
}

Map<String, dynamic> constructLegalMonetaryTotal(
    double totalLineExtensionAmount,
    double totalTax,
    bool acceptWarning) {
  double taxExclusiveAmount = totalLineExtensionAmount;
  double taxInclusiveAmount = taxExclusiveAmount + totalTax;
  return {
    "cbc:LineExtensionAmount": {
      "@currencyID": "SAR",
      "#text": double.parse(totalLineExtensionAmount.toString())
          .toStringAsFixed(2),
    },
    "cbc:TaxExclusiveAmount": {
      "@currencyID": "SAR",
      "#text": roundingNumber(acceptWarning,taxExclusiveAmount),
    },
    "cbc:TaxInclusiveAmount": {
      "@currencyID": "SAR",
      "#text": double.parse(taxInclusiveAmount.toString())
          .toStringAsFixed(2),
    },
    "cbc:PrepaidAmount": {
      "@currencyID": "SAR",
      "#text": 0,
    },
    "cbc:PayableAmount": {
      "@currencyID": "SAR",
      "#text": double.parse(taxInclusiveAmount.toString())
          .toStringAsFixed(2),
    },
  };
}


XmlDocument calc(
    List<ZATCAInvoiceLineItem> lineItems,
    ZATCAInvoiceProps props,
    XmlDocument invoiceXml,
    bool acceptWarning,
    ) {
  double totalTaxes = 0;
  double totalExtensionAmount = 0;
  double totalDiscounts = 0;

  List<Map<String, dynamic>> invoiceLineItems = [];

  lineItems.forEach((lineItem) {
    lineItem.tax_exclusive_price = double.parse(lineItem.tax_exclusive_price.toString()).toDouble();
    var lineItemData = constructLineItem(lineItem, acceptWarning);
    var lineItemXml = lineItemData['lineItemXml'];
    var lineItemTotals = lineItemData['lineItemTotals'];

    totalTaxes += lineItemTotals['taxesTotal'];
    totalExtensionAmount += lineItemTotals['extensionAmount'];
    totalDiscounts += lineItemTotals['discountsTotal'];
    invoiceLineItems.add(lineItemXml);
  });


  // if ((props.invoice_type == "381" || props.invoice_type == "383") && props.cancelation != null) {
  //   invoiceXml.set("Invoice/cac:PaymentMeans", false, {
  //     "cbc:PaymentMeansCode": props.cancelation.paymentMethod,
  //     "cbc:InstructionNote": props.cancelation.reason ?? "No note Specified",
  //   });
  // }

  // Uncomment this line if needed for AllowanceCharge
  // invoiceXml.set("Invoice/cac:AllowanceCharge", false, constructAllowanceCharge(lineItems));

  var taxTotalDetails = constructTaxTotal(lineItems, acceptWarning);

  invoiceXml.set("Invoice/cac:TaxTotal", false, taxTotalDetails['cacTaxTotal']);

  invoiceXml.set("Invoice/cac:LegalMonetaryTotal", true, constructLegalMonetaryTotal(
    totalExtensionAmount,
    totalTaxes,
    acceptWarning,
  ));

for(var lineItem in invoiceLineItems)
{
  invoiceXml.set("Invoice/cac:InvoiceLine", false, lineItem);
}


  return invoiceXml;
}
