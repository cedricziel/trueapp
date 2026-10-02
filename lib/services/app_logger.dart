import 'package:flutter_otel/flutter_otel.dart';

Logger appLogger(String scope) => _AppLogger('truehub.$scope');

class _AppLogger extends Logger {
  _AppLogger(this._name);

  final String _name;

  @override
  void emit(LogRecord record) =>
      OTelSdk.maybeInstance?.getLogger(name: _name).emit(record);
}
