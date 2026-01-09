class Address {
  final String city;
  final String citySubdivision;
  final String street;
  final String building;
  final String postalZone;
  final String countryCode;

  Address({
    required this.city,
    required this.citySubdivision,
    required this.street,
    required this.building,
    required this.postalZone,
    this.countryCode = "SA",
  });

  /// Creates an [Address] instance from a [Map].
  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] ?? '',
      building: map['building'] ?? '',
      citySubdivision: map['citySubdivision'] ?? '',
      city: map['city'] ?? '',
      postalZone: map['postalZone'] ?? '',
      countryCode: map['countryCode'] ?? 'SA',
    );
  }

  /// Converts the [Address] instance to a [Map].
  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'building': building,
      'citySubdivision': citySubdivision,
      'city': city,
      'postalZone': postalZone,
      'countryCode': countryCode,
    };
  }
}

class Location extends Address {
  final String plotIdentification;

  Location({
    required super.city,
    required super.citySubdivision,
    required super.street,
    required super.building,
    required super.postalZone,
    super.countryCode = "SA",
    required this.plotIdentification,
  });

  String get branchLocation {
    return '$building $street, $city';
  }

  /// Creates an [Address] instance from a [Map].

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      street: map['street'] ?? '',
      building: map['building'] ?? '',
      citySubdivision: map['citySubdivision'] ?? '',
      city: map['city'] ?? '',
      postalZone: map['postalZone'] ?? '',
      countryCode: map['countryCode'] ?? 'SA',
      plotIdentification: map['plotIdentification'] ?? '',
    );
  }

  /// Converts the [Address] instance to a [Map].
  @override
  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'building': building,
      'citySubdivision': citySubdivision,
      'city': city,
      'postalZone': postalZone,
      'countryCode': countryCode,
      'plotIdentification': plotIdentification,
    };
  }
}
