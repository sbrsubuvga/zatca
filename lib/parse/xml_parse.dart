// import 'package:xml/xml.dart';
// import 'package:collection/collection.dart';
//
// class XMLDocument {
//   late XmlElement xmlElement;
//
//   XMLDocument([String? xmlStr]) {
//     if (xmlStr != null) {
//       final document = XmlDocument.parse(xmlStr);
//       xmlElement = document.rootElement;
//     } else {
//       xmlElement = XmlElement(XmlName('?xml'))
//         ..attributes.add(XmlAttribute(XmlName('version'), '1.0'))
//         ..attributes.add(XmlAttribute(XmlName('encoding'), 'UTF-8'));
//     }
//   }
//
//   // Helper function to find elements
//   XmlElement? _getElement(XmlElement element, String pathQuery) {
//     if (pathQuery.isEmpty) return element;
//     final pathTags = pathQuery.split('/');
//     XmlElement? currentElement = element;
//     for (var tag in pathTags) {
//       currentElement = currentElement!.findElements(tag)
//           .isEmpty ? null : currentElement
//           .findElements(tag)
//           .first;
//       if (currentElement == null) break;
//     }
//       return currentElement;
//   }
//
//   // Querying the XML by path and applying condition
//   List<XmlElement>? get(String pathQuery, {Map<String, String>? condition}) {
//     final element = _getElement(xmlElement, pathQuery);
//     if (element == null) return null;
//
//     var result = element.findElements('*').toList();
//     if (condition != null) {
//       result = result.where((el) {
//         return condition.entries.every((entry) =>
//             el.getAttribute(entry.key) == entry.value);
//       }).toList();
//     }
//     return result.isEmpty ? null : result;
//   }
//
//   // Deleting an element from XML
//   bool delete(String pathQuery, {Map<String, String>? condition}) {
//     final element = _getElement(xmlElement, pathQuery);
//     if (element == null) return false;
//
//     final parent = element.parent;
//     if (parent == null) return false;
//
//     var result = parent.findElements('*').where((el) {
//       return condition != null
//           ? condition.entries.every((entry) =>
//               el.getAttribute(entry.key) == entry.value)
//           : true;
//     }).toList();
//
//     if (result.isEmpty) return false;
//
//     for (var el in result) {
//       el.remove();
//     }
//     return true;
//   }
//
//   // Setting a new XML object at a specific path
//   bool set(String pathQuery, bool overwrite, dynamic setXml) {
//     final pathTags = pathQuery.split('/');
//     final tag = pathTags.removeLast();
//     var parentElement = _getElement(xmlElement, pathTags.join('/'));
//     if (parentElement == null) return false;
//
//     var element = parentElement.findElements(tag).isEmpty
//         ? null
//         : parentElement.findElements(tag).first;
//
//     if (element != null && !overwrite) {
//       // If element exists and not overwriting, append the new element
//       if (setXml is XmlElement) {
//         parentElement.children.add(setXml);
//       } else {
//         parentElement.children.add(XmlElement(XmlName(tag))..innerText = setXml.toString());
//       }
//     } else {
//       // Otherwise, set or overwrite the element
//       if (setXml is XmlElement) {
//         parentElement.children.add(setXml);
//       } else {
//         parentElement.children.add(XmlElement(XmlName(tag))..innerText = setXml.toString());
//       }
//     }
//     return true;
//   }
//
//   // Convert to String with optional header removal
//   String toString({bool noHeader = false}) {
//     var xmlStr = xmlElement.toXmlString(pretty: true, indent: '    ');
//     if (noHeader) {
//       xmlStr = xmlStr.replaceFirst('<?xml version="1.0" encoding="UTF-8"?>\n', '');
//     }
//     return xmlStr.replaceAll('&apos;', "'");
//   }
// }
//
