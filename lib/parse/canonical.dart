import 'package:xml/xml.dart';

class XmlCanonicalizer {
  bool includeComments;
  bool exclusiveCanonicalization;

  XmlCanonicalizer({this.includeComments = false, this.exclusiveCanonicalization = false});

  String canonicalize(XmlNode node) {
    final canonicalized = StringBuffer();
    if (node is XmlElement) {
      canonicalized.write('<${node.name.local}');
      node.attributes.forEach((attr) {
        canonicalized.write(' ${attr.name.local}="${attr.value}"');
      });
      canonicalized.write('>');
      node.children.forEach((child) {
        canonicalized.write(canonicalize(child));
      });
      canonicalized.write('</${node.name.local}>');
    } else if (node is XmlText) {
      canonicalized.write(node.text);
    }
    return canonicalized.toString();
  }

  String canonicalizeXml(XmlDocument document) {
    final canonicalized = StringBuffer();
    document.children.forEach((node) {
      canonicalized.write(canonicalize(node));
    });
    return canonicalized.toString();
  }
}