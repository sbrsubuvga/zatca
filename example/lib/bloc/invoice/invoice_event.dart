import 'package:equatable/equatable.dart';
import 'package:zatca/models/customer.dart';
import 'package:zatca/resources/enums.dart';

import 'invoice_state.dart';

sealed class InvoiceEvent extends Equatable {
  const InvoiceEvent();
  @override
  List<Object?> get props => [];
}

class InvoiceStarted extends InvoiceEvent {
  const InvoiceStarted();
}

class InvoiceKindChanged extends InvoiceEvent {
  final InvoiceKind kind;
  const InvoiceKindChanged(this.kind);
  @override
  List<Object?> get props => [kind];
}

class InvoiceNumberChanged extends InvoiceEvent {
  final String value;
  const InvoiceNumberChanged(this.value);
  @override
  List<Object?> get props => [value];
}

class InvoicePaymentMethodChanged extends InvoiceEvent {
  final ZATCAPaymentMethods method;
  const InvoicePaymentMethodChanged(this.method);
  @override
  List<Object?> get props => [method];
}

class InvoiceCustomerChanged extends InvoiceEvent {
  final Customer customer;
  const InvoiceCustomerChanged(this.customer);
  @override
  List<Object?> get props => [customer];
}

class InvoiceCancellationChanged extends InvoiceEvent {
  final String reason;
  final String canceledSerialInvoiceNumber;
  const InvoiceCancellationChanged({
    required this.reason,
    required this.canceledSerialInvoiceNumber,
  });
  @override
  List<Object?> get props => [reason, canceledSerialInvoiceNumber];
}

class InvoiceLineAdded extends InvoiceEvent {
  const InvoiceLineAdded();
}

class InvoiceLineRemoved extends InvoiceEvent {
  final int index;
  const InvoiceLineRemoved(this.index);
  @override
  List<Object?> get props => [index];
}

class InvoiceLineUpdated extends InvoiceEvent {
  final int index;
  final InvoiceLineDraft draft;
  const InvoiceLineUpdated(this.index, this.draft);
  @override
  List<Object?> get props => [index, draft];
}

class InvoiceSubmitted extends InvoiceEvent {
  const InvoiceSubmitted();
}

class InvoiceDismissed extends InvoiceEvent {
  const InvoiceDismissed();
}
