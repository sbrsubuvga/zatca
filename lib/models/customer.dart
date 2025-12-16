import 'address.dart';

/// Represents a customer in the invoice.
class Customer {
  /// The company ID of the customer.
  final String companyID;

  /// The registration name of the customer.
  final String registrationName;

  /// The address of the customer.
  final Address address;

  final String? businessID;

  Customer({
    required this.companyID,
    required this.registrationName,
    required this.address,
    this.businessID,
  });

  /// Creates a [Customer] instance from a [Map].
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      companyID: map['companyID'] ?? '',
      registrationName: map['registrationName'] ?? '',
      address: Address.fromMap(map['address']),
      businessID: map['businessID'],
    );
  }

  /// Converts the [Customer] instance to a [Map].
  Map<String, dynamic> toMap() {
    return {
      'companyID': companyID,
      'registrationName': registrationName,
      'address': address.toMap(),
      'businessID': businessID,
    };
  }
}
