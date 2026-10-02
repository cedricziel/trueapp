import 'package:truehub/services/api/area_apis.dart';

/// Interface for TrueNAS API clients to enable dependency injection and
/// testing. Callers that only need one area can depend on its narrower
/// interface from `api/area_apis.dart` instead.
abstract interface class ApiClientInterface
    implements
        SessionApi,
        HealthApi,
        PoolsApi,
        DatasetsApi,
        FilesApi,
        AppsApi,
        SystemStatsApi,
        AppStatsApi,
        JobsApi {}
