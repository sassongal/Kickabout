// Stub for dart:html when not running on web platform
// This allows conditional imports to work on non-web platforms

class Window {
  Document get document => Document();
}

class Document {
  Element? querySelector(String selector) => null;
  HeadElement? get head => null;
  Element createElement(String tag) => Element();
}

class HeadElement {
  void append(dynamic element) {}
}

class Element {
  void setAttribute(String name, String value) {}
}

class MetaElement extends Element {
  String name = '';
  String content = '';
}

class CustomEvent {
  final String type;
  final dynamic detail;
  CustomEvent(this.type, {this.detail});
}

Window get window => Window();
Document get document => Document();

