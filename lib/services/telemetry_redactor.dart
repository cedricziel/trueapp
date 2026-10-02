import 'package:flutter_otel/flutter_otel.dart';

/// The redactor every exported log record and span passes through: the
/// package defaults plus TrueNAS API keys (`<id>-<64 alphanumerics>`),
/// which carry no `key=` prefix for the defaults to catch.
Redactor telemetryRedactor() => PatternRedactor(
  extraRules: [RedactionRule(RegExp(r'\b\d+-[A-Za-z0-9]{64}\b'))],
);
