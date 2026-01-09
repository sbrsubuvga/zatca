import 'dart:convert';
import 'dart:typed_data';

/// Generates a TLV (Tag-Length-Value) encoded string from the given data.
///
/// The `data` parameter is a map where the key is the tag (integer) and the value
/// is the associated data. The value can be a `String`, `Uint8List`, or `List<int>`.
/// Throws an `ArgumentError` if the value type is unsupported.
///
/// Returns the TLV encoded string.
String generateTlv(Map<int, dynamic> data) {
  StringBuffer tlv = StringBuffer();

  data.forEach((tag, value) {
    tlv.write(tag.toRadixString(16).padLeft(2, '0')); // Tag in hex

    List<int> valueBytes;

    if (value is String) {
      valueBytes = utf8.encode(value); // String → UTF-8 bytes
    } else if (value is Uint8List || value is List<int>) {
      valueBytes = List<int>.from(value); // Treat as raw bytes
    } else {
      throw ArgumentError('Unsupported value type for tag $tag');
    }

    // Write length in hex (two digits)
    tlv.write(valueBytes.length.toRadixString(16).padLeft(2, '0'));

    // Write value bytes as hex
    for (int byte in valueBytes) {
      tlv.write(byte.toRadixString(16).padLeft(2, '0'));
    }
  });

  return tlv.toString();
}

/// Converts a TLV encoded string to a Base64 encoded string.
///
/// The `tlv` parameter is a string containing the TLV encoded data.
/// Returns the Base64 encoded representation of the TLV data.
String tlvToBase64(String tlv) {
  List<int> bytes = [];

  for (int i = 0; i < tlv.length; i += 2) {
    String hexStr = tlv.substring(i, i + 2);
    int byte = int.parse(hexStr, radix: 16);
    bytes.add(byte);
  }

  return base64Encode(Uint8List.fromList(bytes));
}
