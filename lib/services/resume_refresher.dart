/// Revives the connection after the app returns to the foreground and
/// refreshes health only when the connection is authenticated again.
class ResumeRefresher {
  ResumeRefresher({
    required this._refreshConnection,
    required this._isAuthenticated,
    required this._refreshHealth,
  });

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
