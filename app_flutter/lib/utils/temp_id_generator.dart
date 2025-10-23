class TempIdGenerator {
  static int _counter = 0;

  static const int _maxTempId = -100000000;
  static const int _minTempId = -999999999;

  static const int _oldMaxTempId = 999999999;
  static const int _oldMinTempId = 100000000;

  static int generateTempId() {
    _counter++;

    final rangeSize = _minTempId.abs() - _maxTempId.abs();
    if (_counter > rangeSize) {
      _counter = 1;
    }

    final tempId = _maxTempId - _counter;
    return tempId;
  }

  static int generateNegativeTempId() {
    return generateTempId();
  }

  static bool isTempId(int id) {
    final absId = id.abs();

    if (absId >= _maxTempId.abs() && absId <= _minTempId.abs()) {
      return true;
    }

    if (absId >= _oldMinTempId && absId <= _oldMaxTempId) {
      return true;
    }

    return false;
  }

  static int toHiveId(int id) {
    return id < 0 ? -id : id;
  }

  static int fromHiveId(int hiveId, {bool isTemp = false}) {
    if (isTemp && hiveId >= _maxTempId.abs() && hiveId <= _minTempId.abs()) {
      return -hiveId;
    }
    return hiveId;
  }
}
