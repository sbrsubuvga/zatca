import 'package:equatable/equatable.dart';
import 'package:zatca/models/customer.dart';
import 'package:zatca/resources/enums.dart';

/// The user-facing invoice variants, flattened so the UI can show
/// a single dropdown. Each maps to one of the package's invoice
/// classes in [InvoiceBloc].
enum InvoiceKind {
  simplifiedInvoice('Simplified Invoice', 'B2C', false),
  simplifiedCreditNote('Simplified Credit Note', 'B2C', true),
  simplifiedDebitNote('Simplified Debit Note', 'B2C', true),
  standardInvoice('Standard Invoice', 'B2B', false),
  standardCreditNote('Standard Credit Note', 'B2B', true),
  standardDebitNote('Standard Debit Note', 'B2B', true);

  final String label;
  final String audience;
  final bool isCreditOrDebitNote;
  const InvoiceKind(this.label, this.audience, this.isCreditOrDebitNote);

  bool get isStandard => audience == 'B2B';
  bool get isSimplified => audience == 'B2C';
}

enum InvoiceStatus { draft, submitting, success, failure }

/// A draft line item. Stored as strings while the user is typing so
/// we don't fight the text controllers.
class InvoiceLineDraft extends Equatable {
  final String id;
  final String itemName;
  final String quantity;
  final String unitCode;
  final String unitPrice;
  final String taxPercent;
  final String discountAmount;
  final String discountReason;

  const InvoiceLineDraft({
    required this.id,
    this.itemName = '',
    this.quantity = '1',
    this.unitCode = 'PCE',
    this.unitPrice = '0',
    this.taxPercent = '15',
    this.discountAmount = '0',
    this.discountReason = '',
  });

  double get quantityD => double.tryParse(quantity) ?? 0;
  double get unitPriceD => double.tryParse(unitPrice) ?? 0;
  double get taxPercentD => double.tryParse(taxPercent) ?? 0;
  double get discountAmountD => double.tryParse(discountAmount) ?? 0;

  double get lineExtensionAmount =>
      (quantityD * unitPriceD) - discountAmountD;
  double get lineTax => (lineExtensionAmount * taxPercentD) / 100;
  double get lineTotal => lineExtensionAmount + lineTax;

  InvoiceLineDraft copyWith({
    String? itemName,
    String? quantity,
    String? unitCode,
    String? unitPrice,
    String? taxPercent,
    String? discountAmount,
    String? discountReason,
  }) => InvoiceLineDraft(
    id: id,
    itemName: itemName ?? this.itemName,
    quantity: quantity ?? this.quantity,
    unitCode: unitCode ?? this.unitCode,
    unitPrice: unitPrice ?? this.unitPrice,
    taxPercent: taxPercent ?? this.taxPercent,
    discountAmount: discountAmount ?? this.discountAmount,
    discountReason: discountReason ?? this.discountReason,
  );

  @override
  List<Object?> get props => [
    id,
    itemName,
    quantity,
    unitCode,
    unitPrice,
    taxPercent,
    discountAmount,
    discountReason,
  ];
}

/// ZATCA's API response summary for the result screen.
class SubmissionResult extends Equatable {
  final String apiEndpoint;
  final String status;
  final String? reportingStatus;
  final String? clearanceStatus;
  final List<String> infoMessages;
  final List<String> warningMessages;
  final List<String> errorMessages;
  final String? rawResponse;
  final bool cleared;

  const SubmissionResult({
    required this.apiEndpoint,
    required this.status,
    this.reportingStatus,
    this.clearanceStatus,
    this.infoMessages = const [],
    this.warningMessages = const [],
    this.errorMessages = const [],
    this.rawResponse,
    required this.cleared,
  });

  @override
  List<Object?> get props => [
    apiEndpoint,
    status,
    reportingStatus,
    clearanceStatus,
    infoMessages,
    warningMessages,
    errorMessages,
    cleared,
  ];
}

class InvoiceState extends Equatable {
  final InvoiceStatus status;
  final InvoiceKind kind;
  final String invoiceNumber;
  final ZATCAPaymentMethods paymentMethod;
  final Customer? customer;
  final String cancellationReason;
  final String canceledSerialInvoiceNumber;
  final List<InvoiceLineDraft> lines;

  // Outputs (populated after successful submission)
  final String? invoiceHash;
  final String? digitalSignature;
  final String? qrString;
  final String? ublXml;
  final SubmissionResult? submission;
  final String? errorMessage;

  const InvoiceState({
    this.status = InvoiceStatus.draft,
    this.kind = InvoiceKind.simplifiedInvoice,
    this.invoiceNumber = '',
    this.paymentMethod = ZATCAPaymentMethods.cash,
    this.customer,
    this.cancellationReason = '',
    this.canceledSerialInvoiceNumber = '',
    this.lines = const [],
    this.invoiceHash,
    this.digitalSignature,
    this.qrString,
    this.ublXml,
    this.submission,
    this.errorMessage,
  });

  double get subtotal => lines.fold(0.0, (s, l) => s + l.lineExtensionAmount);
  double get taxTotal => lines.fold(0.0, (s, l) => s + l.lineTax);
  double get grandTotal => subtotal + taxTotal;

  InvoiceState copyWith({
    InvoiceStatus? status,
    InvoiceKind? kind,
    String? invoiceNumber,
    ZATCAPaymentMethods? paymentMethod,
    Customer? customer,
    String? cancellationReason,
    String? canceledSerialInvoiceNumber,
    List<InvoiceLineDraft>? lines,
    String? invoiceHash,
    String? digitalSignature,
    String? qrString,
    String? ublXml,
    SubmissionResult? submission,
    String? errorMessage,
    bool clearError = false,
    bool clearCustomer = false,
  }) => InvoiceState(
    status: status ?? this.status,
    kind: kind ?? this.kind,
    invoiceNumber: invoiceNumber ?? this.invoiceNumber,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    customer: clearCustomer ? null : (customer ?? this.customer),
    cancellationReason: cancellationReason ?? this.cancellationReason,
    canceledSerialInvoiceNumber:
        canceledSerialInvoiceNumber ?? this.canceledSerialInvoiceNumber,
    lines: lines ?? this.lines,
    invoiceHash: invoiceHash ?? this.invoiceHash,
    digitalSignature: digitalSignature ?? this.digitalSignature,
    qrString: qrString ?? this.qrString,
    ublXml: ublXml ?? this.ublXml,
    submission: submission ?? this.submission,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [
    status,
    kind,
    invoiceNumber,
    paymentMethod,
    customer?.companyID,
    customer?.registrationName,
    cancellationReason,
    canceledSerialInvoiceNumber,
    lines,
    invoiceHash,
    digitalSignature,
    qrString,
    ublXml,
    submission,
    errorMessage,
  ];
}
