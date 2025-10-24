import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// Simple greeting without name
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get hello;

  /// Personalized greeting with user name
  ///
  /// In en, this message translates to:
  /// **'Hello {name}!'**
  String helloWithName(String name);

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'EventyPop'**
  String get appTitle;

  /// The name of the application
  ///
  /// In en, this message translates to:
  /// **'EventyPop'**
  String get appName;

  /// Default title for events without a name
  ///
  /// In en, this message translates to:
  /// **'Untitled Event'**
  String get untitledEvent;

  /// Generic text for items without title
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// Default name for guest users
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestUser;

  /// Default name for anonymous users
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymousUser;

  /// Description for blocked users management
  ///
  /// In en, this message translates to:
  /// **'Manage users you have blocked from contacting you'**
  String get manageBlockedUsersDescription;

  /// Error when user is not authenticated
  ///
  /// In en, this message translates to:
  /// **'User not logged in'**
  String get userNotLoggedIn;

  /// Generic error when loading events
  ///
  /// In en, this message translates to:
  /// **'Failed to load events'**
  String get failedToLoadEvents;

  /// Error when creating a new event
  ///
  /// In en, this message translates to:
  /// **'Failed to create event'**
  String get failedToCreateEvent;

  /// Validation error when updating event
  ///
  /// In en, this message translates to:
  /// **'Cannot update event without ID'**
  String get cannotUpdateEventWithoutId;

  /// Placeholder text for group search field
  ///
  /// In en, this message translates to:
  /// **'Search groups...'**
  String get searchGroups;

  /// Button text to create a new group
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// Error message when groups fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading groups.'**
  String get errorLoadingGroups;

  /// Error message when users fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading users'**
  String get errorLoadingUsers;

  /// Error message when contacts fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading contacts'**
  String get errorLoadingContacts;

  /// Button text to retry an action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Empty state message when user has no groups
  ///
  /// In en, this message translates to:
  /// **'No groups available for invitation'**
  String get noGroupsMessage;

  /// Empty state message when group search returns no results
  ///
  /// In en, this message translates to:
  /// **'No Results\nNo groups match your search'**
  String get noGroupsSearchMessage;

  /// Error when updating existing event
  ///
  /// In en, this message translates to:
  /// **'Failed to update event'**
  String get failedToUpdateEvent;

  /// Error when deleting event
  ///
  /// In en, this message translates to:
  /// **'Failed to delete event'**
  String get failedToDeleteEvent;

  /// Error when saving event personal note
  ///
  /// In en, this message translates to:
  /// **'Failed to save personal note'**
  String get failedToSavePersonalNote;

  /// Error when deleting event personal note
  ///
  /// In en, this message translates to:
  /// **'Failed to delete personal note'**
  String get failedToDeletePersonalNote;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @load.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get load;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @cancelAttendance.
  ///
  /// In en, this message translates to:
  /// **'Cancel Attendance'**
  String get cancelAttendance;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// No description provided for @loadingForm.
  ///
  /// In en, this message translates to:
  /// **'Loading form...'**
  String get loadingForm;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @deleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get deleting;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// Status for accepted invitations
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// Status for declined invitations
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// Status for postponed invitations
  ///
  /// In en, this message translates to:
  /// **'Postponed'**
  String get postponed;

  /// Status for pending invitations or actions
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @appErrorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get appErrorLoadingData;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noData;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// Empty state when no calendars exist
  ///
  /// In en, this message translates to:
  /// **'No calendars available'**
  String get noCalendarsAvailable;

  /// Empty state when no time options exist
  ///
  /// In en, this message translates to:
  /// **'No time options available'**
  String get noTimeOptionsAvailable;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// Connection error message with action
  ///
  /// In en, this message translates to:
  /// **'Connection error. Check your internet.'**
  String get connectionErrorCheckInternet;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error occurred'**
  String get unexpectedError;

  /// Timeout error message
  ///
  /// In en, this message translates to:
  /// **'Operation took too long. Please try again.'**
  String get operationTookTooLong;

  /// Data format error message
  ///
  /// In en, this message translates to:
  /// **'Data format error. Please try again.'**
  String get dataFormatError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @anErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get anErrorOccurred;

  /// No description provided for @pleaseCorrectErrors.
  ///
  /// In en, this message translates to:
  /// **'Please correct the errors below'**
  String get pleaseCorrectErrors;

  /// No description provided for @failedToSubmitForm.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit form'**
  String get failedToSubmitForm;

  /// No description provided for @formSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Form submitted successfully'**
  String get formSubmittedSuccessfully;

  /// No description provided for @failedToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh'**
  String get failedToRefresh;

  /// No description provided for @startingEventyPop.
  ///
  /// In en, this message translates to:
  /// **'Starting EventyPop...'**
  String get startingEventyPop;

  /// No description provided for @initializingOfflineSystem.
  ///
  /// In en, this message translates to:
  /// **'Initializing offline system...'**
  String get initializingOfflineSystem;

  /// No description provided for @loadingConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Loading configuration...'**
  String get loadingConfiguration;

  /// No description provided for @verifyingAccess.
  ///
  /// In en, this message translates to:
  /// **'Verifying access...'**
  String get verifyingAccess;

  /// No description provided for @testEventCreated.
  ///
  /// In en, this message translates to:
  /// **'Test event created!'**
  String get testEventCreated;

  /// No description provided for @testEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Event {timestamp}'**
  String testEventTitle(String timestamp);

  /// No description provided for @testEventDescription.
  ///
  /// In en, this message translates to:
  /// **'Test event created offline-first'**
  String get testEventDescription;

  /// No description provided for @syncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync completed!'**
  String get syncCompleted;

  /// No description provided for @localizationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Localization not available'**
  String get localizationNotAvailable;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// No description provided for @confirmLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogoutTitle;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave without saving?'**
  String get unsavedChangesMessage;

  /// No description provided for @confirmLeave.
  ///
  /// In en, this message translates to:
  /// **'Confirm Leave'**
  String get confirmLeave;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @myEvents.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get myEvents;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEvent;

  /// No description provided for @deleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete Event'**
  String get deleteEvent;

  /// No description provided for @removeFromMyList.
  ///
  /// In en, this message translates to:
  /// **'Remove from My List'**
  String get removeFromMyList;

  /// No description provided for @notifyCancellation.
  ///
  /// In en, this message translates to:
  /// **'Notify cancellation'**
  String get notifyCancellation;

  /// No description provided for @sendCancellationNotification.
  ///
  /// In en, this message translates to:
  /// **'Send cancellation notification'**
  String get sendCancellationNotification;

  /// No description provided for @sendNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotification;

  /// No description provided for @customMessageOptional.
  ///
  /// In en, this message translates to:
  /// **'Custom message (optional)'**
  String get customMessageOptional;

  /// No description provided for @writeAdditionalMessage.
  ///
  /// In en, this message translates to:
  /// **'Write an additional message for users...'**
  String get writeAdditionalMessage;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @eventTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Title'**
  String get eventTitle;

  /// Generic title label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Placeholder for event name input
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get eventNamePlaceholder;

  /// No description provided for @eventDescription.
  ///
  /// In en, this message translates to:
  /// **'Event Description'**
  String get eventDescription;

  /// Generic description label
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Placeholder for details input
  ///
  /// In en, this message translates to:
  /// **'Add details...'**
  String get addDetailsPlaceholder;

  /// No description provided for @eventDate.
  ///
  /// In en, this message translates to:
  /// **'Event Date'**
  String get eventDate;

  /// No description provided for @eventTime.
  ///
  /// In en, this message translates to:
  /// **'Event Time'**
  String get eventTime;

  /// No description provided for @eventLocation.
  ///
  /// In en, this message translates to:
  /// **'Event Location'**
  String get eventLocation;

  /// No description provided for @inviteToEvent.
  ///
  /// In en, this message translates to:
  /// **'Invite to Event'**
  String get inviteToEvent;

  /// No description provided for @inviteUsers.
  ///
  /// In en, this message translates to:
  /// **'Invite Users'**
  String get inviteUsers;

  /// No description provided for @eventCreated.
  ///
  /// In en, this message translates to:
  /// **'Event created successfully'**
  String get eventCreated;

  /// No description provided for @eventUpdated.
  ///
  /// In en, this message translates to:
  /// **'Event updated successfully'**
  String get eventUpdated;

  /// No description provided for @eventDeleted.
  ///
  /// In en, this message translates to:
  /// **'Event deleted successfully'**
  String get eventDeleted;

  /// No description provided for @eventRemoved.
  ///
  /// In en, this message translates to:
  /// **'Event removed successfully'**
  String get eventRemoved;

  /// No description provided for @seriesDeleted.
  ///
  /// In en, this message translates to:
  /// **'Series deleted successfully'**
  String get seriesDeleted;

  /// No description provided for @seriesEditNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Series editing will be available soon'**
  String get seriesEditNotAvailable;

  /// No description provided for @noEvents.
  ///
  /// In en, this message translates to:
  /// **'No events available'**
  String get noEvents;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcomingEvents;

  /// No description provided for @pastEvents.
  ///
  /// In en, this message translates to:
  /// **'Past Events'**
  String get pastEvents;

  /// No description provided for @eventDetails.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetails;

  /// No description provided for @joinEvent.
  ///
  /// In en, this message translates to:
  /// **'Join Event'**
  String get joinEvent;

  /// No description provided for @acceptEventButRejectInvitation.
  ///
  /// In en, this message translates to:
  /// **'Accept event but reject invitation'**
  String get acceptEventButRejectInvitation;

  /// No description provided for @acceptEventButRejectInvitationAck.
  ///
  /// In en, this message translates to:
  /// **'You accepted the event but rejected the invitation'**
  String get acceptEventButRejectInvitationAck;

  /// No description provided for @leaveEvent.
  ///
  /// In en, this message translates to:
  /// **'Leave Event'**
  String get leaveEvent;

  /// No description provided for @eventMembers.
  ///
  /// In en, this message translates to:
  /// **'Event Members'**
  String get eventMembers;

  /// No description provided for @eventInvitations.
  ///
  /// In en, this message translates to:
  /// **'Event Invitations'**
  String get eventInvitations;

  /// List of users invited to event
  ///
  /// In en, this message translates to:
  /// **'Invited Users'**
  String get invitedUsers;

  /// No description provided for @attendees.
  ///
  /// In en, this message translates to:
  /// **'Attendees'**
  String get attendees;

  /// Button to view all calendar events
  ///
  /// In en, this message translates to:
  /// **'View Calendar Events'**
  String get viewCalendarEvents;

  /// No description provided for @saveChangesOffline.
  ///
  /// In en, this message translates to:
  /// **'Save changes offline'**
  String get saveChangesOffline;

  /// No description provided for @saveEventOffline.
  ///
  /// In en, this message translates to:
  /// **'Save event offline'**
  String get saveEventOffline;

  /// No description provided for @updateEvent.
  ///
  /// In en, this message translates to:
  /// **'Update Event'**
  String get updateEvent;

  /// No description provided for @createRecurringEventQuestion.
  ///
  /// In en, this message translates to:
  /// **'Create recurring event?'**
  String get createRecurringEventQuestion;

  /// No description provided for @offlineSaveMessage.
  ///
  /// In en, this message translates to:
  /// **'Your changes will be saved offline and synced when you are online.'**
  String get offlineSaveMessage;

  /// No description provided for @onlineSaveMessage.
  ///
  /// In en, this message translates to:
  /// **'Your changes have been saved.'**
  String get onlineSaveMessage;

  /// No description provided for @offlineEventCreationMessage.
  ///
  /// In en, this message translates to:
  /// **'The event will be saved locally and created on the server automatically when you have connection.'**
  String get offlineEventCreationMessage;

  /// No description provided for @notifyChanges.
  ///
  /// In en, this message translates to:
  /// **'Notify Changes'**
  String get notifyChanges;

  /// No description provided for @sendChangesNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Send a notification to all users who have this event informing them about its changes.'**
  String get sendChangesNotificationMessage;

  /// No description provided for @utc.
  ///
  /// In en, this message translates to:
  /// **'UTC'**
  String get utc;

  /// No description provided for @worldFlag.
  ///
  /// In en, this message translates to:
  /// **'🌍'**
  String get worldFlag;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// Title for group details dialog
  ///
  /// In en, this message translates to:
  /// **'Group Details'**
  String get groupDetails;

  /// No description provided for @groupInitialFallback.
  ///
  /// In en, this message translates to:
  /// **'G'**
  String get groupInitialFallback;

  /// No description provided for @avatarUnknownInitial.
  ///
  /// In en, this message translates to:
  /// **'?'**
  String get avatarUnknownInitial;

  /// No description provided for @myGroups.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get myGroups;

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @groupDescription.
  ///
  /// In en, this message translates to:
  /// **'Group Description'**
  String get groupDescription;

  /// No description provided for @inviteToGroup.
  ///
  /// In en, this message translates to:
  /// **'Invite to Group'**
  String get inviteToGroup;

  /// No description provided for @groupCreated.
  ///
  /// In en, this message translates to:
  /// **'Group created successfully'**
  String get groupCreated;

  /// No description provided for @groupUpdated.
  ///
  /// In en, this message translates to:
  /// **'Group updated successfully'**
  String get groupUpdated;

  /// No description provided for @groupDeleted.
  ///
  /// In en, this message translates to:
  /// **'Group deleted successfully'**
  String get groupDeleted;

  /// No description provided for @noGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups available'**
  String get noGroups;

  /// No description provided for @groupMembers.
  ///
  /// In en, this message translates to:
  /// **'Group Members'**
  String get groupMembers;

  /// No description provided for @groupAdmin.
  ///
  /// In en, this message translates to:
  /// **'Group Admin'**
  String get groupAdmin;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make Admin'**
  String get makeAdmin;

  /// No description provided for @removeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove Admin'**
  String get removeAdmin;

  /// No description provided for @confirmMakeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to make {displayName} an admin?'**
  String confirmMakeAdmin(String displayName);

  /// No description provided for @confirmRemoveAdmin.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove admin permissions from {displayName}?'**
  String confirmRemoveAdmin(String displayName);

  /// No description provided for @memberMadeAdmin.
  ///
  /// In en, this message translates to:
  /// **'{displayName} made admin'**
  String memberMadeAdmin(String displayName);

  /// No description provided for @memberRemovedAdmin.
  ///
  /// In en, this message translates to:
  /// **'{displayName} removed admin'**
  String memberRemovedAdmin(String displayName);

  /// No description provided for @envDev.
  ///
  /// In en, this message translates to:
  /// **'DEV'**
  String get envDev;

  /// No description provided for @envProd.
  ///
  /// In en, this message translates to:
  /// **'PROD'**
  String get envProd;

  /// No description provided for @deleteFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get deleteFromGroup;

  /// No description provided for @noPermissionsToManageMember.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permissions to manage this member'**
  String get noPermissionsToManageMember;

  /// No description provided for @confirmRemoveFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {displayName} from the group?'**
  String confirmRemoveFromGroup(String displayName);

  /// No description provided for @memberRemovedFromGroup.
  ///
  /// In en, this message translates to:
  /// **'{displayName} removed from the group'**
  String memberRemovedFromGroup(String displayName);

  /// No description provided for @joinGroup.
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroup;

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave Group'**
  String get leaveGroup;

  /// No description provided for @groupInvitations.
  ///
  /// In en, this message translates to:
  /// **'Group Invitations'**
  String get groupInvitations;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @instagramName.
  ///
  /// In en, this message translates to:
  /// **'Instagram Name'**
  String get instagramName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search Users'**
  String get searchUsers;

  /// No description provided for @noUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsers;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @invitation.
  ///
  /// In en, this message translates to:
  /// **'Invitation'**
  String get invitation;

  /// No description provided for @invitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations;

  /// No description provided for @sendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Send Invitation'**
  String get sendInvitation;

  /// No description provided for @acceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'Accept Invitation'**
  String get acceptInvitation;

  /// No description provided for @rejectInvitation.
  ///
  /// In en, this message translates to:
  /// **'Reject Invitation'**
  String get rejectInvitation;

  /// No description provided for @cancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invitation'**
  String get cancelInvitation;

  /// No description provided for @invitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent successfully'**
  String get invitationSent;

  /// No description provided for @errorInvitingUser.
  ///
  /// In en, this message translates to:
  /// **'Error inviting {displayName}'**
  String errorInvitingUser(String displayName);

  /// No description provided for @errorInvitingUserWithError.
  ///
  /// In en, this message translates to:
  /// **'Error inviting {displayName}: {error}'**
  String errorInvitingUserWithError(String displayName, String error);

  /// No description provided for @errorInvitingGroup.
  ///
  /// In en, this message translates to:
  /// **'Error inviting group {groupName}'**
  String errorInvitingGroup(String groupName);

  /// No description provided for @errorInvitingGroupWithError.
  ///
  /// In en, this message translates to:
  /// **'Error inviting group {groupName}: {error}'**
  String errorInvitingGroupWithError(String groupName, String error);

  /// No description provided for @invitationsSentWithErrors.
  ///
  /// In en, this message translates to:
  /// **'{successful} invitations sent, {errors} errors'**
  String invitationsSentWithErrors(int successful, int errors);

  /// No description provided for @invitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get invitationAccepted;

  /// No description provided for @invitationRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get invitationRejected;

  /// No description provided for @invitationCancelled.
  ///
  /// In en, this message translates to:
  /// **'Invitation cancelled'**
  String get invitationCancelled;

  /// No description provided for @pendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'Pending Invitations'**
  String get pendingInvitations;

  /// No description provided for @sentInvitations.
  ///
  /// In en, this message translates to:
  /// **'Sent Invitations'**
  String get sentInvitations;

  /// No description provided for @receivedInvitations.
  ///
  /// In en, this message translates to:
  /// **'Received Invitations'**
  String get receivedInvitations;

  /// No description provided for @noInvitations.
  ///
  /// In en, this message translates to:
  /// **'No invitations'**
  String get noInvitations;

  /// No description provided for @invitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Invitation Message'**
  String get invitationMessage;

  /// No description provided for @invitationDecisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Invitation decision'**
  String get invitationDecisionTitle;

  /// No description provided for @optionalMessage.
  ///
  /// In en, this message translates to:
  /// **'Optional message'**
  String get optionalMessage;

  /// No description provided for @notifyInviter.
  ///
  /// In en, this message translates to:
  /// **'Notify inviter'**
  String get notifyInviter;

  /// No description provided for @postponeDecision.
  ///
  /// In en, this message translates to:
  /// **'Postpone decision'**
  String get postponeDecision;

  /// No description provided for @decideInvitation.
  ///
  /// In en, this message translates to:
  /// **'Decide invitation'**
  String get decideInvitation;

  /// No description provided for @decideNow.
  ///
  /// In en, this message translates to:
  /// **'Decide now'**
  String get decideNow;

  /// No description provided for @postponedUntil.
  ///
  /// In en, this message translates to:
  /// **'Postponed until {date}'**
  String postponedUntil(String date);

  /// No description provided for @confirmInviteUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to invite {displayName} to {eventTitle}?'**
  String confirmInviteUser(String displayName, String eventTitle);

  /// No description provided for @confirmCancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel the invitation for {eventTitle}?'**
  String confirmCancelInvitation(String eventTitle);

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @markAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get markAllAsRead;

  /// No description provided for @deleteNotification.
  ///
  /// In en, this message translates to:
  /// **'Delete Notification'**
  String get deleteNotification;

  /// No description provided for @clearNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear Notifications'**
  String get clearNotifications;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @disableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Disable Notifications'**
  String get disableNotifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @eventChangeNotification.
  ///
  /// In en, this message translates to:
  /// **'Event Change Notification'**
  String get eventChangeNotification;

  /// No description provided for @notificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Notification Message'**
  String get notificationMessage;

  /// No description provided for @notificationSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent successfully'**
  String get notificationSent;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccess;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logout successful'**
  String get logoutSuccess;

  /// No description provided for @registerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful'**
  String get registerSuccess;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get invalidCredentials;

  /// No description provided for @accountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get accountNotFound;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get emailInUse;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get weakPassword;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} is required'**
  String fieldRequired(String fieldName);

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get invalidEmail;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @invalidInstagramName.
  ///
  /// In en, this message translates to:
  /// **'Invalid Instagram username format'**
  String get invalidInstagramName;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {minLength} characters'**
  String passwordTooShort(int minLength);

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @textTooShort.
  ///
  /// In en, this message translates to:
  /// **'Text must be at least {minLength} characters'**
  String textTooShort(int minLength);

  /// No description provided for @textTooLong.
  ///
  /// In en, this message translates to:
  /// **'Text cannot exceed {maxLength} characters'**
  String textTooLong(int maxLength);

  /// No description provided for @eventTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Event title is required'**
  String get eventTitleRequired;

  /// No description provided for @groupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get groupNameRequired;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @messageRequired.
  ///
  /// In en, this message translates to:
  /// **'Message is required'**
  String get messageRequired;

  /// No description provided for @dateTooFarInFuture.
  ///
  /// In en, this message translates to:
  /// **'Date cannot be too far in the future'**
  String get dateTooFarInFuture;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @syncPending.
  ///
  /// In en, this message translates to:
  /// **'Sync pending'**
  String get syncPending;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncComplete;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncFailed;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get offlineMode;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get noConnection;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @pendingChanges.
  ///
  /// In en, this message translates to:
  /// **'Pending changes'**
  String get pendingChanges;

  /// No description provided for @syncWhenOnline.
  ///
  /// In en, this message translates to:
  /// **'Will sync when online'**
  String get syncWhenOnline;

  /// No description provided for @dataWillSyncSoon.
  ///
  /// In en, this message translates to:
  /// **'Your data will sync when connection is restored'**
  String get dataWillSyncSoon;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @now.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// Month label
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// Day label
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// Hour label
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hour;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @recently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recently;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @lastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get lastYear;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next Week'**
  String get nextWeek;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next Month'**
  String get nextMonth;

  /// No description provided for @nextYear.
  ///
  /// In en, this message translates to:
  /// **'Next Year'**
  String get nextYear;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @selectDateTime.
  ///
  /// In en, this message translates to:
  /// **'Select Date & Time'**
  String get selectDateTime;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @oneTime.
  ///
  /// In en, this message translates to:
  /// **'One Time'**
  String get oneTime;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @patternsConfigured.
  ///
  /// In en, this message translates to:
  /// **'Patterns configured: {count}'**
  String patternsConfigured(int count);

  /// No description provided for @noEventsMessage.
  ///
  /// In en, this message translates to:
  /// **'No events available for invitation'**
  String get noEventsMessage;

  /// No description provided for @noUsersMessage.
  ///
  /// In en, this message translates to:
  /// **'No users available for invitation'**
  String get noUsersMessage;

  /// No description provided for @noContactsMessage.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get noContactsMessage;

  /// No description provided for @noNotificationsMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up! No notifications.'**
  String get noNotificationsMessage;

  /// No description provided for @noInvitationsMessage.
  ///
  /// In en, this message translates to:
  /// **'No invitations at this time'**
  String get noInvitationsMessage;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results found for your search'**
  String get noSearchResults;

  /// No description provided for @emptyEventsList.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any events yet'**
  String get emptyEventsList;

  /// No description provided for @emptyGroupsList.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any groups yet'**
  String get emptyGroupsList;

  /// No description provided for @createFirstEvent.
  ///
  /// In en, this message translates to:
  /// **'Create your first event'**
  String get createFirstEvent;

  /// No description provided for @createFirstGroup.
  ///
  /// In en, this message translates to:
  /// **'Create your first group'**
  String get createFirstGroup;

  /// No description provided for @inviteFirstUser.
  ///
  /// In en, this message translates to:
  /// **'Invite your first user'**
  String get inviteFirstUser;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @debugAmbiguousReconciliations.
  ///
  /// In en, this message translates to:
  /// **'Debug ambiguous reconciliations'**
  String get debugAmbiguousReconciliations;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get systemTheme;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @countryAndTimezone.
  ///
  /// In en, this message translates to:
  /// **'Country and timezone'**
  String get countryAndTimezone;

  /// Country label
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// Timezone label
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get timezone;

  /// City or timezone selector label
  ///
  /// In en, this message translates to:
  /// **'City / Timezone'**
  String get cityOrTimezone;

  /// Message when no countries are available
  ///
  /// In en, this message translates to:
  /// **'No countries available'**
  String get noCountriesAvailable;

  /// Message when no timezones are available
  ///
  /// In en, this message translates to:
  /// **'No timezones available'**
  String get noTimezonesAvailable;

  /// Label for displaying the user's current timezone setting in the settings screen
  ///
  /// In en, this message translates to:
  /// **'Current Timezone'**
  String get currentTimezone;

  /// Title for the timezone selector action sheet
  ///
  /// In en, this message translates to:
  /// **'Select Timezone'**
  String get selectTimezone;

  /// No description provided for @selectCountryTimezone.
  ///
  /// In en, this message translates to:
  /// **'Select Country and Timezone'**
  String get selectCountryTimezone;

  /// No description provided for @defaultSettingsForNewEvents.
  ///
  /// In en, this message translates to:
  /// **'Default settings for new events'**
  String get defaultSettingsForNewEvents;

  /// No description provided for @connectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Connection Status'**
  String get connectionStatus;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @peopleAndGroups.
  ///
  /// In en, this message translates to:
  /// **'People & Groups'**
  String get peopleAndGroups;

  /// No description provided for @findYourFriends.
  ///
  /// In en, this message translates to:
  /// **'Find your friends'**
  String get findYourFriends;

  /// No description provided for @permissionsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Permissions needed'**
  String get permissionsNeeded;

  /// No description provided for @contactsPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'EventyPop can find friends who already use the app by accessing your contacts.'**
  String get contactsPermissionMessage;

  /// No description provided for @yourContactsStayPrivate.
  ///
  /// In en, this message translates to:
  /// **'Your contacts stay private'**
  String get yourContactsStayPrivate;

  /// No description provided for @onlyShowMutualFriends.
  ///
  /// In en, this message translates to:
  /// **'We only show mutual friends'**
  String get onlyShowMutualFriends;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @contactsPermissionSettingsMessage.
  ///
  /// In en, this message translates to:
  /// **'To find friends who use EventyPop, we need access to your contacts.\n\nGo to Settings > EventyPop > Contacts and enable it.'**
  String get contactsPermissionSettingsMessage;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @allowAccess.
  ///
  /// In en, this message translates to:
  /// **'Allow access'**
  String get allowAccess;

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @confirmDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the event \"{eventTitle}\"?'**
  String confirmDeleteEvent(String eventTitle);

  /// No description provided for @eventDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Event deleted successfully'**
  String get eventDeletedSuccessfully;

  /// No description provided for @deleteRecurringEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete Recurring Event'**
  String get deleteRecurringEvent;

  /// No description provided for @deleteRecurringEventQuestion.
  ///
  /// In en, this message translates to:
  /// **'What do you want to delete from \"{eventTitle}\"?'**
  String deleteRecurringEventQuestion(String eventTitle);

  /// No description provided for @deleteOnlyThisInstance.
  ///
  /// In en, this message translates to:
  /// **'Only this instance'**
  String get deleteOnlyThisInstance;

  /// No description provided for @deleteOnlyThisInstanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete only this specific event'**
  String get deleteOnlyThisInstanceSubtitle;

  /// No description provided for @deleteEntireSeries.
  ///
  /// In en, this message translates to:
  /// **'Entire recurring series'**
  String get deleteEntireSeries;

  /// No description provided for @deleteEntireSeriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all events in this series'**
  String get deleteEntireSeriesSubtitle;

  /// No description provided for @confirmDeleteInstance.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete only this instance of the event \"{eventTitle}\"?'**
  String confirmDeleteInstance(String eventTitle);

  /// No description provided for @deleteInstance.
  ///
  /// In en, this message translates to:
  /// **'Delete instance'**
  String get deleteInstance;

  /// No description provided for @confirmDeleteSeries.
  ///
  /// In en, this message translates to:
  /// **'Confirm series deletion'**
  String get confirmDeleteSeries;

  /// No description provided for @confirmDeleteSeriesMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the ENTIRE recurring series \"{seriesTitle}\"? This action cannot be undone.'**
  String confirmDeleteSeriesMessage(String seriesTitle);

  /// No description provided for @deleteCompleteSeries.
  ///
  /// In en, this message translates to:
  /// **'Delete complete series'**
  String get deleteCompleteSeries;

  /// No description provided for @editRecurringEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit Recurring Event'**
  String get editRecurringEvent;

  /// No description provided for @editRecurringEventQuestion.
  ///
  /// In en, this message translates to:
  /// **'What do you want to edit from \"{eventTitle}\"?'**
  String editRecurringEventQuestion(String eventTitle);

  /// No description provided for @editOnlyThisInstance.
  ///
  /// In en, this message translates to:
  /// **'Only this instance'**
  String get editOnlyThisInstance;

  /// No description provided for @editOnlyThisInstanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit only this specific event'**
  String get editOnlyThisInstanceSubtitle;

  /// No description provided for @editEntireSeries.
  ///
  /// In en, this message translates to:
  /// **'Entire recurring series'**
  String get editEntireSeries;

  /// No description provided for @editEntireSeriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Edit all events in this series'**
  String get editEntireSeriesSubtitle;

  /// No description provided for @phoneHintExample.
  ///
  /// In en, this message translates to:
  /// **'+34666666666'**
  String get phoneHintExample;

  /// No description provided for @smsCodeHintExample.
  ///
  /// In en, this message translates to:
  /// **'123456'**
  String get smsCodeHintExample;

  /// No description provided for @errorCompletingRegistrationWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error completing registration: {errorMessage}'**
  String errorCompletingRegistrationWithMessage(String errorMessage);

  /// No description provided for @usePhysicalIosDevice.
  ///
  /// In en, this message translates to:
  /// **'• Use a physical iOS device'**
  String get usePhysicalIosDevice;

  /// No description provided for @useAndroidEmulator.
  ///
  /// In en, this message translates to:
  /// **'• Use the Android emulator'**
  String get useAndroidEmulator;

  /// No description provided for @useWebVersion.
  ///
  /// In en, this message translates to:
  /// **'• Use the web version'**
  String get useWebVersion;

  /// No description provided for @invalidEventId.
  ///
  /// In en, this message translates to:
  /// **'Invalid event ID.'**
  String get invalidEventId;

  /// No description provided for @invitationSentTo.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent to {displayName}.'**
  String invitationSentTo(String displayName);

  /// No description provided for @errorSendingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Error sending invitation'**
  String get errorSendingInvitation;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUser;

  /// No description provided for @confirmBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block {displayName}?'**
  String confirmBlockUser(String displayName);

  /// No description provided for @confirmUnblockUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unblock {displayName}?'**
  String confirmUnblockUser(String displayName);

  /// No description provided for @userBlockedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User blocked successfully.'**
  String get userBlockedSuccessfully;

  /// No description provided for @userUnblockedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User unblocked successfully.'**
  String get userUnblockedSuccessfully;

  /// No description provided for @errorBlockingUser.
  ///
  /// In en, this message translates to:
  /// **'Error blocking user.'**
  String get errorBlockingUser;

  /// No description provided for @errorUnblockingUser.
  ///
  /// In en, this message translates to:
  /// **'Error unblocking user.'**
  String get errorUnblockingUser;

  /// No description provided for @errorBlockingUserDetail.
  ///
  /// In en, this message translates to:
  /// **'Error blocking user: {errorMessage}'**
  String errorBlockingUserDetail(String errorMessage);

  /// No description provided for @invitationsSentToUser.
  ///
  /// In en, this message translates to:
  /// **'Invitations sent to {displayName}'**
  String invitationsSentToUser(String displayName);

  /// No description provided for @eventNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Event not available'**
  String get eventNotAvailable;

  /// No description provided for @blockingUser.
  ///
  /// In en, this message translates to:
  /// **'Blocking User...'**
  String get blockingUser;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// No description provided for @noBlockedUsersDescription.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t blocked anyone yet.'**
  String get noBlockedUsersDescription;

  /// No description provided for @eventHidden.
  ///
  /// In en, this message translates to:
  /// **'Event \"{eventTitle}\" hidden.'**
  String eventHidden(String eventTitle);

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @inviteToOtherEvents.
  ///
  /// In en, this message translates to:
  /// **'Invite to other events'**
  String get inviteToOtherEvents;

  /// No description provided for @accessDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDeniedTitle;

  /// No description provided for @accessDeniedMessagePrimary.
  ///
  /// In en, this message translates to:
  /// **'This application is available for private users only.'**
  String get accessDeniedMessagePrimary;

  /// No description provided for @accessDeniedMessageSecondary.
  ///
  /// In en, this message translates to:
  /// **'Public users do not have access to this mobile application.'**
  String get accessDeniedMessageSecondary;

  /// No description provided for @contactAdminIfError.
  ///
  /// In en, this message translates to:
  /// **'Contact the administrator if you believe this is an error.'**
  String get contactAdminIfError;

  /// No description provided for @invitationCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invitation cancelled successfully.'**
  String get invitationCancelledSuccessfully;

  /// No description provided for @errorCancellingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling invitation'**
  String errorCancellingInvitation(String errorMessage);

  /// No description provided for @eventDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Event description is required'**
  String get eventDescriptionRequired;

  /// No description provided for @groupInfo.
  ///
  /// In en, this message translates to:
  /// **'Group Info'**
  String get groupInfo;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @addEventDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Add details about your event...'**
  String get addEventDetailsHint;

  /// No description provided for @addMembers.
  ///
  /// In en, this message translates to:
  /// **'Add Members'**
  String get addMembers;

  /// No description provided for @searchFriends.
  ///
  /// In en, this message translates to:
  /// **'Search Friends'**
  String get searchFriends;

  /// No description provided for @noFriendsToAdd.
  ///
  /// In en, this message translates to:
  /// **'No friends to add'**
  String get noFriendsToAdd;

  /// No description provided for @noFriendsFoundWithName.
  ///
  /// In en, this message translates to:
  /// **'No friends found with that name'**
  String get noFriendsFoundWithName;

  /// No description provided for @addAtLeastOnePattern.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one repetition pattern.'**
  String get addAtLeastOnePattern;

  /// No description provided for @startDateBeforeEndDate.
  ///
  /// In en, this message translates to:
  /// **'Start date must be before end date.'**
  String get startDateBeforeEndDate;

  /// No description provided for @errorCreatingEvent.
  ///
  /// In en, this message translates to:
  /// **'Error creating event.'**
  String get errorCreatingEvent;

  /// No description provided for @createRecurringEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Recurring Event'**
  String get createRecurringEvent;

  /// No description provided for @repetitionPatterns.
  ///
  /// In en, this message translates to:
  /// **'Repetition Patterns'**
  String get repetitionPatterns;

  /// No description provided for @addSchedules.
  ///
  /// In en, this message translates to:
  /// **'Add Schedules'**
  String get addSchedules;

  /// No description provided for @noPatternsConfigured.
  ///
  /// In en, this message translates to:
  /// **'No patterns configured.'**
  String get noPatternsConfigured;

  /// No description provided for @editPattern.
  ///
  /// In en, this message translates to:
  /// **'Edit Pattern'**
  String get editPattern;

  /// No description provided for @newPattern.
  ///
  /// In en, this message translates to:
  /// **'New Pattern'**
  String get newPattern;

  /// No description provided for @dayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Day of Week'**
  String get dayOfWeek;

  /// No description provided for @hourLabel.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hourLabel;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @organizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizer;

  /// No description provided for @noDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// No description provided for @upcomingEventsOf.
  ///
  /// In en, this message translates to:
  /// **'Upcoming events of {eventName}'**
  String upcomingEventsOf(String eventName);

  /// No description provided for @noUpcomingEventsScheduled.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events scheduled.'**
  String get noUpcomingEventsScheduled;

  /// No description provided for @invitedPeople.
  ///
  /// In en, this message translates to:
  /// **'Invited People'**
  String get invitedPeople;

  /// No description provided for @noInvitedPeople.
  ///
  /// In en, this message translates to:
  /// **'No invited people.'**
  String get noInvitedPeople;

  /// No description provided for @invitationToEvent.
  ///
  /// In en, this message translates to:
  /// **'Invitation to Event'**
  String get invitationToEvent;

  /// No description provided for @noUsersOrGroupsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No users or groups available.'**
  String get noUsersOrGroupsAvailable;

  /// No description provided for @noGroupsLeftToInvite.
  ///
  /// In en, this message translates to:
  /// **'No groups left to invite.'**
  String get noGroupsLeftToInvite;

  /// No description provided for @noUsersLeftToInvite.
  ///
  /// In en, this message translates to:
  /// **'No users left to invite.'**
  String get noUsersLeftToInvite;

  /// No description provided for @unnamedGroup.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Group'**
  String get unnamedGroup;

  /// No description provided for @errorInviting.
  ///
  /// In en, this message translates to:
  /// **'Error inviting.'**
  String get errorInviting;

  /// No description provided for @allGroupMembersAlreadyInvited.
  ///
  /// In en, this message translates to:
  /// **'All group members already invited.'**
  String get allGroupMembersAlreadyInvited;

  /// No description provided for @alreadyInvited.
  ///
  /// In en, this message translates to:
  /// **'Already Invited'**
  String get alreadyInvited;

  /// No description provided for @invitationsSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invitations sent successfully to {destinations} users.'**
  String invitationsSentSuccessfully(int destinations);

  /// No description provided for @invitationsSent.
  ///
  /// In en, this message translates to:
  /// **'Invitations Sent'**
  String get invitationsSent;

  /// No description provided for @errors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get errors;

  /// No description provided for @errorSendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'Error sending invitations.'**
  String get errorSendingInvitations;

  /// No description provided for @sendInvitations.
  ///
  /// In en, this message translates to:
  /// **'Send Invitations'**
  String get sendInvitations;

  /// No description provided for @loginWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Login with Phone'**
  String get loginWithPhone;

  /// No description provided for @sendSmsCode.
  ///
  /// In en, this message translates to:
  /// **'Send SMS Code'**
  String get sendSmsCode;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phoneNumber}'**
  String codeSentTo(String phoneNumber);

  /// No description provided for @smsCode.
  ///
  /// In en, this message translates to:
  /// **'SMS Code'**
  String get smsCode;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @changeNumber.
  ///
  /// In en, this message translates to:
  /// **'Change Number'**
  String get changeNumber;

  /// No description provided for @automaticVerificationError.
  ///
  /// In en, this message translates to:
  /// **'Automatic verification failed. Please enter the code manually.'**
  String get automaticVerificationError;

  /// No description provided for @verificationError.
  ///
  /// In en, this message translates to:
  /// **'Verification Error'**
  String get verificationError;

  /// No description provided for @phoneAuthSimulatorError.
  ///
  /// In en, this message translates to:
  /// **'Phone authentication is not supported on iOS simulator. Please use a physical device or Android emulator.'**
  String get phoneAuthSimulatorError;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get tooManyRequests;

  /// No description provided for @operationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Phone number sign-in is not enabled. Please enable it in the authentication console.'**
  String get operationNotAllowed;

  /// No description provided for @smsCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'SMS code sent to {phoneNumber}.'**
  String smsCodeSentTo(String phoneNumber);

  /// No description provided for @errorSendingCode.
  ///
  /// In en, this message translates to:
  /// **'Error sending code.'**
  String get errorSendingCode;

  /// No description provided for @incorrectCode.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code. Please try again.'**
  String get incorrectCode;

  /// No description provided for @invalidVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code.'**
  String get invalidVerificationCode;

  /// Error when user session expires
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please login again.'**
  String get sessionExpired;

  /// No description provided for @errorVerifyingCode.
  ///
  /// In en, this message translates to:
  /// **'Error verifying code.'**
  String get errorVerifyingCode;

  /// No description provided for @couldNotGetAuthToken.
  ///
  /// In en, this message translates to:
  /// **'Could not get authentication token'**
  String get couldNotGetAuthToken;

  /// No description provided for @iosSimulatorDetected.
  ///
  /// In en, this message translates to:
  /// **'iOS Simulator Detected'**
  String get iosSimulatorDetected;

  /// No description provided for @phoneAuthLimitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Phone authentication is not fully supported on iOS simulators. For full functionality, please use a physical iOS device, an Android emulator, or the web version.'**
  String get phoneAuthLimitationMessage;

  /// No description provided for @testPhoneAuthInstructions.
  ///
  /// In en, this message translates to:
  /// **'For testing purposes on iOS simulator, you can use a test phone number and verification code configured in the authentication console.'**
  String get testPhoneAuthInstructions;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @errorLoadingNotifications.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications.'**
  String get errorLoadingNotifications;

  /// No description provided for @errorAcceptingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Error accepting invitation'**
  String get errorAcceptingInvitation;

  /// No description provided for @errorRejectingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Error rejecting invitation'**
  String get errorRejectingInvitation;

  /// No description provided for @syncingContacts.
  ///
  /// In en, this message translates to:
  /// **'Syncing contacts...'**
  String get syncingContacts;

  /// No description provided for @contactsPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission required.'**
  String get contactsPermissionRequired;

  /// No description provided for @errorLoadingFriends.
  ///
  /// In en, this message translates to:
  /// **'Error loading friends.'**
  String get errorLoadingFriends;

  /// No description provided for @errorLoadingFriendsWithError.
  ///
  /// In en, this message translates to:
  /// **'Error loading friends: {error}'**
  String errorLoadingFriendsWithError(String error);

  /// No description provided for @contactsPermissionInstructions.
  ///
  /// In en, this message translates to:
  /// **'To find friends who use EventyPop, we need access to your contacts. Please grant permission in settings.'**
  String get contactsPermissionInstructions;

  /// No description provided for @requestPermissions.
  ///
  /// In en, this message translates to:
  /// **'Request Permissions'**
  String get requestPermissions;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @resetPreferences.
  ///
  /// In en, this message translates to:
  /// **'Reset preferences'**
  String get resetPreferences;

  /// Button label for resetting contacts permission preferences in settings
  ///
  /// In en, this message translates to:
  /// **'Reset Contacts Permissions'**
  String get resetContactsPermissions;

  /// Button label for opening the device app settings
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get openAppSettings;

  /// No description provided for @syncInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'Events, subscriptions, notifications, and invitations are automatically synchronized when the application starts and in the background to keep the information updated.'**
  String get syncInfoMessage;

  /// No description provided for @settingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Settings updated'**
  String get settingsUpdated;

  /// No description provided for @errorUpdatingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error updating settings'**
  String get errorUpdatingSettings;

  /// No description provided for @errorUpdatingContacts.
  ///
  /// In en, this message translates to:
  /// **'Error updating contacts: {error}'**
  String errorUpdatingContacts(String error);

  /// No description provided for @creatorLabel.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creatorLabel;

  /// No description provided for @adminsList.
  ///
  /// In en, this message translates to:
  /// **'Admins: {list}'**
  String adminsList(String list);

  /// No description provided for @noAdmins.
  ///
  /// In en, this message translates to:
  /// **'No admins'**
  String get noAdmins;

  /// No description provided for @membersAndAdmins.
  ///
  /// In en, this message translates to:
  /// **'Members: {count} • {admins}'**
  String membersAndAdmins(int count, String admins);

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @acceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get acceptedStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedStatus;

  /// No description provided for @recurringShort.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get recurringShort;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet.'**
  String get noFriendsYet;

  /// No description provided for @noContactsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No contacts available.'**
  String get noContactsAvailable;

  /// No description provided for @notInAnyGroup.
  ///
  /// In en, this message translates to:
  /// **'Not in any group yet.'**
  String get notInAnyGroup;

  /// No description provided for @groupsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your groups will appear here.'**
  String get groupsWillAppearHere;

  /// No description provided for @startingAutomaticSync.
  ///
  /// In en, this message translates to:
  /// **'Starting automatic sync...'**
  String get startingAutomaticSync;

  /// No description provided for @loadingLocalData.
  ///
  /// In en, this message translates to:
  /// **'Loading local data...'**
  String get loadingLocalData;

  /// No description provided for @verifyingSync.
  ///
  /// In en, this message translates to:
  /// **'Verifying sync...'**
  String get verifyingSync;

  /// No description provided for @checkingContactsPermissions.
  ///
  /// In en, this message translates to:
  /// **'Checking contacts permissions...'**
  String get checkingContactsPermissions;

  /// No description provided for @dataUpdated.
  ///
  /// In en, this message translates to:
  /// **'Data updated.'**
  String get dataUpdated;

  /// No description provided for @readyToUse.
  ///
  /// In en, this message translates to:
  /// **'Ready to use!'**
  String get readyToUse;

  /// No description provided for @errorInitializingApp.
  ///
  /// In en, this message translates to:
  /// **'Error initializing app.'**
  String get errorInitializingApp;

  /// No description provided for @retrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying...'**
  String get retrying;

  /// No description provided for @yourEventsAlwaysWithYou.
  ///
  /// In en, this message translates to:
  /// **'Your events, always with you.'**
  String get yourEventsAlwaysWithYou;

  /// No description provided for @oopsSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong.'**
  String get oopsSomethingWentWrong;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @mySubscriptions.
  ///
  /// In en, this message translates to:
  /// **'My Subscriptions'**
  String get mySubscriptions;

  /// No description provided for @searchPublicUsers.
  ///
  /// In en, this message translates to:
  /// **'Search Public Users'**
  String get searchPublicUsers;

  /// No description provided for @searchEvents.
  ///
  /// In en, this message translates to:
  /// **'Search Events'**
  String get searchEvents;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @allEvents.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allEvents;

  /// No description provided for @myEventsFilter.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get myEventsFilter;

  /// No description provided for @subscribedEvents.
  ///
  /// In en, this message translates to:
  /// **'Subs'**
  String get subscribedEvents;

  /// No description provided for @invitationEvents.
  ///
  /// In en, this message translates to:
  /// **'Invites'**
  String get invitationEvents;

  /// No description provided for @noEventsForFilter.
  ///
  /// In en, this message translates to:
  /// **'No events for this filter'**
  String get noEventsForFilter;

  /// No description provided for @noMyEvents.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any events yet'**
  String get noMyEvents;

  /// No description provided for @noSubscribedEvents.
  ///
  /// In en, this message translates to:
  /// **'No events from subscribed users'**
  String get noSubscribedEvents;

  /// No description provided for @noInvitationEvents.
  ///
  /// In en, this message translates to:
  /// **'No invitation events'**
  String get noInvitationEvents;

  /// No description provided for @searchSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Search subscriptions'**
  String get searchSubscriptions;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @eventTypes.
  ///
  /// In en, this message translates to:
  /// **'Event Types'**
  String get eventTypes;

  /// No description provided for @showRecurringEvents.
  ///
  /// In en, this message translates to:
  /// **'Show Recurring Events'**
  String get showRecurringEvents;

  /// No description provided for @showOwnedEvents.
  ///
  /// In en, this message translates to:
  /// **'Show Owned Events'**
  String get showOwnedEvents;

  /// No description provided for @showInvitedEvents.
  ///
  /// In en, this message translates to:
  /// **'Show Invited Events'**
  String get showInvitedEvents;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @until.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get until;

  /// No description provided for @noEventsFound.
  ///
  /// In en, this message translates to:
  /// **'No events found'**
  String get noEventsFound;

  /// No description provided for @personalNote.
  ///
  /// In en, this message translates to:
  /// **'Personal Note'**
  String get personalNote;

  /// No description provided for @addPersonalNote.
  ///
  /// In en, this message translates to:
  /// **'Add Personal Note'**
  String get addPersonalNote;

  /// No description provided for @addPersonalNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a private note for this event...'**
  String get addPersonalNoteHint;

  /// No description provided for @personalNoteUpdated.
  ///
  /// In en, this message translates to:
  /// **'Personal note updated'**
  String get personalNoteUpdated;

  /// No description provided for @personalNoteDeleted.
  ///
  /// In en, this message translates to:
  /// **'Personal note deleted'**
  String get personalNoteDeleted;

  /// No description provided for @editPersonalNote.
  ///
  /// In en, this message translates to:
  /// **'Edit Note'**
  String get editPersonalNote;

  /// No description provided for @errorSavingNote.
  ///
  /// In en, this message translates to:
  /// **'Error saving note'**
  String get errorSavingNote;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this personal note?'**
  String get deleteNoteConfirmation;

  /// No description provided for @privateNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a private note for this event. Only you will be able to see it.'**
  String get privateNoteHint;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found.'**
  String get noUsersFound;

  /// No description provided for @publicUser.
  ///
  /// In en, this message translates to:
  /// **'Public User'**
  String get publicUser;

  /// No description provided for @noSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet.'**
  String get noSubscriptions;

  /// No description provided for @errorLoadingSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Error loading subscriptions.'**
  String get errorLoadingSubscriptions;

  /// No description provided for @unsubscribedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribed successfully.'**
  String get unsubscribedSuccessfully;

  /// No description provided for @subscribedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Subscribed successfully.'**
  String get subscribedSuccessfully;

  /// No description provided for @errorRemovingSubscription.
  ///
  /// In en, this message translates to:
  /// **'Error removing subscription.'**
  String get errorRemovingSubscription;

  /// No description provided for @subscribedToUser.
  ///
  /// In en, this message translates to:
  /// **'Subscribed to {displayName}'**
  String subscribedToUser(String displayName);

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @recurringEvent.
  ///
  /// In en, this message translates to:
  /// **'Recurring Event'**
  String get recurringEvent;

  /// No description provided for @startDateTime.
  ///
  /// In en, this message translates to:
  /// **'Start Date & Time'**
  String get startDateTime;

  /// No description provided for @endDateTime.
  ///
  /// In en, this message translates to:
  /// **'End Date & Time'**
  String get endDateTime;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @cityHint.
  ///
  /// In en, this message translates to:
  /// **'Enter city name'**
  String get cityHint;

  /// No description provided for @noLocationSet.
  ///
  /// In en, this message translates to:
  /// **'No location set'**
  String get noLocationSet;

  /// No description provided for @recurrencePatterns.
  ///
  /// In en, this message translates to:
  /// **'Recurrence Patterns'**
  String get recurrencePatterns;

  /// No description provided for @addPattern.
  ///
  /// In en, this message translates to:
  /// **'Add Pattern'**
  String get addPattern;

  /// No description provided for @addAnotherPattern.
  ///
  /// In en, this message translates to:
  /// **'Add Another Pattern'**
  String get addAnotherPattern;

  /// No description provided for @tapAddPatternToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap Add Pattern to start'**
  String get tapAddPatternToStart;

  /// No description provided for @selectDayOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Select Day of Week'**
  String get selectDayOfWeek;

  /// No description provided for @noPatternsAdded.
  ///
  /// In en, this message translates to:
  /// **'No recurrence patterns added'**
  String get noPatternsAdded;

  /// No description provided for @addFirstPattern.
  ///
  /// In en, this message translates to:
  /// **'Add your first recurrence pattern'**
  String get addFirstPattern;

  /// No description provided for @onePatternAdded.
  ///
  /// In en, this message translates to:
  /// **'1 pattern added'**
  String get onePatternAdded;

  /// No description provided for @multiplePatternsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count} patterns added'**
  String multiplePatternsAdded(int count);

  /// No description provided for @everyNDays.
  ///
  /// In en, this message translates to:
  /// **'Every {count} days'**
  String everyNDays(int count);

  /// No description provided for @everyNWeeks.
  ///
  /// In en, this message translates to:
  /// **'Every {count} weeks'**
  String everyNWeeks(int count);

  /// No description provided for @everyNMonths.
  ///
  /// In en, this message translates to:
  /// **'Every {count} months'**
  String everyNMonths(int count);

  /// No description provided for @everyNYears.
  ///
  /// In en, this message translates to:
  /// **'Every {count} years'**
  String everyNYears(int count);

  /// No description provided for @endsOn.
  ///
  /// In en, this message translates to:
  /// **'Ends on {date}'**
  String endsOn(String date);

  /// No description provided for @dayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String dayOfMonth(int day);

  /// No description provided for @noAdditionalSettings.
  ///
  /// In en, this message translates to:
  /// **'No additional settings'**
  String get noAdditionalSettings;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @interval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get interval;

  /// No description provided for @daysOfWeek.
  ///
  /// In en, this message translates to:
  /// **'Days of Week'**
  String get daysOfWeek;

  /// No description provided for @selectDay.
  ///
  /// In en, this message translates to:
  /// **'Select Day'**
  String get selectDay;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @selectEndDate.
  ///
  /// In en, this message translates to:
  /// **'Select End Date'**
  String get selectEndDate;

  /// No description provided for @monthOfYear.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthOfYear;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @noRecurrencePatterns.
  ///
  /// In en, this message translates to:
  /// **'No recurrence patterns added yet'**
  String get noRecurrencePatterns;

  /// No description provided for @deletePattern.
  ///
  /// In en, this message translates to:
  /// **'Delete Pattern'**
  String get deletePattern;

  /// No description provided for @confirmDeletePattern.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this pattern?'**
  String get confirmDeletePattern;

  /// No description provided for @recurringEventHelperText.
  ///
  /// In en, this message translates to:
  /// **'Toggle to create an event that repeats'**
  String get recurringEventHelperText;

  /// No description provided for @endDateRequired.
  ///
  /// In en, this message translates to:
  /// **'End date is required for recurring events'**
  String get endDateRequired;

  /// No description provided for @atLeastOnePatternRequired.
  ///
  /// In en, this message translates to:
  /// **'At least one recurrence pattern is required'**
  String get atLeastOnePatternRequired;

  /// No description provided for @eventCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Event created successfully'**
  String get eventCreatedSuccessfully;

  /// No description provided for @eventUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Event updated successfully'**
  String get eventUpdatedSuccessfully;

  /// No description provided for @eventCreatedOffline.
  ///
  /// In en, this message translates to:
  /// **'Event created (will sync when online)'**
  String get eventCreatedOffline;

  /// No description provided for @eventUpdatedOffline.
  ///
  /// In en, this message translates to:
  /// **'Event updated (will sync when online)'**
  String get eventUpdatedOffline;

  /// No description provided for @eventChangedNotification.
  ///
  /// In en, this message translates to:
  /// **'The event \"{eventTitle}\" has been modified'**
  String eventChangedNotification(String eventTitle);

  /// No description provided for @errorSendingNotification.
  ///
  /// In en, this message translates to:
  /// **'Error sending notification.'**
  String get errorSendingNotification;

  /// No description provided for @offlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Offline - Events saved locally'**
  String get offlineStatus;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online - Changes saved automatically'**
  String get onlineStatus;

  /// No description provided for @syncingData.
  ///
  /// In en, this message translates to:
  /// **'Syncing data...'**
  String get syncingData;

  /// No description provided for @syncingPendingOperations.
  ///
  /// In en, this message translates to:
  /// **'Syncing {count} pending changes'**
  String syncingPendingOperations(int count);

  /// No description provided for @noDaysSelected.
  ///
  /// In en, this message translates to:
  /// **'No days selected'**
  String get noDaysSelected;

  /// No description provided for @allDaysSelected.
  ///
  /// In en, this message translates to:
  /// **'All days'**
  String get allDaysSelected;

  /// No description provided for @weekdaysSelected.
  ///
  /// In en, this message translates to:
  /// **'Weekdays'**
  String get weekdaysSelected;

  /// No description provided for @weekendsSelected.
  ///
  /// In en, this message translates to:
  /// **'Weekends'**
  String get weekendsSelected;

  /// No description provided for @createNormalEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createNormalEvent;

  /// No description provided for @selectTimezoneForCountry.
  ///
  /// In en, this message translates to:
  /// **'Select timezone for {country}'**
  String selectTimezoneForCountry(String country);

  /// No description provided for @searchCity.
  ///
  /// In en, this message translates to:
  /// **'Search City'**
  String get searchCity;

  /// No description provided for @citySearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type city name...'**
  String get citySearchPlaceholder;

  /// No description provided for @offlineTestDashboard.
  ///
  /// In en, this message translates to:
  /// **'Offline Test Dashboard'**
  String get offlineTestDashboard;

  /// No description provided for @pendingOperationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending operations:'**
  String get pendingOperationsLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @eventsLabel.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsLabel;

  /// No description provided for @createLabel.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createLabel;

  /// No description provided for @updateLabel.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateLabel;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @connectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connectionLabel;

  /// No description provided for @membersLabel.
  ///
  /// In en, this message translates to:
  /// **'Members: {count}'**
  String membersLabel(int count);

  /// No description provided for @groupMembersHeading.
  ///
  /// In en, this message translates to:
  /// **'Group Members'**
  String get groupMembersHeading;

  /// No description provided for @noMembersInGroup.
  ///
  /// In en, this message translates to:
  /// **'No members in this group'**
  String get noMembersInGroup;

  /// No description provided for @testCreate.
  ///
  /// In en, this message translates to:
  /// **'Test Create'**
  String get testCreate;

  /// No description provided for @forceSync.
  ///
  /// In en, this message translates to:
  /// **'Force Sync'**
  String get forceSync;

  /// No description provided for @checkNet.
  ///
  /// In en, this message translates to:
  /// **'Check Net'**
  String get checkNet;

  /// No description provided for @eventWithoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Untitled event'**
  String get eventWithoutTitle;

  /// No description provided for @invitationFrom.
  ///
  /// In en, this message translates to:
  /// **'Invited by'**
  String get invitationFrom;

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationDeleted;

  /// No description provided for @errorDeletingNotification.
  ///
  /// In en, this message translates to:
  /// **'Error deleting notification: {error}'**
  String errorDeletingNotification(String error);

  /// No description provided for @specificTimezone.
  ///
  /// In en, this message translates to:
  /// **'Specific timezone'**
  String get specificTimezone;

  /// No description provided for @hourSuffix.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourSuffix;

  /// No description provided for @offsetDotTimezone.
  ///
  /// In en, this message translates to:
  /// **'{offset} • {timezone}'**
  String offsetDotTimezone(String offset, String timezone);

  /// No description provided for @timezoneWithOffsetParen.
  ///
  /// In en, this message translates to:
  /// **'{timezone} ({offset})'**
  String timezoneWithOffsetParen(String timezone, String offset);

  /// No description provided for @countryCodeDotTimezone.
  ///
  /// In en, this message translates to:
  /// **'{countryCode} • {timezone}'**
  String countryCodeDotTimezone(String countryCode, String timezone);

  /// No description provided for @dotSeparator.
  ///
  /// In en, this message translates to:
  /// **' • '**
  String get dotSeparator;

  /// No description provided for @minuteSuffix.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minuteSuffix;

  /// No description provided for @colon.
  ///
  /// In en, this message translates to:
  /// **':'**
  String get colon;

  /// No description provided for @errorCreatingTestEvent.
  ///
  /// In en, this message translates to:
  /// **'Error creating test event: {error}'**
  String errorCreatingTestEvent(String error);

  /// No description provided for @syncFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String syncFailedWithError(String error);

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @errorDeletingGroup.
  ///
  /// In en, this message translates to:
  /// **'Error deleting group: {error}'**
  String errorDeletingGroup(String error);

  /// No description provided for @networkErrorDuringSync.
  ///
  /// In en, this message translates to:
  /// **'Network error during sync'**
  String get networkErrorDuringSync;

  /// No description provided for @cannotSyncWhileOffline.
  ///
  /// In en, this message translates to:
  /// **'Cannot sync while offline'**
  String get cannotSyncWhileOffline;

  /// No description provided for @timezoneServiceNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'TimezoneService not initialized. Call initialize() first.'**
  String get timezoneServiceNotInitialized;

  /// No description provided for @notificationServiceNotInitialized.
  ///
  /// In en, this message translates to:
  /// **'NotificationService not initialized'**
  String get notificationServiceNotInitialized;

  /// Banner shown on event cards for invitations that are still pending
  ///
  /// In en, this message translates to:
  /// **'Pending invitation'**
  String get pendingInvitationBanner;

  /// Button to view all events of the organizer
  ///
  /// In en, this message translates to:
  /// **'View Organizer Events'**
  String get viewOrganizerEvents;

  /// Button to view the parent event series
  ///
  /// In en, this message translates to:
  /// **'View Event Series'**
  String get viewEventSeries;

  /// Localized word for 'and' used in sentences
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get andWord;

  /// Localized word for 'Every' used in recurrence description
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get everyWord;

  /// Localized word for 'at' used in time expressions
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get atWord;

  /// No description provided for @errorLoadingInvitations.
  ///
  /// In en, this message translates to:
  /// **'Error loading invitations'**
  String get errorLoadingInvitations;

  /// No description provided for @errorSendingGroupInvitation.
  ///
  /// In en, this message translates to:
  /// **'Error sending group invitation'**
  String get errorSendingGroupInvitation;

  /// No description provided for @invitationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Invitation not found'**
  String get invitationNotFound;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @validationFailed.
  ///
  /// In en, this message translates to:
  /// **'Validation failed'**
  String get validationFailed;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @noInvitationsSent.
  ///
  /// In en, this message translates to:
  /// **'No invitations sent yet'**
  String get noInvitationsSent;

  /// No description provided for @subscribeToOwner.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to Owner'**
  String get subscribeToOwner;

  /// No description provided for @yourResponse.
  ///
  /// In en, this message translates to:
  /// **'Your Response'**
  String get yourResponse;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @eventManagement.
  ///
  /// In en, this message translates to:
  /// **'Event Management'**
  String get eventManagement;

  /// No description provided for @successfully.
  ///
  /// In en, this message translates to:
  /// **'successfully'**
  String get successfully;

  /// No description provided for @eventActions.
  ///
  /// In en, this message translates to:
  /// **'Event Actions'**
  String get eventActions;

  /// No description provided for @eventCancellation.
  ///
  /// In en, this message translates to:
  /// **'Event Cancellation'**
  String get eventCancellation;

  /// No description provided for @cancellationMessage.
  ///
  /// In en, this message translates to:
  /// **'Cancellation message'**
  String get cancellationMessage;

  /// No description provided for @cancelEventWithNotification.
  ///
  /// In en, this message translates to:
  /// **'Cancel Event with Notification'**
  String get cancelEventWithNotification;

  /// No description provided for @eventOptions.
  ///
  /// In en, this message translates to:
  /// **'Event Options'**
  String get eventOptions;

  /// No description provided for @cancelEvent.
  ///
  /// In en, this message translates to:
  /// **'Cancel Event'**
  String get cancelEvent;

  /// No description provided for @confirmCancelEvent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this event?'**
  String get confirmCancelEvent;

  /// No description provided for @doNotCancel.
  ///
  /// In en, this message translates to:
  /// **'Do Not Cancel'**
  String get doNotCancel;

  /// No description provided for @eventCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Event cancelled successfully'**
  String get eventCancelledSuccessfully;

  /// No description provided for @failedToCancelEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel event'**
  String get failedToCancelEvent;

  /// No description provided for @removeFromList.
  ///
  /// In en, this message translates to:
  /// **'Remove from List'**
  String get removeFromList;

  /// No description provided for @confirmRemoveFromList.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this event from your list?'**
  String get confirmRemoveFromList;

  /// No description provided for @eventRemovedFromList.
  ///
  /// In en, this message translates to:
  /// **'Event removed from list'**
  String get eventRemovedFromList;

  /// No description provided for @failedToRemoveFromList.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove from list'**
  String get failedToRemoveFromList;

  /// No description provided for @invitationPostponed.
  ///
  /// In en, this message translates to:
  /// **'Postponed'**
  String get invitationPostponed;

  /// No description provided for @invitationPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get invitationPending;

  /// No description provided for @acceptedEventButDeclinedInvitation.
  ///
  /// In en, this message translates to:
  /// **'Accepted event / Declined invitation'**
  String get acceptedEventButDeclinedInvitation;

  /// No description provided for @confirmDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {groupName}?'**
  String confirmDeleteGroup(String groupName);

  /// No description provided for @failedToDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete group'**
  String get failedToDeleteGroup;

  /// No description provided for @resolveAmbiguousReconciliation.
  ///
  /// In en, this message translates to:
  /// **'Resolve ambiguous reconciliation'**
  String get resolveAmbiguousReconciliation;

  /// No description provided for @confirmResolve.
  ///
  /// In en, this message translates to:
  /// **'Confirm resolve'**
  String get confirmResolve;

  /// No description provided for @payload.
  ///
  /// In en, this message translates to:
  /// **'Payload'**
  String get payload;

  /// No description provided for @ambiguousReconciliations.
  ///
  /// In en, this message translates to:
  /// **'Ambiguous reconciliations'**
  String get ambiguousReconciliations;

  /// No description provided for @availableInDebugBuildsOnly.
  ///
  /// In en, this message translates to:
  /// **'Available in debug builds only'**
  String get availableInDebugBuildsOnly;

  /// No description provided for @noAmbiguousReconciliations.
  ///
  /// In en, this message translates to:
  /// **'No ambiguous reconciliations'**
  String get noAmbiguousReconciliations;

  /// No description provided for @deleteAmbiguousEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete ambiguous entry'**
  String get deleteAmbiguousEntry;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @resolveOptimisticToServerId.
  ///
  /// In en, this message translates to:
  /// **'Resolve optimistic {optimisticId} to server id {serverId}?'**
  String resolveOptimisticToServerId(String optimisticId, String serverId);

  /// No description provided for @contactSyncInProgress.
  ///
  /// In en, this message translates to:
  /// **'Contact sync already in progress'**
  String get contactSyncInProgress;

  /// No description provided for @contactsPermissionNotGranted.
  ///
  /// In en, this message translates to:
  /// **'Contacts permission not granted'**
  String get contactsPermissionNotGranted;

  /// No description provided for @failedToLoadInvitations.
  ///
  /// In en, this message translates to:
  /// **'Failed to load invitations'**
  String get failedToLoadInvitations;

  /// No description provided for @failedToSendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to send invitation'**
  String get failedToSendInvitation;

  /// No description provided for @failedToSendInvitations.
  ///
  /// In en, this message translates to:
  /// **'Failed to send invitations'**
  String get failedToSendInvitations;

  /// No description provided for @failedToSendGroupInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to send group invitation'**
  String get failedToSendGroupInvitation;

  /// No description provided for @failedToAcceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept invitation'**
  String get failedToAcceptInvitation;

  /// No description provided for @failedToRejectInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject invitation'**
  String get failedToRejectInvitation;

  /// No description provided for @failedToCancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel invitation'**
  String get failedToCancelInvitation;

  /// No description provided for @titleIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleIsRequired;

  /// No description provided for @endDateMustBeAfterStartDate.
  ///
  /// In en, this message translates to:
  /// **'End date/time must be after start date/time'**
  String get endDateMustBeAfterStartDate;

  /// No description provided for @failedToSaveEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to save event'**
  String get failedToSaveEvent;

  /// No description provided for @failedToLoadEventData.
  ///
  /// In en, this message translates to:
  /// **'Failed to load event data'**
  String get failedToLoadEventData;

  /// No description provided for @noInvitationFound.
  ///
  /// In en, this message translates to:
  /// **'No invitation found'**
  String get noInvitationFound;

  /// No description provided for @failedToSubmitDecision.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit decision'**
  String get failedToSubmitDecision;

  /// No description provided for @onlyEventOwnerCanEdit.
  ///
  /// In en, this message translates to:
  /// **'Only event owner can edit'**
  String get onlyEventOwnerCanEdit;

  /// No description provided for @onlyEventOwnerCanDelete.
  ///
  /// In en, this message translates to:
  /// **'Only event owner can delete'**
  String get onlyEventOwnerCanDelete;

  /// No description provided for @onlyEventOwnerCanInviteUsers.
  ///
  /// In en, this message translates to:
  /// **'Only event owner can invite users'**
  String get onlyEventOwnerCanInviteUsers;

  /// No description provided for @failedToToggleSubscription.
  ///
  /// In en, this message translates to:
  /// **'Failed to toggle subscription'**
  String get failedToToggleSubscription;

  /// No description provided for @failedToRefreshContacts.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh contacts'**
  String get failedToRefreshContacts;

  /// No description provided for @failedToLoadGroups.
  ///
  /// In en, this message translates to:
  /// **'Failed to load groups'**
  String get failedToLoadGroups;

  /// No description provided for @userNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get userNotAuthenticated;

  /// No description provided for @failedToCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to create group'**
  String get failedToCreateGroup;

  /// No description provided for @failedToAddMember.
  ///
  /// In en, this message translates to:
  /// **'Failed to add member'**
  String get failedToAddMember;

  /// No description provided for @failedToRemoveMember.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove member'**
  String get failedToRemoveMember;

  /// No description provided for @failedToLeaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave group'**
  String get failedToLeaveGroup;

  /// No description provided for @failedToGrantAdminPermission.
  ///
  /// In en, this message translates to:
  /// **'Failed to grant admin permission'**
  String get failedToGrantAdminPermission;

  /// No description provided for @failedToRemoveAdminPermission.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove admin permission'**
  String get failedToRemoveAdminPermission;

  /// No description provided for @failedToCreateContact.
  ///
  /// In en, this message translates to:
  /// **'Failed to create contact'**
  String get failedToCreateContact;

  /// No description provided for @failedToUpdateContact.
  ///
  /// In en, this message translates to:
  /// **'Failed to update contact'**
  String get failedToUpdateContact;

  /// No description provided for @failedToDeleteContact.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete contact'**
  String get failedToDeleteContact;

  /// No description provided for @failedToReadDeviceContacts.
  ///
  /// In en, this message translates to:
  /// **'Failed to read device contacts'**
  String get failedToReadDeviceContacts;

  /// No description provided for @errorFindingUsersByPhones.
  ///
  /// In en, this message translates to:
  /// **'Error finding users by phones'**
  String get errorFindingUsersByPhones;

  /// No description provided for @failedToBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to block user'**
  String get failedToBlockUser;

  /// No description provided for @failedToUnblockUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to unblock user'**
  String get failedToUnblockUser;

  /// No description provided for @failedToLoadBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load blocked users'**
  String get failedToLoadBlockedUsers;

  /// No description provided for @couldNotCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Could not create group'**
  String get couldNotCreateGroup;

  /// No description provided for @failedToFetchEvents.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch events'**
  String get failedToFetchEvents;

  /// No description provided for @failedToFetchSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch subscriptions'**
  String get failedToFetchSubscriptions;

  /// No description provided for @failedToFetchNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch notifications'**
  String get failedToFetchNotifications;

  /// No description provided for @failedToFetchGroups.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch groups'**
  String get failedToFetchGroups;

  /// No description provided for @failedToFetchContacts.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch contacts'**
  String get failedToFetchContacts;

  /// No description provided for @failedToFetchEventsHash.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch events hash'**
  String get failedToFetchEventsHash;

  /// No description provided for @failedToFetchGroupsHash.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch groups hash'**
  String get failedToFetchGroupsHash;

  /// No description provided for @failedToFetchContactsHash.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch contacts hash'**
  String get failedToFetchContactsHash;

  /// No description provided for @failedToFetchInvitationsHash.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch invitations hash'**
  String get failedToFetchInvitationsHash;

  /// No description provided for @failedToFetchSubscriptionsHash.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch subscriptions hash'**
  String get failedToFetchSubscriptionsHash;

  /// No description provided for @failedToFetchNotificationsHash.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch notifications hash'**
  String get failedToFetchNotificationsHash;

  /// No description provided for @failedToLeaveEvent.
  ///
  /// In en, this message translates to:
  /// **'Failed to leave event'**
  String get failedToLeaveEvent;

  /// No description provided for @failedToDeleteRecurringSeries.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete recurring series'**
  String get failedToDeleteRecurringSeries;

  /// No description provided for @failedToAddMemberToGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to add member to group'**
  String get failedToAddMemberToGroup;

  /// No description provided for @failedToRemoveMemberFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove member from group'**
  String get failedToRemoveMemberFromGroup;

  /// No description provided for @failedToAcceptNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept notification'**
  String get failedToAcceptNotification;

  /// No description provided for @failedToRejectNotification.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject notification'**
  String get failedToRejectNotification;

  /// No description provided for @failedToMarkNotificationAsSeen.
  ///
  /// In en, this message translates to:
  /// **'Failed to mark notification as seen'**
  String get failedToMarkNotificationAsSeen;

  /// No description provided for @failedToCreateSubscription.
  ///
  /// In en, this message translates to:
  /// **'Failed to create subscription'**
  String get failedToCreateSubscription;

  /// No description provided for @failedToDeleteSubscription.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete subscription'**
  String get failedToDeleteSubscription;

  /// No description provided for @failedToFetchEventInvitations.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch event invitations'**
  String get failedToFetchEventInvitations;

  /// No description provided for @failedToFetchUserGroups.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch user groups'**
  String get failedToFetchUserGroups;

  /// No description provided for @failedToFetchUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch users'**
  String get failedToFetchUsers;

  /// No description provided for @failedToSearchPublicUsers.
  ///
  /// In en, this message translates to:
  /// **'Failed to search public users'**
  String get failedToSearchPublicUsers;

  /// No description provided for @subscriptionIdCannotBeNull.
  ///
  /// In en, this message translates to:
  /// **'Subscription ID cannot be null'**
  String get subscriptionIdCannotBeNull;

  /// No description provided for @userIdCannotBeNull.
  ///
  /// In en, this message translates to:
  /// **'User ID cannot be null'**
  String get userIdCannotBeNull;

  /// No description provided for @failedToCreateUpdateUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to create/update user'**
  String get failedToCreateUpdateUser;

  /// No description provided for @failedToLoadCurrentUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to load current user'**
  String get failedToLoadCurrentUser;

  /// No description provided for @noCurrentUserToUpdate.
  ///
  /// In en, this message translates to:
  /// **'No current user to update'**
  String get noCurrentUserToUpdate;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @failedToUpdateFCMToken.
  ///
  /// In en, this message translates to:
  /// **'Failed to update FCM token'**
  String get failedToUpdateFCMToken;

  /// No description provided for @authUserHasNoPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Authenticated user has no phone number'**
  String get authUserHasNoPhoneNumber;

  /// No description provided for @eventsBy.
  ///
  /// In en, this message translates to:
  /// **'Events by {name}'**
  String eventsBy(String name);

  /// No description provided for @publicOrganizerEvents.
  ///
  /// In en, this message translates to:
  /// **'Public organizer events'**
  String get publicOrganizerEvents;

  /// No description provided for @errorLoadingEvents.
  ///
  /// In en, this message translates to:
  /// **'Error loading events'**
  String get errorLoadingEvents;

  /// No description provided for @changeDecision.
  ///
  /// In en, this message translates to:
  /// **'Change decision'**
  String get changeDecision;

  /// No description provided for @changeInvitationDecision.
  ///
  /// In en, this message translates to:
  /// **'Change invitation decision'**
  String get changeInvitationDecision;

  /// No description provided for @selectNewDecision.
  ///
  /// In en, this message translates to:
  /// **'Select your new decision for this event'**
  String get selectNewDecision;

  /// No description provided for @errorProcessingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Error processing invitation'**
  String get errorProcessingInvitation;

  /// Label shown on unviewed same-day events
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newLabel;

  /// Communities tab label
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get communities;

  /// Single calendar
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// Multiple calendars
  ///
  /// In en, this message translates to:
  /// **'Calendars'**
  String get calendars;

  /// User's own calendars section
  ///
  /// In en, this message translates to:
  /// **'My Calendars'**
  String get myCalendars;

  /// Calendars the user is subscribed to
  ///
  /// In en, this message translates to:
  /// **'Subscribed Calendars'**
  String get subscribedCalendars;

  /// Publicly available calendars
  ///
  /// In en, this message translates to:
  /// **'Public Calendars'**
  String get publicCalendars;

  /// Button to create a new calendar
  ///
  /// In en, this message translates to:
  /// **'Create Calendar'**
  String get createCalendar;

  /// Button to edit a calendar
  ///
  /// In en, this message translates to:
  /// **'Edit Calendar'**
  String get editCalendar;

  /// Button to delete a calendar
  ///
  /// In en, this message translates to:
  /// **'Delete Calendar'**
  String get deleteCalendar;

  /// Label for calendar name input
  ///
  /// In en, this message translates to:
  /// **'Calendar Name'**
  String get calendarName;

  /// Label for calendar description input
  ///
  /// In en, this message translates to:
  /// **'Calendar Description'**
  String get calendarDescription;

  /// Label for calendar color picker
  ///
  /// In en, this message translates to:
  /// **'Calendar Color'**
  String get calendarColor;

  /// Checkbox label for calendar deletion behavior
  ///
  /// In en, this message translates to:
  /// **'Delete associated events when removing calendar'**
  String get deleteAssociatedEvents;

  /// Button to subscribe to a public calendar
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribeToCalendar;

  /// Button to unsubscribe from a calendar
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get unsubscribeFromCalendar;

  /// Placeholder for calendar search input
  ///
  /// In en, this message translates to:
  /// **'Search public calendars'**
  String get searchPublicCalendars;

  /// Empty state message when user has no calendars
  ///
  /// In en, this message translates to:
  /// **'No calendars yet'**
  String get noCalendarsYet;

  /// Checkbox label in event form
  ///
  /// In en, this message translates to:
  /// **'Associate with Calendar'**
  String get associateWithCalendar;

  /// Validation error when calendar name is empty
  ///
  /// In en, this message translates to:
  /// **'Calendar name is required'**
  String get calendarNameRequired;

  /// Validation error when calendar name exceeds limit
  ///
  /// In en, this message translates to:
  /// **'Calendar name must be 100 characters or less'**
  String get calendarNameTooLong;

  /// Validation error when description exceeds limit
  ///
  /// In en, this message translates to:
  /// **'Description must be 500 characters or less'**
  String get calendarDescriptionTooLong;

  /// Error message for no internet connection
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network and try again.'**
  String get noInternetCheckNetwork;

  /// Error message when request times out
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get requestTimedOut;

  /// Error message for server errors
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// Error when calendar name is duplicated
  ///
  /// In en, this message translates to:
  /// **'A calendar with this name already exists.'**
  String get calendarNameExists;

  /// Error when user lacks permissions
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get noPermission;

  /// Error when calendar creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create calendar. Please try again.'**
  String get failedToCreateCalendar;

  /// Label for public calendar toggle
  ///
  /// In en, this message translates to:
  /// **'Public Calendar'**
  String get publicCalendar;

  /// Description for public calendar feature
  ///
  /// In en, this message translates to:
  /// **'Others can search and subscribe'**
  String get othersCanSearchAndSubscribe;

  /// Option to delete events when calendar is deleted
  ///
  /// In en, this message translates to:
  /// **'Delete events when this calendar is deleted'**
  String get deleteEventsWithCalendar;

  /// Warning when deleting calendar with events
  ///
  /// In en, this message translates to:
  /// **'This will delete the calendar and all associated events. This action cannot be undone.'**
  String get confirmDeleteCalendarWithEvents;

  /// Warning when deleting calendar without events
  ///
  /// In en, this message translates to:
  /// **'This will delete the calendar but keep the events. This action cannot be undone.'**
  String get confirmDeleteCalendarKeepEvents;

  /// Status text for public calendar
  ///
  /// In en, this message translates to:
  /// **'Visible to others'**
  String get visibleToOthers;

  /// Status text for private calendar
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// Status for cascade delete option
  ///
  /// In en, this message translates to:
  /// **'Events will be deleted with calendar'**
  String get eventsWillBeDeleted;

  /// Status for keeping events when deleting calendar
  ///
  /// In en, this message translates to:
  /// **'Events will be kept when calendar is deleted'**
  String get eventsWillBeKept;

  /// Error when calendar doesn't exist
  ///
  /// In en, this message translates to:
  /// **'Calendar not found'**
  String get calendarNotFound;

  /// Error when loading calendar fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load calendar'**
  String get failedToLoadCalendar;

  /// Toggle for birthday events
  ///
  /// In en, this message translates to:
  /// **'Is Birthday'**
  String get isBirthday;

  /// Icon displayed for birthday events
  ///
  /// In en, this message translates to:
  /// **'🎂'**
  String get birthdayIcon;

  /// Dropdown placeholder for calendar selection
  ///
  /// In en, this message translates to:
  /// **'Select Calendar'**
  String get selectCalendar;

  /// Label for invitation status field in event detail
  ///
  /// In en, this message translates to:
  /// **'Invitation Status'**
  String get invitationStatus;

  /// Header for invitation status change buttons section
  ///
  /// In en, this message translates to:
  /// **'Change Invitation Status'**
  String get changeInvitationStatus;

  /// Label for button to attend event independently (declining invitation but attending)
  ///
  /// In en, this message translates to:
  /// **'Attend Independently'**
  String get attendIndependently;

  /// Placeholder for calendar search field
  ///
  /// In en, this message translates to:
  /// **'Search calendars...'**
  String get searchCalendars;

  /// Placeholder for birthday search field
  ///
  /// In en, this message translates to:
  /// **'Search birthdays...'**
  String get searchBirthdays;

  /// Empty state message when calendar search returns no results
  ///
  /// In en, this message translates to:
  /// **'No calendars found'**
  String get noCalendarsFound;

  /// Empty state message when user has no calendars
  ///
  /// In en, this message translates to:
  /// **'No calendars'**
  String get noCalendars;

  /// Empty state message when birthday search returns no results
  ///
  /// In en, this message translates to:
  /// **'No birthdays found'**
  String get noBirthdaysFound;

  /// Empty state message when user has no birthday events
  ///
  /// In en, this message translates to:
  /// **'No birthdays'**
  String get noBirthdays;

  /// Plural form for birthday events, menu option
  ///
  /// In en, this message translates to:
  /// **'Birthdays'**
  String get birthdays;

  /// Single birthday event
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// Badge label for default calendar
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultCalendar;

  /// Generic error message when data fails to load
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoadingData;

  /// Label for birthday timing (e.g., 'in 5 days')
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String inDays(int days);

  /// Label for birthday timing exactly one week away
  ///
  /// In en, this message translates to:
  /// **'in 1 week'**
  String get inOneWeek;

  /// Label for birthday timing (e.g., 'in 3 weeks')
  ///
  /// In en, this message translates to:
  /// **'in {weeks} weeks'**
  String inWeeks(int weeks);

  /// Label for birthday timing exactly one month away
  ///
  /// In en, this message translates to:
  /// **'in 1 month'**
  String get inOneMonth;

  /// Label for birthday timing (e.g., 'in 2 months')
  ///
  /// In en, this message translates to:
  /// **'in {months} months'**
  String inMonths(int months);

  /// Label for birthday timing exactly one year away
  ///
  /// In en, this message translates to:
  /// **'in 1 year'**
  String get inOneYear;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
