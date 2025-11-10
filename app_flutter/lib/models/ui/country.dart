class Country {
  final String code;
  final String name;
  final String nameEn;
  final String flag;
  final String dialCode;
  final List<String> timezones;
  final String primaryTimezone;

  const Country({
    required this.code,
    required this.name,
    required this.nameEn,
    required this.flag,
    required this.dialCode,
    required this.timezones,
    required this.primaryTimezone,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      code: json['code'],
      name: json['name'],
      nameEn: json['nameEn'],
      flag: json['flag'],
      dialCode: json['dialCode'] ?? '',
      timezones: List<String>.from(json['timezones']),
      primaryTimezone: json['primaryTimezone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'nameEn': nameEn,
      'flag': flag,
      'dialCode': dialCode,
      'timezones': timezones,
      'primaryTimezone': primaryTimezone,
    };
  }

  @override
  String toString() {
    return '$flag $name';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Country && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}
