/// Lifecycle state of an installed TrueNAS app, as reported by `app.query`.
enum AppState {
  running('RUNNING'),
  deploying('DEPLOYING'),
  stopping('STOPPING'),
  stopped('STOPPED'),
  crashed('CRASHED'),
  unknown(null);

  const AppState(this.apiValue);

  /// The TrueNAS `state` string, or null when the state is not known.
  final String? apiValue;

  static AppState parse(String? value) {
    for (final state in values) {
      if (state.apiValue != null && state.apiValue == value) return state;
    }
    return unknown;
  }

  bool get canStart => this == stopped || this == crashed;
  bool get canStop => this == running || this == deploying || this == crashed;
  bool get canRestart => this == running;
}
