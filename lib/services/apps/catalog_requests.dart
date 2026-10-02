import 'package:truehub/models/app.dart';
import 'package:truehub/services/api_client_interface.dart';

/// The result of a settled future: exactly one of [value] or [error] is set.
/// [stackTrace] is only set alongside [error], so a settled failure can
/// still be reported to telemetry with its original trace.
class Outcome<T> {
  final T? value;
  final Object? error;
  final StackTrace? stackTrace;

  const Outcome.success(this.value) : error = null, stackTrace = null;
  const Outcome.failure(this.error, this.stackTrace) : value = null;

  static Future<Outcome<T>> settle<T>(Future<T> future) => future
      .then<Outcome<T>>(Outcome.success)
      .catchError(
        (Object e, StackTrace stackTrace) => Outcome<T>.failure(e, stackTrace),
      );
}

/// The catalog side of a load, started alongside the installed-apps request
/// and merged in a second phase once installed apps are already visible.
/// Both futures are settled, so abandoning a request leaks no error.
class CatalogRequests {
  final Future<Outcome<List<App>>> available;
  final Future<Outcome<List<String>>> categories;

  const CatalogRequests({required this.available, required this.categories});

  factory CatalogRequests.start(ApiClientInterface client) => CatalogRequests(
    available: Outcome.settle(client.getAvailableApps()),
    categories: Outcome.settle(client.getAppCategories()),
  );
}
