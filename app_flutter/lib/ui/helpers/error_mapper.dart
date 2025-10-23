import 'package:flutter/widgets.dart';
import '../../utils/app_exceptions.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';

String mapAppExceptionToMessage(BuildContext context, AppException ex) {
  final l10n = context.l10n;
  return mapAppExceptionToMessageWithL10n(l10n, ex);
}

String mapAppExceptionToMessageWithL10n(dynamic l10n, AppException ex) {
  if (ex is ConflictException &&
      ex.message.contains('All group members already invited')) {
    return l10n.allGroupMembersAlreadyInvited;
  }

  if (ex is OfflineException) return l10n.noInternetConnection;
  if (ex is PermissionDeniedException) {
    try {
      final dyn = l10n as dynamic;
      return dyn.permissionDeniedContacts ?? l10n.unexpectedError;
    } catch (_) {
      return l10n.unexpectedError;
    }
  }
  if (ex is ValidationException) return ex.message;
  if (ex is NotFoundException) return l10n.noData;
  if (ex is ApiException || ex is NetworkException) return l10n.connectionError;

  return l10n.unexpectedError;
}

String mapInvitationProviderError(dynamic l10n, String key) {
  try {
    switch (key) {
      case 'errorLoadingInvitations':
        return (l10n as dynamic).errorLoadingInvitations;
      case 'invitationNotFound':
        return (l10n as dynamic).invitationNotFound;
      case 'errorSendingInvitation':
        return (l10n as dynamic).errorSendingInvitations ??
            (l10n as dynamic).unexpectedError;
      case 'errorSendingGroupInvitation':
        return (l10n as dynamic).errorSendingInvitations ??
            (l10n as dynamic).unexpectedError;
      case 'errorAcceptingInvitation':
      case 'errorRejectingInvitation':
      case 'errorCancellingInvitation':
        return (l10n as dynamic).unexpectedError;
      default:
        return (l10n as dynamic).unexpectedError;
    }
  } catch (_) {
    try {
      return (l10n as dynamic).unexpectedError;
    } catch (_) {
      return 'ERR_FALLBACK';
    }
  }
}
