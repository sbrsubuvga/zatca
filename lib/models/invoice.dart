import '../resources/enums.dart';
import 'customer.dart';
import 'invoice_line.dart';

class BaseInvoice {
  final InvoiceType invoiceType;

  final String profileID = 'reporting:1.0';

  /// The unique identifier of the invoice.
  final String invoiceNumber;

  /// The universally unique identifier (UUID) of the invoice.
  final String uuid;

  /// The issue date of the invoice in ISO 8601 format.
  final String issueDate;

  /// The issue time of the invoice in ISO 8601 format.
  final String issueTime;

  /// The currency code used in the invoice.
  final String currencyCode;

  /// The tax currency code used in the invoice.
  final String taxCurrencyCode;

  /// The customer information.
  final Customer? customer;

  /// The list of invoice line items.
  final List<InvoiceLine> invoiceLines;

  /// The total tax amount for the invoice.
  final double taxAmount;

  /// The total amount for the invoice.
  final double totalAmount;

  /// The hash of the previous invoice, if applicable.
  final String previousInvoiceHash;

  BaseInvoice({
    required this.invoiceNumber,
    required this.uuid,
    required this.issueDate,
    required this.issueTime,
    required this.currencyCode,
    required this.taxCurrencyCode,
    this.customer,
    required this.invoiceLines,
    required this.taxAmount,
    required this.totalAmount,
    required this.previousInvoiceHash,
    required this.invoiceType,
  });

  factory BaseInvoice.fromJson(Map<String, dynamic> json) {
    return BaseInvoice(
      invoiceNumber: json['invoiceNumber'],
      uuid: json['uuid'],
      issueDate: json['issueDate'],
      issueTime: json['issueTime'],
      currencyCode: json['currencyCode'],
      taxCurrencyCode: json['taxCurrencyCode'],
      customer:
          json['customer'] != null ? Customer.fromMap(json['customer']) : null,
      invoiceLines:
          (json['invoiceLines'] as List)
              .map((item) => InvoiceLine.fromMap(item))
              .toList(),
      taxAmount: json['taxAmount'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      previousInvoiceHash: json['previousInvoiceHash'],
      invoiceType: InvoiceType.values[json['invoiceType']],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invoiceNumber': invoiceNumber,
      'uuid': uuid,
      'issueDate': issueDate,
      'issueTime': issueTime,
      'currencyCode': currencyCode,
      'taxCurrencyCode': taxCurrencyCode,
      'customer': customer?.toMap(),
      'invoiceLines': invoiceLines.map((item) => item.toMap()).toList(),
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'previousInvoiceHash': previousInvoiceHash,
      'invoiceType': invoiceType,
    };
  }
}

class Invoice extends BaseInvoice {
  /// The actual delivery date of the invoice in ISO 8601 format.
  final String actualDeliveryDate;

