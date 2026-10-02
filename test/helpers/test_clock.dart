class TestClock {
  TestClock(this._currentTime);

  DateTime _currentTime;

  DateTime now() => _currentTime;

  void elapse(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }
}
