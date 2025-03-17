import 'package:collection/collection.dart';
// import 'package:lithosposremake/services/zatca/parser/xml_node_extension.dart';
import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

extension XmlDocumentExtension on XmlDocument {

  XmlNode generate(dynamic json, String key) {
    if (json is Map) {
      List<XmlAttribute> attributes = [];
      List<XmlNode> nonAttributes = [];
      json.forEach((key, value) {
        if (key.startsWith('@')) {
          attributes.add(XmlAttribute(XmlName(key.substring(1)), value.toString()));
        } else if (key.startsWith('#')) {
          nonAttributes.add(XmlText(value.toString()));
        } else {
          nonAttributes.add(generate(value, key));
        }
      });
      return XmlElement(XmlName(key), attributes, nonAttributes);
    } else if (json is List) {
      final Iterable<XmlNode> children = json.map((item) => generate(item, key));
      return XmlDocumentFragment(children);
    } else {
      return XmlElement(XmlName(key), [], [XmlText(json.toString())]);
    }
  }



  void set(String pathQuery, bool overwrite, dynamic data) {

    List<String> parts = pathQuery.split('/');
    String tag = parts.removeLast();
    pathQuery = parts.join("/");


    Iterable<XmlNode> nodes = xpath(pathQuery);
    if (nodes.isEmpty) return; // Path not found


    for (XmlNode node in nodes) {
     // XmlElement element =node as XmlElement;
      XmlNode? exist=node.xpath(tag).firstOrNull;
      XmlNode element = generate(data,tag);
      if(exist!=null) {
        if(overwrite) exist.replace(element);
      }
      else{
        node.children.add(element);
      }
    }
  }





  bool delete(String pathQuery, {required Map<String, String> condition}) {
    var elements = xpath(pathQuery);
    for (var element in elements) {
      if (matchesCondition(element, condition)) {
        element.remove();
      }
    }
    return true;
  }

  Iterable<XmlNode> xpath(String pathQuery) {
    List<String> parts = pathQuery.split('/');
    XmlNode? current = this;
    for (String part in parts) {
      if (part.isEmpty) continue;
      if (part.contains('[')) {
        String tagName = part.substring(0, part.indexOf('['));
        int index = int.parse(part.substring(part.indexOf('[') + 1, part.indexOf(']')));
        current = current?.findElements(tagName).elementAt(index - 1);
      } else {
        current = current?.findElements(part).firstOrNull;
      }
      if (current == null) return const Iterable.empty();
    }
    if(current==null) {
      return [];
    } else {
      return [current];
    }
  }


  bool matchesCondition(XmlNode node, Map<String, String> condition) {
    if (condition == null) {
      return true; // No condition, so always true
    }
    if (node is XmlElement) {
      for (var entry in condition.entries) {
        var attribute = node.getAttribute(entry.key);
        if (attribute != entry.value) {
          return false;
        }
      }
      return true;
    }
    return false; // Node is not an element
  }
}