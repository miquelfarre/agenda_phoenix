import 'package:intl/intl.dart';

class MonthOption {
  final int month;
  final int year;
  final String displayName;
  final bool isSelectable;

  MonthOption({
    required this.month,
    required this.year,
    required this.displayName,
    this.isSelectable = true,
  }) : assert(month >= 1 && month <= 12, 'Month must be between 1 and 12');

  factory MonthOption.fromDateTime(DateTime date, String locale) {
    final formatter = DateFormat('MMMM yyyy', locale);
    return MonthOption(
      month: date.month,
      year: date.year,
      displayName: formatter.format(date),
      isSelectable: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month,
    'year': year,
    'displayName': displayName,
    'isSelectable': isSelectable,
  };

  factory MonthOption.fromJson(Map<String, dynamic> json) => MonthOption(
    month: json['month'] as int,
    year: json['year'] as int,
    displayName: json['displayName'] as String,
    isSelectable: json['isSelectable'] as bool? ?? true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthOption &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => month.hashCode ^ year.hashCode;

  @override
  String toString() => 'MonthOption($displayName)';
}