  Invoice({
    required super.invoiceNumber,
    required super.uuid,
    required super.issueDate,
    required super.issueTime,
    required super.currencyCode,
    required super.taxCurrencyCode,
    super.customer,
    required super.invoiceLines,
    required super.taxAmount,
    required super.totalAmount,
    required super.previousInvoiceHash,
    required super.invoiceType,
    required this.actualDeliveryDate,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceNumber: json['invoiceNumber'],
      uuid: json['uuid'],
      issueDate: json['issueDate'],
      issueTime: json['issueTime'],
      currencyCode: json['currencyCode'],
      taxCurrencyCode: json['taxCurrencyCode'],
      customer:
          json['customer'] != null ? Customer.fromMap(json['customer']) : null,
      invoiceLines:
          (json['invoiceLines'] as List)
              .map((item) => InvoiceLine.fromMap(item))
              .toList(),
      taxAmount: json['taxAmount'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      previousInvoiceHash: json['previousInvoiceHash'],
      invoiceType: InvoiceType.values[json['invoiceType']],
      actualDeliveryDate: json['actualDeliveryDate'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['actualDeliveryDate'] = actualDeliveryDate;
    return json;
  }
}

class SimplifiedInvoice extends Invoice {
  SimplifiedInvoice({
    required super.invoiceNumber,
    required super.uuid,
    required super.issueDate,
    required super.issueTime,
    required super.currencyCode,
    required super.taxCurrencyCode,
    super.customer,
    required super.invoiceLines,
    required super.taxAmount,
    required super.totalAmount,
    required super.previousInvoiceHash,
    required super.actualDeliveryDate,
  }) : super(invoiceType: InvoiceType.simplifiedInvoice);

  factory SimplifiedInvoice.fromJson(Map<String, dynamic> json) {
    return SimplifiedInvoice(
      invoiceNumber: json['invoiceNumber'],
      uuid: json['uuid'],
      issueDate: json['issueDate'],
      issueTime: json['issueTime'],
      currencyCode: json['currencyCode'],
      taxCurrencyCode: json['taxCurrencyCode'],
      customer:
          json['customer'] != null ? Customer.fromMap(json['customer']) : null,
      invoiceLines:
          (json['invoiceLines'] as List)
              .map((item) => InvoiceLine.fromMap(item))
              .toList(),
      taxAmount: json['taxAmount'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      previousInvoiceHash: json['previousInvoiceHash'],
      actualDeliveryDate: json['actualDeliveryDate'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['actualDeliveryDate'] = actualDeliveryDate;
    return json;
  }
}

class StandardInvoice extends Invoice {
  StandardInvoice({
    required super.invoiceNumber,
    required super.uuid,
    required super.issueDate,
    required super.issueTime,
    required super.currencyCode,
    required super.taxCurrencyCode,
    required Customer super.customer,
    required super.invoiceLines,
    required super.taxAmount,
    required super.totalAmount,
    required super.previousInvoiceHash,
    required super.actualDeliveryDate,
  }) : super(invoiceType: InvoiceType.standardInvoice);

  factory StandardInvoice.fromJson(Map<String, dynamic> json) {
    return StandardInvoice(
      invoiceNumber: json['invoiceNumber'],
      uuid: json['uuid'],
      issueDate: json['issueDate'],
      issueTime: json['issueTime'],
      currencyCode: json['currencyCode'],
      taxCurrencyCode: json['taxCurrencyCode'],
      customer: Customer.fromMap(json['customer']), // Required
      invoiceLines:
          (json['invoiceLines'] as List)
              .map((item) => InvoiceLine.fromMap(item))
              .toList(),
      taxAmount: json['taxAmount'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      previousInvoiceHash: json['previousInvoiceHash'],
      actualDeliveryDate: json['actualDeliveryDate'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['actualDeliveryDate'] = actualDeliveryDate;
    return json;
  }
}

class DBInvoice extends BaseInvoice {
  /// The cancellation details of the invoice.
  final InvoiceCancellation cancellation;

  DBInvoice({
    required super.invoiceNumber,
    required super.uuid,
    required super.issueDate,
    required super.issueTime,
    required super.currencyCode,
    required super.taxCurrencyCode,
    super.customer, // Changed to optional
    required super.invoiceLines,
    required super.taxAmount,
    required super.totalAmount,
    required super.previousInvoiceHash,
    required super.invoiceType,
    required this.cancellation,
  });

  factory DBInvoice.fromJson(Map<String, dynamic> json) {
    return DBInvoice(
      invoiceNumber: json['invoiceNumber'],
      uuid: json['uuid'],
      issueDate: json['issueDate'],
      issueTime: json['issueTime'],
      currencyCode: json['currencyCode'],
      taxCurrencyCode: json['taxCurrencyCode'],
      customer:
          json['customer'] != null ? Customer.fromMap(json['customer']) : null,
      invoiceLines:
          (json['invoiceLines'] as List)
              .map((item) => InvoiceLine.fromMap(item))
              .toList(),
      taxAmount: json['taxAmount'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      previousInvoiceHash: json['previousInvoiceHash'],
      invoiceType: InvoiceType.values[json['invoiceType']],
      cancellation: InvoiceCancellation.fromMap(json['cancellation']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['cancellation'] = cancellation.toMap();
    return json;
  }
}

class SimplifiedCreditNoteInvoice extends DBInvoice {
  SimplifiedCreditNoteInvoice({
    required super.invoiceNumber,
    required super.uuid,
    required super.issueDate,
    required super.issueTime,
    required super.currencyCode,
    required super.taxCurrencyCode,
    super.customer, // Now optional
    required super.invoiceLines,
    required super.taxAmount,
    required super.totalAmount,
    required super.previousInvoiceHash,
    required super.cancellation,
  }) : super(invoiceType: InvoiceType.simplifiedCreditNote);

  factory SimplifiedCreditNoteInvoice.fromJson(Map<String, dynamic> json) {
    return SimplifiedCreditNoteInvoice(
      invoiceNumber: json['invoiceNumber'],
      uuid: json['uuid'],
      issueDate: json['issueDate'],
      issueTime: json['issueTime'],
      currencyCode: json['currencyCode'],
      taxCurrencyCode: json['taxCurrencyCode'],
      customer:
          json['customer'] != null ? Customer.fromMap(json['customer']) : null,
      invoiceLines:
          (json['invoiceLines'] as List)
              .map((item) => InvoiceLine.fromMap(item))
              .toList(),
      taxAmount: json['taxAmount'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      previousInvoiceHash: json['previousInvoiceHash'],
      cancellation: InvoiceCancellation.fromMap(json['cancellation']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['cancellation'] = cancellation.toMap();
    return json;
  }
}

class StandardCreditNoteInvoice extends DBInvoice {
  StandardCreditNoteInvoice({
    required super.invoiceNumber,
    required super.uuid,
    required super.issueDate,
    required super.issueTime,
    required super.currencyCode,
    required super.taxCurrencyCode,
    required Customer super.customer, // Required for standard
    required super.invoiceLines,
    required super.taxAmount,
    required super.totalAmount,
    required super.previousInvoiceHash,
    required super.cancellation,
  }) : super(invoiceType: InvoiceType.standardCreditNote);

  factory StandardCreditNoteInvoice.fromJson(Map<String, dynamic> json) {
    return StandardCreditNoteInvoice(
      invoiceNumber: json['invoiceNumber'],
      uuid: json['uuid'],
      issueDate: json['issueDate'],
      issueTime: json['issueTime'],
      currencyCode: json['currencyCode'],
      taxCurrencyCode: json['taxCurrencyCode'],
      customer: Customer.fromMap(json['customer']), // Required
      invoiceLines:
          (json['invoiceLines'] as List)
              .map((item) => InvoiceLine.fromMap(item))
              .toList(),
      taxAmount: json['taxAmount'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      previousInvoiceHash: json['previousInvoiceHash'],
      cancellation: InvoiceCancellation.fromMap(json['cancellation']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['cancellation'] = cancellation.toMap();
    return json;
  }
}

class SimplifiedDebitNoteInvoice extends DBInvoice {
  SimplifiedDebitNoteInvoice({
    required super.invoiceNumber,
    required super.uuid,
    required super.issueDate,
    required super.issueTime,
    required super.currencyCode,
    required super.taxCurrencyCode,
    super.customer, // Now optional
    required super.invoiceLines,
    required super.taxAmount,
    required super.totalAmount,
    required super.previousInvoiceHash,
    required super.cancellation,
  }) : super(invoiceType: InvoiceType.simplifiedDebitNote);

  factory SimplifiedDebitNoteInvoice.fromJson(Map<String, dynamic> json) {
    return SimplifiedDebitNoteInvoice(
      invoiceNumber: json['invoiceNumber'],
      uuid: json['uuid'],
      issueDate: json['issueDate'],
      issueTime: json['issueTime'],
      currencyCode: json['currencyCode'],
      taxCurrencyCode: json['taxCurrencyCode'],
      customer:
          json['customer'] != null ? Customer.fromMap(json['customer']) : null,
      invoiceLines:
          (json['invoiceLines'] as List)
              .map((item) => InvoiceLine.fromMap(item))
              .toList(),
      taxAmount: json['taxAmount'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      previousInvoiceHash: json['previousInvoiceHash'],
      cancellation: InvoiceCancellation.fromMap(json['cancellation']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['cancellation'] = cancellation.toMap();
    return json;
  }
}

class StandardDebitNoteInvoice extends DBInvoice {
  StandardDebitNoteInvoice({
    required super.invoiceNumber,
    required super.uuid,
    required super.issueDate,
    required super.issueTime,
    required super.currencyCode,
    required super.taxCurrencyCode,
    required Customer super.customer, // Required for standard
    required super.invoiceLines,
    required super.taxAmount,
    required super.totalAmount,
    required super.previousInvoiceHash,
    required super.cancellation,
  }) : super(invoiceType: InvoiceType.standardDebitNote);

  factory StandardDebitNoteInvoice.fromJson(Map<String, dynamic> json) {
    return StandardDebitNoteInvoice(
      invoiceNumber: json['invoiceNumber'],
      uuid: json['uuid'],
      issueDate: json['issueDate'],
      issueTime: json['issueTime'],
      currencyCode: json['currencyCode'],
      taxCurrencyCode: json['taxCurrencyCode'],
      customer: Customer.fromMap(json['customer']), // Required
      invoiceLines:
          (json['invoiceLines'] as List)
              .map((item) => InvoiceLine.fromMap(item))
              .toList(),
      taxAmount: json['taxAmount'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      previousInvoiceHash: json['previousInvoiceHash'],
      cancellation: InvoiceCancellation.fromMap(json['cancellation']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['cancellation'] = cancellation.toMap();
    return json;
  }
}
