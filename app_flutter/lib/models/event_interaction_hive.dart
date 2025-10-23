import 'package:hive_ce/hive.dart';

part 'event_interaction_hive.g.dart';

@HiveType(typeId: 16)
class EventInteractionHive extends HiveObject {
  @HiveField(0)
  int userId;

  @HiveField(1)
  int eventId;

  @HiveField(2)
  int? inviterId;

  @HiveField(3)
  String? invitationMessage;

  @HiveField(4)
  DateTime? invitedAt;

  @HiveField(5)
  String? participationStatus;

  @HiveField(6)
  DateTime? participationDecidedAt;

  @HiveField(7)
  String? decisionMessage;

  @HiveField(8)
  DateTime? postponeUntil;

  @HiveField(20)
  bool isAttending;

  @HiveField(21)
  bool isEventAdmin;

  @HiveField(9)
  bool viewed;

  @HiveField(10)
  DateTime? firstViewedAt;

  @HiveField(11)
  DateTime? lastViewedAt;

  @HiveField(12)
  String? personalNote;

  @HiveField(13)
  DateTime? noteUpdatedAt;

  @HiveField(14)
  bool favorited;

  @HiveField(15)
  DateTime? favoritedAt;

  @HiveField(16)
  bool hidden;

  @HiveField(17)
  DateTime? hiddenAt;

  @HiveField(18)
  DateTime createdAt;

  @HiveField(19)
  DateTime updatedAt;

  EventInteractionHive({
    required this.userId,
    required this.eventId,
    this.inviterId,
    this.invitationMessage,
    this.invitedAt,
    this.participationStatus,
    this.participationDecidedAt,
    this.decisionMessage,
    this.postponeUntil,
    this.isAttending = false,
    this.isEventAdmin = false,
    this.viewed = false,
    this.firstViewedAt,
    this.lastViewedAt,
    this.personalNote,
    this.noteUpdatedAt,
    this.favorited = false,
    this.favoritedAt,
    this.hidden = false,
    this.hiddenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get hiveKey => '${userId}_$eventId';

  static String createHiveKey(int userId, int eventId) => '${userId}_$eventId';

  factory EventInteractionHive.fromDomain(dynamic interaction) {
    return EventInteractionHive(
      userId: interaction.userId,
      eventId: interaction.eventId,
      inviterId: interaction.inviterId,
      invitationMessage: interaction.invitationMessage,
      invitedAt: interaction.invitedAt,
      participationStatus: interaction.participationStatus,
      participationDecidedAt: interaction.participationDecidedAt,
      decisionMessage: interaction.decisionMessage,
      postponeUntil: interaction.postponeUntil,
      isAttending: interaction.isAttending,
      isEventAdmin: interaction.isEventAdmin,
      viewed: interaction.viewed,
      firstViewedAt: interaction.firstViewedAt,
      lastViewedAt: interaction.lastViewedAt,
      personalNote: interaction.personalNote,
      noteUpdatedAt: interaction.noteUpdatedAt,
      favorited: interaction.favorited,
      favoritedAt: interaction.favoritedAt,
      hidden: interaction.hidden,
      hiddenAt: interaction.hiddenAt,
      createdAt: interaction.createdAt,
      updatedAt: interaction.updatedAt,
    );
  }

  factory EventInteractionHive.fromJson(Map<String, dynamic> json) {
    return EventInteractionHive(
      userId: json['user_id'],
      eventId: json['event_id'],
      inviterId: json['inviter_id'],
      invitationMessage: json['invitation_message'],
      invitedAt: json['invited_at'] != null
          ? DateTime.parse(json['invited_at'])
          : null,
      participationStatus: json['participation_status'],
      participationDecidedAt: json['participation_decided_at'] != null
          ? DateTime.parse(json['participation_decided_at'])
          : null,
      decisionMessage: json['decision_message'],
      postponeUntil: json['postpone_until'] != null
          ? DateTime.parse(json['postpone_until'])
          : null,
      isAttending: json['is_attending'] ?? false,
      isEventAdmin: json['is_event_admin'] ?? false,
      viewed: json['viewed'] ?? false,
      firstViewedAt: json['first_viewed_at'] != null
          ? DateTime.parse(json['first_viewed_at'])
          : null,
      lastViewedAt: json['last_viewed_at'] != null
          ? DateTime.parse(json['last_viewed_at'])
          : null,
      personalNote: json['personal_note'],
      noteUpdatedAt: json['note_updated_at'] != null
          ? DateTime.parse(json['note_updated_at'])
          : null,
      favorited: json['favorited'] ?? false,
      favoritedAt: json['favorited_at'] != null
          ? DateTime.parse(json['favorited_at'])
          : null,
      hidden: json['hidden'] ?? false,
      hiddenAt: json['hidden_at'] != null
          ? DateTime.parse(json['hidden_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'event_id': eventId,
      'inviter_id': inviterId,
      'invitation_message': invitationMessage,
      'invited_at': invitedAt?.toIso8601String(),
      'participation_status': participationStatus,
      'participation_decided_at': participationDecidedAt?.toIso8601String(),
      'decision_message': decisionMessage,
      'postpone_until': postponeUntil?.toIso8601String(),
      'is_attending': isAttending,
      'is_event_admin': isEventAdmin,
      'viewed': viewed,
      'first_viewed_at': firstViewedAt?.toIso8601String(),
      'last_viewed_at': lastViewedAt?.toIso8601String(),
      'personal_note': personalNote,
      'note_updated_at': noteUpdatedAt?.toIso8601String(),
      'favorited': favorited,
      'favorited_at': favoritedAt?.toIso8601String(),
      'hidden': hidden,
      'hidden_at': hiddenAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
