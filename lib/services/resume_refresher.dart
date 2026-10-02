/// Revives the connection after the app returns to the foreground and
/// refreshes health only when the connection is authenticated again.
class ResumeRefresher {
  ResumeRefresher({
    required Future<void> Function() refreshConnection,
    required bool Function() isAuthenticated,
    required Future<void> Function() refreshHealth,
  }) : _refreshConnection = refreshConnection,
       _isAuthenticated = isAuthenticated,
       _refreshHealth = refreshHealth;

  final Future<void> Function() _refreshConnection;
  final bool Function() _isAuthenticated;
  final Future<void> Function() _refreshHealth;

  Future<void> refresh() async {
    await _refreshConnection();
    if (_isAuthenticated()) {
      await _refreshHealth();
    }
  }
}
