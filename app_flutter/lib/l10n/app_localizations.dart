import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  String get appTitle;

  String get appName;

  String get untitledEvent;

  String get untitled;

  String get guestUser;

  String get anonymousUser;

  String get manageBlockedUsersDescription;

  String get userNotLoggedIn;

  String get failedToLoadEvents;

  String get failedToCreateEvent;

  String get cannotUpdateEventWithoutId;

  String get searchGroups;

  String get createGroup;

  String get errorLoadingGroups;

  String get errorLoadingUsers;

  String get errorLoadingContacts;

  String get retry;

  String get noGroupsMessage;

  String get noGroupsSearchMessage;

  String get failedToUpdateEvent;

  String get failedToDeleteEvent;

  String get failedToSavePersonalNote;

  String get failedToDeletePersonalNote;

  String get save;

  String get cancel;

  String get delete;

  String get edit;

  String get create;

  String get update;

  String get add;

  String get remove;

  String get close;

  String get done;

  String get next;

  String get back;

  String get refresh;

  String get load;

  String get send;

  String get share;

  String get copy;

  String get paste;

  String get select;

  String get selectAll;

  String get clear;

  String get reset;

  String get confirm;

  String get accept;

  String get reject;

  String get approve;

  String get decline;

  String get cancelAttendance;

  String get submit;

  String get continueAction;

  String get skip;

  String get finish;

  String get start;

  String get stop;

  String get pause;

  String get resume;

  String get enable;

  String get disable;

  String get show;

  String get hide;

  String get view;

  String get preview;

  String get download;

  String get upload;

  String get loading;

  String get loadingData;

  String get saving;

  String get updating;

  String get deleting;

  String get sending;

  String get connecting;

  String get syncing;

  String get processing;

  String get searching;

  String get creating;

  String get success;

  String get error;

  String get warning;

  String get info;

  String get appErrorLoadingData;

  String get noData;

  String get noResults;

  String get noInternetConnection;

  String get connectionError;

  String get unexpectedError;

  String get tryAgain;

  String get somethingWentWrong;

  String get startingEventyPop;

  String get initializingOfflineSystem;

  String get loadingConfiguration;

  String get verifyingAccess;

  String get testEventCreated;

  String testEventTitle(String timestamp);

  String get testEventDescription;

  String get syncCompleted;

  String get localizationNotAvailable;

  String get home;

  String get events;

  String get groups;

  String get profile;

  String get settings;

  String get notifications;

  String get search;

  String get help;

  String get about;

  String get logout;

  String get login;

  String get register;

  String get confirmDelete;

  String get confirmDeleteTitle;

  String get confirmLogout;

  String get confirmLogoutTitle;

  String get unsavedChanges;

  String get unsavedChangesMessage;

  String get confirmLeave;

  String get event;

  String get myEvents;

  String get createEvent;

  String get editEvent;

  String get deleteEvent;

  String get removeFromMyList;

  String get notifyCancellation;

  String get sendCancellationNotification;

  String get sendNotification;

  String get customMessageOptional;

  String get writeAdditionalMessage;

  String get unknownUser;

  String get eventTitle;

  String get eventDescription;

  String get eventDate;

  String get eventTime;

  String get eventLocation;

  String get inviteToEvent;

  String get inviteUsers;

  String get eventCreated;

  String get eventUpdated;

  String get eventDeleted;

  String get eventRemoved;

  String get seriesDeleted;

  String get seriesEditNotAvailable;

  String get noEvents;

  String get upcomingEvents;

  String get pastEvents;

  String get eventDetails;

  String get joinEvent;

  String get acceptEventButRejectInvitation;

  String get acceptEventButRejectInvitationAck;

  String get leaveEvent;

  String get eventMembers;

  String get eventInvitations;

  String get attendees;

  String get saveChangesOffline;

  String get saveEventOffline;

  String get updateEvent;

  String get createRecurringEventQuestion;

  String get offlineSaveMessage;

  String get onlineSaveMessage;

  String get offlineEventCreationMessage;

  String get notifyChanges;

  String get sendChangesNotificationMessage;

  String get utc;

  String get worldFlag;

  String get group;

  String get groupInitialFallback;

  String get avatarUnknownInitial;

  String get myGroups;

  String get editGroup;

  String get deleteGroup;

  String get groupName;

  String get groupDescription;

  String get inviteToGroup;

  String get groupCreated;

  String get groupUpdated;

  String get groupDeleted;

  String get noGroups;

  String get groupMembers;

  String get groupAdmin;

  String get makeAdmin;

  String get removeAdmin;

  String confirmMakeAdmin(String displayName);

  String confirmRemoveAdmin(String displayName);

  String memberMadeAdmin(String displayName);

  String memberRemovedAdmin(String displayName);

  String get envDev;

  String get envProd;

  String get deleteFromGroup;

  String get noPermissionsToManageMember;

  String confirmRemoveFromGroup(String displayName);

  String memberRemovedFromGroup(String displayName);

  String get joinGroup;

  String get leaveGroup;

  String get groupInvitations;

  String get user;

  String get users;

  String get myProfile;

  String get editProfile;

  String get fullName;

  String get instagramName;

  String get email;

  String get phone;

  String get bio;

  String get contacts;

  String get searchUsers;

  String get noUsers;

  String get userProfile;

  String get followers;

  String get following;

  String get follow;

  String get unfollow;

  String get block;

  String get unblock;

  String get report;

  String get invitation;

  String get invitations;

  String get sendInvitation;

  String get acceptInvitation;

  String get rejectInvitation;

  String get cancelInvitation;

  String get invitationSent;

  String errorInvitingUser(String displayName);

  String errorInvitingUserWithError(String displayName, String error);

  String errorInvitingGroup(String groupName);

  String errorInvitingGroupWithError(String groupName, String error);

  String invitationsSentWithErrors(int successful, int errors);

  String get invitationAccepted;

  String get invitationRejected;

  String get invitationCancelled;

  String get pendingInvitations;

  String get sentInvitations;

  String get receivedInvitations;

  String get noInvitations;

  String get invitationMessage;

  String get invitationDecisionTitle;

  String get optionalMessage;

  String get notifyInviter;

  String get postponeDecision;

  String get decideInvitation;

  String get decideNow;

  String postponedUntil(String date);

  String confirmInviteUser(String displayName, String eventTitle);

  String confirmCancelInvitation(String eventTitle);

  String get notification;

  String get noNotifications;

  String get markAsRead;

  String get markAllAsRead;

  String get deleteNotification;

  String get clearNotifications;

  String get notificationSettings;

  String get enableNotifications;

  String get disableNotifications;

  String get pushNotifications;

  String get emailNotifications;

  String get eventChangeNotification;

  String get notificationMessage;

  String get notificationSent;

  String get signIn;

  String get signOut;

  String get signUp;

  String get password;

  String get confirmPassword;

  String get forgotPassword;

  String get resetPassword;

  String get changePassword;

  String get currentPassword;

  String get newPassword;

  String get loginSuccess;

  String get logoutSuccess;

  String get registerSuccess;

  String get invalidCredentials;

  String get accountNotFound;

  String get emailInUse;

  String get weakPassword;

  String fieldRequired(String fieldName);

  String get invalidEmail;

  String get invalidPhone;

  String get invalidInstagramName;

  String passwordTooShort(int minLength);

  String get passwordsDoNotMatch;

  String textTooShort(int minLength);

  String textTooLong(int maxLength);

  String get eventTitleRequired;

  String get groupNameRequired;

  String get fullNameRequired;

  String get emailRequired;

  String get passwordRequired;

  String get messageRequired;

  String get dateTooFarInFuture;

  String get offline;

  String get online;

  String get syncPending;

  String get syncComplete;

  String get syncFailed;

  String get offlineMode;

  String get noConnection;

  String get reconnecting;

  String get pendingChanges;

  String get syncWhenOnline;

  String get dataWillSyncSoon;

  String get today;

  String get yesterday;

  String get tomorrow;

  String get now;

  String get soon;

  String get recently;

  String get thisWeek;

  String get thisMonth;

  String get thisYear;

  String get lastWeek;

  String get lastMonth;

  String get lastYear;

  String get nextWeek;

  String get nextMonth;

  String get nextYear;

  String get selectDate;

  String get selectTime;

  String get selectDateTime;

  String get startDate;

  String get endDate;

  String get startTime;

  String get endTime;

  String get duration;

  String get recurring;

  String get oneTime;

  String get daily;

  String get weekly;

  String get monthly;

  String get yearly;

  String patternsConfigured(int count);

  String get noEventsMessage;

  String get noUsersMessage;

  String get noContactsMessage;

  String get noNotificationsMessage;

  String get noInvitationsMessage;

  String get noSearchResults;

  String get emptyEventsList;

  String get emptyGroupsList;

  String get createFirstEvent;

  String get createFirstGroup;

  String get inviteFirstUser;

  String get options;

  String get debugAmbiguousReconciliations;

  String get preferences;

  String get account;

  String get privacy;

  String get security;

  String get language;

  String get theme;

  String get darkMode;

  String get lightMode;

  String get systemTheme;

  String get version;

  String get buildNumber;

  String get termsOfService;

  String get privacyPolicy;

  String get contactUs;

  String get feedback;

  String get rateApp;

  String get shareApp;

  String get countryAndTimezone;

  String get timezone;

  String get currentTimezone;

  String get selectTimezone;

  String get selectCountryTimezone;

  String get defaultSettingsForNewEvents;

  String get connectionStatus;

  String get subscription;

  String get subscriptions;

  String get peopleAndGroups;

  String get findYourFriends;

  String get permissionsNeeded;

  String get contactsPermissionMessage;

  String get yourContactsStayPrivate;

  String get onlyShowMutualFriends;

  String get goToSettings;

  String get contactsPermissionSettingsMessage;

  String get notNow;

  String get allowAccess;

  String get invite;

  String confirmDeleteEvent(String eventTitle);

  String get eventDeletedSuccessfully;

  String get deleteRecurringEvent;

  String deleteRecurringEventQuestion(String eventTitle);

  String get deleteOnlyThisInstance;

  String get deleteOnlyThisInstanceSubtitle;

  String get deleteEntireSeries;

  String get deleteEntireSeriesSubtitle;

  String confirmDeleteInstance(String eventTitle);

  String get deleteInstance;

  String get confirmDeleteSeries;

  String confirmDeleteSeriesMessage(String seriesTitle);

  String get deleteCompleteSeries;

  String get editRecurringEvent;

  String editRecurringEventQuestion(String eventTitle);

  String get editOnlyThisInstance;

  String get editOnlyThisInstanceSubtitle;

  String get editEntireSeries;

  String get editEntireSeriesSubtitle;

  String get phoneHintExample;

  String get smsCodeHintExample;

  String errorCompletingRegistrationWithMessage(String errorMessage);

  String get usePhysicalIosDevice;

  String get useAndroidEmulator;

  String get useWebVersion;

  String get invalidEventId;

  String invitationSentTo(String displayName);

  String get errorSendingInvitation;

  String get blockUser;

  String get unblockUser;

  String confirmBlockUser(String displayName);

  String confirmUnblockUser(String displayName);

  String get userBlockedSuccessfully;

  String get userUnblockedSuccessfully;

  String get errorBlockingUser;

  String get errorUnblockingUser;

  String errorBlockingUserDetail(String errorMessage);

  String invitationsSentToUser(String displayName);

  String get eventNotAvailable;

  String get blockingUser;

  String get blockedUsers;

  String get noBlockedUsers;

  String get noBlockedUsersDescription;

  String eventHidden(String eventTitle);

  String get no;

  String get yesCancel;

  String get inviteToOtherEvents;

  String get accessDeniedTitle;

  String get accessDeniedMessagePrimary;

  String get accessDeniedMessageSecondary;

  String get contactAdminIfError;

  String get invitationCancelledSuccessfully;

  String errorCancellingInvitation(String errorMessage);

  String get eventDescriptionRequired;

  String get groupInfo;

  String get descriptionOptional;

  String get addEventDetailsHint;

  String get addMembers;

  String get searchFriends;

  String get noFriendsToAdd;

  String get noFriendsFoundWithName;

  String get addAtLeastOnePattern;

  String get startDateBeforeEndDate;

  String get errorCreatingEvent;

  String get createRecurringEvent;

  String get repetitionPatterns;

  String get addSchedules;

  String get noPatternsConfigured;

  String get editPattern;

  String get newPattern;

  String get dayOfWeek;

  String get hourLabel;

  String get minutes;

  String get organizer;

  String get noDescription;

  String upcomingEventsOf(String eventName);

  String get noUpcomingEventsScheduled;

  String get invitedPeople;

  String get noInvitedPeople;

  String get invitationToEvent;

  String get noUsersOrGroupsAvailable;

  String get noGroupsLeftToInvite;

  String get noUsersLeftToInvite;

  String get unnamedGroup;

  String get errorInviting;

  String get allGroupMembersAlreadyInvited;

  String get alreadyInvited;

  String invitationsSentSuccessfully(int destinations);

  String get invitationsSent;

  String get errors;

  String get errorSendingInvitations;

  String get sendInvitations;

  String get loginWithPhone;

  String get sendSmsCode;

  String codeSentTo(String phoneNumber);

  String get smsCode;

  String get verifyCode;

  String get changeNumber;

  String get automaticVerificationError;

  String get verificationError;

  String get firebasePhoneAuthSimulatorError;

  String get tooManyRequests;

  String get operationNotAllowed;

  String smsCodeSentTo(String phoneNumber);

  String get errorSendingCode;

  String get incorrectCode;

  String get invalidVerificationCode;

  String get sessionExpired;

  String get errorVerifyingCode;

  String get couldNotGetFirebaseToken;

  String get iosSimulatorDetected;

  String get firebasePhoneAuthLimitationMessage;

  String get testPhoneAuthInstructions;

  String get understood;

  String get errorLoadingNotifications;

  String get errorAcceptingInvitation;

  String get errorRejectingInvitation;

  String get syncingContacts;

  String get contactsPermissionRequired;

  String get errorLoadingFriends;

  String errorLoadingFriendsWithError(String error);

  String get contactsPermissionInstructions;

  String get requestPermissions;

  String get openSettings;

  String get resetPreferences;

  String get resetContactsPermissions;

  String get openAppSettings;

  String get syncInfoMessage;

  String get settingsUpdated;

  String get errorUpdatingSettings;

  String errorUpdatingContacts(String error);

  String get creatorLabel;

  String adminsList(String list);

  String get noAdmins;

  String membersAndAdmins(int count, String admins);

  String get pendingStatus;

  String get acceptedStatus;

  String get rejectedStatus;

  String get recurringShort;

  String get noFriendsYet;

  String get noContactsAvailable;

  String get notInAnyGroup;

  String get groupsWillAppearHere;

  String get startingAutomaticSync;

  String get loadingLocalData;

  String get verifyingSync;

  String get checkingContactsPermissions;

  String get dataUpdated;

  String get readyToUse;

  String get errorInitializingApp;

  String get retrying;

  String get yourEventsAlwaysWithYou;

  String get oopsSomethingWentWrong;

  String get pleaseWait;

  String get mySubscriptions;

  String get searchPublicUsers;

  String get searchEvents;

  String get filters;

  String get clearFilters;

  String get allEvents;

  String get myEventsFilter;

  String get subscribedEvents;

  String get invitationEvents;

  String get noEventsForFilter;

  String get noMyEvents;

  String get noSubscribedEvents;

  String get noInvitationEvents;

  String get searchSubscriptions;

  String get dateRange;

  String get categories;

  String get eventTypes;

  String get showRecurringEvents;

  String get showOwnedEvents;

  String get showInvitedEvents;

  String get from;

  String get until;

  String get noEventsFound;

  String get personalNote;

  String get addPersonalNote;

  String get addPersonalNoteHint;

  String get personalNoteUpdated;

  String get personalNoteDeleted;

  String get editPersonalNote;

  String get errorSavingNote;

  String get deleteNote;

  String get deleteNoteConfirmation;

  String get privateNoteHint;

  String get noUsersFound;

  String get publicUser;

  String get noSubscriptions;

  String get errorLoadingSubscriptions;

  String get unsubscribedSuccessfully;

  String get subscribedSuccessfully;

  String get errorRemovingSubscription;

  String subscribedToUser(String displayName);

  String get monday;

  String get tuesday;

  String get wednesday;

  String get thursday;

  String get friday;

  String get saturday;

  String get sunday;

  String get january;

  String get february;

  String get march;

  String get april;

  String get may;

  String get june;

  String get july;

  String get august;

  String get september;

  String get october;

  String get november;

  String get december;

  String get recurringEvent;

  String get startDateTime;

  String get endDateTime;

  String get city;

  String get cityHint;

  String get noLocationSet;

  String get recurrencePatterns;

  String get addPattern;

  String get addAnotherPattern;

  String get tapAddPatternToStart;

  String get selectDayOfWeek;

  String get noPatternsAdded;

  String get addFirstPattern;

  String get onePatternAdded;

  String multiplePatternsAdded(int count);

  String everyNDays(int count);

  String everyNWeeks(int count);

  String everyNMonths(int count);

  String everyNYears(int count);

  String endsOn(String date);

  String dayOfMonth(int day);

  String get noAdditionalSettings;

  String get frequency;

  String get interval;

  String get daysOfWeek;

  String get selectDay;

  String get selectMonth;

  String get selectEndDate;

  String get monthOfYear;

  String get optional;

  String get time;

  String get noRecurrencePatterns;

  String get deletePattern;

  String get confirmDeletePattern;

  String get recurringEventHelperText;

  String get endDateRequired;

  String get atLeastOnePatternRequired;

  String get eventCreatedSuccessfully;

  String get eventUpdatedSuccessfully;

  String get eventCreatedOffline;

  String get eventUpdatedOffline;

  String eventChangedNotification(String eventTitle);

  String get errorSendingNotification;

  String get offlineStatus;

  String get onlineStatus;

  String get syncingData;

  String syncingPendingOperations(int count);

  String get noDaysSelected;

  String get allDaysSelected;

  String get weekdaysSelected;

  String get weekendsSelected;

  String get createNormalEvent;

  String selectTimezoneForCountry(String country);

  String get searchCity;

  String get citySearchPlaceholder;

  String get offlineTestDashboard;

  String get pendingOperationsLabel;

  String get totalLabel;

  String get eventsLabel;

  String get createLabel;

  String get updateLabel;

  String get deleteLabel;

  String get connectionLabel;

  String membersLabel(int count);

  String get groupMembersHeading;

  String get noMembersInGroup;

  String get testCreate;

  String get forceSync;

  String get checkNet;

  String get eventWithoutTitle;

  String get invitationFrom;

  String get notificationDeleted;

  String errorDeletingNotification(String error);

  String get specificTimezone;

  String get hourSuffix;

  String offsetDotTimezone(String offset, String timezone);

  String timezoneWithOffsetParen(String timezone, String offset);

  String countryCodeDotTimezone(String countryCode, String timezone);

  String get dotSeparator;

  String get minuteSuffix;

  String get colon;

  String errorCreatingTestEvent(String error);

  String syncFailedWithError(String error);

  String get statusLabel;

  String errorDeletingGroup(String error);

  String get networkErrorDuringSync;

  String get cannotSyncWhileOffline;

  String get timezoneServiceNotInitialized;

  String get notificationServiceNotInitialized;

  String get pendingInvitationBanner;

  String get viewOrganizerEvents;

  String get viewEventSeries;

  String get andWord;

  String get everyWord;

  String get atWord;

  String get errorLoadingInvitations;

  String get errorSendingGroupInvitation;

  String get invitationNotFound;

  String get unknownError;

  String get ok;

  String get validationFailed;

  String get saveFailed;

  String get noInvitationsSent;

  String get subscribeToOwner;

  String get yourResponse;

  String get status;

  String get eventManagement;

  String get successfully;

  String get eventActions;

  String get eventCancellation;

  String get cancellationMessage;

  String get cancelEventWithNotification;

  String get eventOptions;

  String get cancelEvent;

  String get confirmCancelEvent;

  String get doNotCancel;

  String get eventCancelledSuccessfully;

  String get failedToCancelEvent;

  String get removeFromList;

  String get confirmRemoveFromList;

  String get eventRemovedFromList;

  String get failedToRemoveFromList;

  String get invitationPostponed;

  String get invitationPending;

  String get acceptedEventButDeclinedInvitation;

  String confirmDeleteGroup(String groupName);

  String get failedToDeleteGroup;

  String get resolveAmbiguousReconciliation;

  String get confirmResolve;

  String get payload;

  String get ambiguousReconciliations;

  String get availableInDebugBuildsOnly;

  String get noAmbiguousReconciliations;

  String get deleteAmbiguousEntry;

  String get export;

  String resolveOptimisticToServerId(String optimisticId, String serverId);

  String get contactSyncInProgress;

  String get contactsPermissionNotGranted;

  String get failedToLoadInvitations;

  String get failedToSendInvitation;

  String get failedToSendInvitations;

  String get failedToSendGroupInvitation;

  String get failedToAcceptInvitation;

  String get failedToRejectInvitation;

  String get failedToCancelInvitation;

  String get titleIsRequired;

  String get endDateMustBeAfterStartDate;

  String get failedToSaveEvent;

  String get failedToLoadEventData;

  String get noInvitationFound;

  String get failedToSubmitDecision;

  String get onlyEventOwnerCanEdit;

  String get onlyEventOwnerCanDelete;

  String get onlyEventOwnerCanInviteUsers;

  String get failedToToggleSubscription;

  String get failedToRefreshContacts;

  String get failedToLoadGroups;

  String get userNotAuthenticated;

  String get failedToCreateGroup;

  String get failedToAddMember;

  String get failedToRemoveMember;

  String get failedToLeaveGroup;

  String get failedToGrantAdminPermission;

  String get failedToRemoveAdminPermission;

  String get failedToCreateContact;

  String get failedToUpdateContact;

  String get failedToDeleteContact;

  String get failedToReadDeviceContacts;

  String get errorFindingUsersByPhones;

  String get failedToBlockUser;

  String get failedToUnblockUser;

  String get failedToLoadBlockedUsers;

  String get couldNotCreateGroup;

  String get failedToFetchEvents;

  String get failedToFetchSubscriptions;

  String get failedToFetchNotifications;

  String get failedToFetchGroups;

  String get failedToFetchContacts;

  String get failedToFetchEventsHash;

  String get failedToFetchGroupsHash;

  String get failedToFetchContactsHash;

  String get failedToFetchInvitationsHash;

  String get failedToFetchSubscriptionsHash;

  String get failedToFetchNotificationsHash;

  String get failedToLeaveEvent;

  String get failedToDeleteRecurringSeries;

  String get failedToAddMemberToGroup;

  String get failedToRemoveMemberFromGroup;

  String get failedToAcceptNotification;

  String get failedToRejectNotification;

  String get failedToMarkNotificationAsSeen;

  String get failedToCreateSubscription;

  String get failedToDeleteSubscription;

  String get failedToFetchEventInvitations;

  String get failedToFetchUserGroups;

  String get failedToFetchUsers;

  String get failedToSearchPublicUsers;

  String get subscriptionIdCannotBeNull;

  String get userIdCannotBeNull;

  String get failedToCreateUpdateUser;

  String get failedToLoadCurrentUser;

  String get noCurrentUserToUpdate;

  String get failedToUpdateProfile;

  String get failedToUpdateFCMToken;

  String get firebaseUserHasNoPhoneNumber;

  String eventsBy(String name);

  String get publicOrganizerEvents;

  String get errorLoadingEvents;

  String get changeDecision;

  String get changeInvitationDecision;

  String get selectNewDecision;

  String get errorProcessingInvitation;

  String get newLabel;

  String get communities;

  String get calendar;

  String get calendars;

  String get myCalendars;

  String get subscribedCalendars;

  String get publicCalendars;

  String get createCalendar;

  String get editCalendar;

  String get deleteCalendar;

  String get calendarName;

  String get calendarDescription;

  String get calendarColor;

  String get deleteAssociatedEvents;

  String get subscribeToCalendar;

  String get unsubscribeFromCalendar;

  String get searchPublicCalendars;

  String get noCalendarsYet;

  String get associateWithCalendar;

  String get isBirthday;

  String get birthdayIcon;

  String get selectCalendar;

  String get invitationStatus;

  String get changeInvitationStatus;

  String get attendIndependently;

  String get searchCalendars;

  String get searchBirthdays;

  String get noCalendarsFound;

  String get noCalendars;

  String get noBirthdaysFound;

  String get noBirthdays;

  String get birthdays;

  String get birthday;

  String get defaultCalendar;

  String get errorLoadingData;

  String inDays(int days);

  String get inOneWeek;

  String inWeeks(int weeks);

  String get inOneMonth;

  String inMonths(int months);

  String get inOneYear;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
