import 'package:flutter/foundation.dart';
import '../utils/datetime_utils.dart';

@immutable
class BirthdayEvent {
  final String id;
  final String userId;
  final String celebrantName;
  final DateTime birthDate;
  final bool recurring;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BirthdayEvent({
    required this.id,
    required this.userId,
    required this.celebrantName,
    required this.birthDate,
    this.recurring = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BirthdayEvent.fromJson(Map<String, dynamic> json) {
    return BirthdayEvent(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      celebrantName: json['celebrant_name'] ?? '',
      birthDate: DateTimeUtils.parseAndNormalize(json['birth_date']),
      recurring: json['recurring'] ?? true,
      notes: json['notes'],
      createdAt: DateTimeUtils.parseAndNormalize(json['created_at']),
      updatedAt: DateTimeUtils.parseAndNormalize(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'celebrant_name': celebrantName,
      'birth_date': DateTimeUtils.toNormalizedIso8601String(birthDate),
      'recurring': recurring,
      'notes': notes,
      'created_at': DateTimeUtils.toNormalizedIso8601String(createdAt),
      'updated_at': DateTimeUtils.toNormalizedIso8601String(updatedAt),
    };
  }

  BirthdayEvent copyWith({
    String? id,
    String? userId,
    String? celebrantName,
    DateTime? birthDate,
    bool? recurring,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BirthdayEvent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      celebrantName: celebrantName ?? this.celebrantName,
      birthDate: birthDate ?? this.birthDate,
      recurring: recurring ?? this.recurring,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BirthdayEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BirthdayEvent(id: $id, celebrantName: $celebrantName, birthDate: $birthDate)';
  }

  int calculateAge([DateTime? onDate]) {
    final date = onDate ?? DateTime.now();
    int age = date.year - birthDate.year;

    if (date.month < birthDate.month ||
        (date.month == birthDate.month && date.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  DateTime getNextBirthday([DateTime? fromDate]) {
    final from = fromDate ?? DateTime.now();
    int year = from.year;

    DateTime nextBirthday = DateTime(year, birthDate.month, birthDate.day);

    if (nextBirthday.isBefore(from)) {
      nextBirthday = DateTime(year + 1, birthDate.month, birthDate.day);
    }

    return nextBirthday;
  }

  DateTime getMostRecentBirthday([DateTime? beforeDate]) {
    final before = beforeDate ?? DateTime.now();
    int year = before.year;

    DateTime recentBirthday = DateTime(year, birthDate.month, birthDate.day);

    if (recentBirthday.isAfter(before)) {
      recentBirthday = DateTime(year - 1, birthDate.month, birthDate.day);
    }

    return recentBirthday;
  }

  bool get isBirthdayToday {
    final today = DateTime.now();
    return today.month == birthDate.month && today.day == birthDate.day;
  }

  bool get isBirthdayThisWeek {
    final today = DateTime.now();
    final weekFromNow = today.add(const Duration(days: 7));
    final nextBirthday = getNextBirthday(today);

    return nextBirthday.isBefore(weekFromNow) ||
        nextBirthday.isAtSameMomentAs(weekFromNow);
  }

  int get daysUntilBirthday {
    final today = DateTime.now();
    final nextBirthday = getNextBirthday(today);
    return nextBirthday.difference(today).inDays;
  }

  bool get isValidName =>
      celebrantName.trim().isNotEmpty && celebrantName.length <= 100;
  bool get isValidBirthDate => birthDate.isBefore(DateTime.now());
  bool get isValid => isValidName && isValidBirthDate;

  bool isCreatedBy(String userId) => this.userId == userId;
  String get displayAge => '${calculateAge()} years old';
  String get shortDisplayAge => '${calculateAge()}';
}
