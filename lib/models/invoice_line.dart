import 'package:zatca/extesions/discount_list_extesions.dart';

import '../resources/enums.dart';

/// Represents an invoice line item in the invoice.
class InvoiceLine {
  final String id;
  final double quantity;
  final String unitCode;
  final double lineExtensionAmount;
  final String itemName;
  final double taxPercent;
  final List<Discount> discounts;

  /// Creates a new [InvoiceLine] instance.
  InvoiceLine({
    required this.id,
    required this.quantity,
    required this.unitCode,
    required this.lineExtensionAmount,
    required this.itemName,
    required this.taxPercent,
    this.discounts = const [],
  });

  /// Creates an [InvoiceLine] instance from a [Map].
  factory InvoiceLine.fromMap(Map<String, dynamic> map) {
    return InvoiceLine(
      id: map['id'] ?? '',
      quantity: double.tryParse((map['quantity'] ?? '0').toString()) ?? 0,
      unitCode: map['unitCode'] ?? '',
      lineExtensionAmount: map['lineExtensionAmount'] ?? '',
      itemName: map['itemName'] ?? '',
      taxPercent: map['taxPercent'] ?? '',
      discounts:
          List<Discount>.from((map['discounts'] ?? [])
              .map((discount) => Discount.fromMap(discount))
              .toList()),
    );
  }

  /// Converts the [InvoiceLine] instance to a [Map].
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quantity': quantity,
      'unitCode': unitCode,
      'lineExtensionAmount': lineExtensionAmount,
      'itemName': itemName,
      'taxPercent': taxPercent,
      'discounts': discounts.map((discount) => discount.toMap()).toList(),
    };
  }

  double get taxAmount => (lineExtensionAmount * taxPercent / 100);
  double get taxExclusivePrice =>
      (lineExtensionAmount / quantity) + discounts.totalAmount;
  double get taxExclusiveDiscountAppliedPrice =>
      (lineExtensionAmount / quantity);
  double get roundingAmount => lineExtensionAmount + taxAmount;
}

/// Represents the cancellation details of an invoice.
class InvoiceCancellation {
  /// The reason for the cancellation.
  final String reason;

  /// The canceled serial invoice number.
  final String canceledSerialInvoiceNumber;

  /// The payment method used.
  final ZATCAPaymentMethods paymentMethod;

  /// Creates a new [InvoiceCancellation] instance.
  InvoiceCancellation({
    required this.reason,
    required this.canceledSerialInvoiceNumber,
    required this.paymentMethod,
  });

  /// Creates an [InvoiceCancellation] instance from a [Map].
  factory InvoiceCancellation.fromMap(Map<String, dynamic> map) {
    return InvoiceCancellation(
      reason: map['reason'] ?? '',
      canceledSerialInvoiceNumber: map['canceled_serial_invoice_number'] ?? '',
      paymentMethod: ZATCAPaymentMethods.values[map['payment_method']],
    );
  }

  /// Converts the [InvoiceCancellation] instance to a [Map].
  Map<String, dynamic> toMap() {
    return {
      'reason': reason,
      'canceled_serial_invoice_number': canceledSerialInvoiceNumber,
      'payment_method': paymentMethod.index,
    };
  }
}

/// Represents a discount applied to an invoice.
class Discount {
  /// The amount of the discount.
  final double amount;

  /// The reason for the discount.
  final String reason;

  /// Creates a new [Discount] instance.
  Discount({required this.amount, required this.reason});

  /// Creates a [Discount] instance from a [Map].
  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      amount: map['amount']?.toDouble() ?? 0.0,
      reason: map['reason'] ?? '',
    );
  }

  /// Converts the [Discount] instance to a [Map].
  Map<String, dynamic> toMap() {
    return {'amount': amount, 'reason': reason};
  }
}
