class TimeOption {
  final int hour;
  final int minute;
  final String displayName;

  TimeOption({required this.hour, required this.minute, required this.displayName}) : assert(hour >= 0 && hour <= 23, 'Hour must be between 0 and 23'), assert([0, 15, 30, 45].contains(minute), 'Minute must be 0, 15, 30, or 45');

  factory TimeOption.fromTime(int hour, int minute) {
    if (![0, 15, 30, 45].contains(minute)) {
      throw ArgumentError('Minute must be 0, 15, 30, or 45');
    }

    final displayName = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return TimeOption(hour: hour, minute: minute, displayName: displayName);
  }

  Map<String, dynamic> toJson() => {'hour': hour, 'minute': minute, 'displayName': displayName};

  factory TimeOption.fromJson(Map<String, dynamic> json) => TimeOption(hour: json['hour'] as int, minute: json['minute'] as int, displayName: json['displayName'] as String);

  @override
  bool operator ==(Object other) => identical(this, other) || other is TimeOption && runtimeType == other.runtimeType && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;

  @override
  String toString() => 'TimeOption($displayName)';
}
