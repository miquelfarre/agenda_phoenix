import 'package:flutter/cupertino.dart';
import '../../models/event.dart';

class EventCardConfig {
  final bool showChevron;
  final bool showActions;
  final bool showInvitationStatus;
  final bool showOwner;
  final bool navigateAfterDelete;
  final bool showNewBadge;
  final bool showDate;

  final String? customTitle;
  final String? customSubtitle;
  final String? customStatus;
  final String? invitationStatus;

  final Widget? customAvatar;
  final Widget? customAction;

  final Function(Event, {bool shouldNavigate})? onDelete;
  final Function(Event)? onEdit;
  final Function(Event)? onInvite;
  final Function(Event, {bool shouldNavigate})? onDeleteSeries;
  final Function(Event)? onEditSeries;
  final Function(int invitationId)? onToggleAcceptance;
  final Function(int invitationId)? onRejectInvitation;

  const EventCardConfig({
    this.showChevron = true,
    this.showActions = true,
    this.showInvitationStatus = false,
    this.showOwner = true,
    this.navigateAfterDelete = false,
    this.showNewBadge = false,
    this.showDate = false,
    this.customTitle,
    this.customSubtitle,
    this.customStatus,
    this.invitationStatus,
    this.customAvatar,
    this.customAction,
    this.onDelete,
    this.onEdit,
    this.onInvite,
    this.onDeleteSeries,
    this.onEditSeries,
    this.onToggleAcceptance,
    this.onRejectInvitation,
  });

  EventCardConfig copyWith({
    bool? showChevron,
    bool? showActions,
    bool? showInvitationStatus,
    bool? showOwner,
    bool? navigateAfterDelete,
    bool? showNewBadge,
    bool? showDate,
    String? customTitle,
    String? customSubtitle,
    String? customStatus,
    String? invitationStatus,
    Widget? customAvatar,
    Widget? customAction,
    Function(Event, {bool shouldNavigate})? onDelete,
    Function(Event)? onEdit,
    Function(Event)? onInvite,
    Function(Event, {bool shouldNavigate})? onDeleteSeries,
    Function(Event)? onEditSeries,
    Function(int invitationId)? onToggleAcceptance,
    Function(int invitationId)? onRejectInvitation,
  }) {
    return EventCardConfig(
      showChevron: showChevron ?? this.showChevron,
      showActions: showActions ?? this.showActions,
      showInvitationStatus: showInvitationStatus ?? this.showInvitationStatus,
      showOwner: showOwner ?? this.showOwner,
      navigateAfterDelete: navigateAfterDelete ?? this.navigateAfterDelete,
      showNewBadge: showNewBadge ?? this.showNewBadge,
      showDate: showDate ?? this.showDate,
      customTitle: customTitle ?? this.customTitle,
      customSubtitle: customSubtitle ?? this.customSubtitle,
      customStatus: customStatus ?? this.customStatus,
      invitationStatus: invitationStatus ?? this.invitationStatus,
      customAvatar: customAvatar ?? this.customAvatar,
      customAction: customAction ?? this.customAction,
      onDelete: onDelete ?? this.onDelete,
      onEdit: onEdit ?? this.onEdit,
      onInvite: onInvite ?? this.onInvite,
      onDeleteSeries: onDeleteSeries ?? this.onDeleteSeries,
      onEditSeries: onEditSeries ?? this.onEditSeries,
      onToggleAcceptance: onToggleAcceptance ?? this.onToggleAcceptance,
      onRejectInvitation: onRejectInvitation ?? this.onRejectInvitation,
    );
  }

  factory EventCardConfig.simple({
    Function(Event)? onEdit,
    Function(Event, {bool shouldNavigate})? onDelete,
  }) {
    return EventCardConfig(
      showChevron: true,
      showActions: true,
      showInvitationStatus: false,
      showOwner: true,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }

  factory EventCardConfig.invitation({required String status}) {
    return EventCardConfig(
      showChevron: true,
      showActions: false,
      showInvitationStatus: true,
      showOwner: true,
      invitationStatus: status,
    );
  }

  factory EventCardConfig.readOnly() {
    return const EventCardConfig(
      showChevron: true,
      showActions: false,
      showInvitationStatus: false,
      showOwner: true,
    );
  }

  factory EventCardConfig.withCustomAction({required Widget action}) {
    return EventCardConfig(
      showChevron: false,
      showActions: false,
      showInvitationStatus: false,
      showOwner: true,
      customAction: action,
    );
  }

  @override
  String toString() {
    return 'EventCardConfig(showActions: $showActions, showChevron: $showChevron, showNewBadge: $showNewBadge, customTitle: $customTitle, customStatus: $customStatus)';
  }
}
