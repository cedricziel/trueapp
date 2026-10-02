import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/resume_refresher.dart';

void main() {
  late List<String> calls;

  ResumeRefresher build({required bool authenticated}) => ResumeRefresher(
    refreshConnection: () async => calls.add('connection'),
    isAuthenticated: () {
      calls.add('authenticated?');
      return authenticated;
    },
    refreshHealth: () async => calls.add('health'),
  );

  setUp(() => calls = []);

  test('refreshes health after the connection when authenticated', () async {
    await build(authenticated: true).refresh();

    expect(calls, ['connection', 'authenticated?', 'health']);
  });

  test('skips the health refresh when not authenticated', () async {
    await build(authenticated: false).refresh();

    expect(calls, ['connection', 'authenticated?']);
  });
}
