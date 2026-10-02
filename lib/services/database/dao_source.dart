import 'package:truehub/services/database/app_configs_dao.dart';
import 'package:truehub/services/database/servers_dao.dart';

abstract interface class ServersDaoSource {
  ServersDao get serversDao;
}

abstract interface class AppConfigsDaoSource {
  AppConfigsDao get appConfigsDao;
}

abstract interface class DaoSource
    implements ServersDaoSource, AppConfigsDaoSource {}
