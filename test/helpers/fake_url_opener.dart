import 'package:truehub/services/url_opener.dart';

class FakeUrlOpener implements UrlOpener {
  final List<String> opened = [];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return true;
  }
}
