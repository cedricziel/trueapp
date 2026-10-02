import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/apps/app_config_mapper.dart';

NasServer _server({bool useHttps = true}) => NasServer.create(
  name: 'nas',
  host: 'nas.local',
  username: 'admin',
  password: 'pw',
  useHttps: useHttps,
);

void main() {
  test('leaves URLs untouched without a server', () {
    expect(
      const AppConfigMapper(null).interpolateUrl('tcp://localhost:80'),
      'tcp://localhost:80',
    );
  });

  test('points localhost at the server host', () {
    expect(
      AppConfigMapper(_server()).interpolateUrl('http://127.0.0.1:8080/x?a=1'),
      'http://nas.local:8080/x?a=1',
    );
  });

  test('maps the tcp scheme to http or https per server config', () {
    expect(
      AppConfigMapper(_server()).interpolateUrl('tcp://localhost:9000'),
      'https://nas.local:9000',
    );
    expect(
      AppConfigMapper(_server(useHttps: false)).interpolateUrl('tcp://h:9000'),
      'http://h:9000',
    );
  });
}
