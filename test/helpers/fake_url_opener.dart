import 'package:truehub/services/url_opener.dart';

class FakeUrlOpener implements UrlOpener {
  final List<String> opened = [];
  bool succeeds = true;

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return succeeds;
  }
}
