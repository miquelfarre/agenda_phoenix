import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/auth_service.dart';
import '../../services/config_service.dart';
import '../../services/country_service.dart';
import '../../models/country.dart';
import '../../widgets/pickers/country_picker.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:eventypop/widgets/adaptive/adaptive_button.dart';
import 'package:eventypop/widgets/adaptive/configs/button_config.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import '../../widgets/adaptive_scaffold.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'dart:io';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  String _verificationId = '';
  bool _codeSent = false;
  bool _isLoading = false;

  late Country _selectedCountry;

  @override
  void initState() {
    super.initState();
    _initializeCountry();
  }

  Future<void> _initializeCountry() async {
    String? countryCode;
    try {
      final localeString = Platform.localeName;
      if (localeString.contains('_')) {
        countryCode = localeString.split('_').last;
      } else if (localeString.length == 2) {
        countryCode = localeString.toUpperCase();
      }
    } catch (e) {}

    setState(() {
      _selectedCountry =
          CountryService.getCountryByCode(countryCode ?? 'ES') ??
          CountryService.getCountryByCode('ES')!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isIOS = PlatformDetection.isIOS;

    return AdaptivePageScaffold(
      key: const Key('phone_login_screen_scaffold'),
      title: l10n.login,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformWidgets.platformIcon(
              CupertinoIcons.phone,
              size: 80,
              color: isIOS
                  ? CupertinoColors.activeBlue.resolveFrom(context)
                  : AppStyles.blue600,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.loginWithPhone,
              style: isIOS
                  ? AppStyles.headlineSmall.copyWith(
                      color: CupertinoColors.label.resolveFrom(context),
                      fontSize: 24,
                    )
                  : AppStyles.headlineSmall.copyWith(
                      color: AppStyles.black87,
                      fontSize: 24,
                    ),
            ),
            const SizedBox(height: 30),

            if (!_codeSent) ...[
              Row(
                children: [
                  GestureDetector(
                    key: const Key('phone_login_country_selector'),
                    onTap: _showCountryPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isIOS
                              ? CupertinoColors.systemGrey4.resolveFrom(context)
                              : AppStyles.grey300,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedCountry.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _selectedCountry.dialCode,
                            style: isIOS
                                ? AppStyles.bodyText.copyWith(
                                    color: CupertinoColors.label.resolveFrom(
                                      context,
                                    ),
                                  )
                                : AppStyles.bodyText,
                          ),
                          const SizedBox(width: 4),
                          PlatformWidgets.platformIcon(
                            CupertinoIcons.chevron_down,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    child: PlatformWidgets.platformTextField(
                      controller: _phoneController,
                      placeholder: l10n.phone,
                      hintText: '626034421',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AdaptiveButton(
                  key: const Key('phone_login_send_sms_button'),
                  config: AdaptiveButtonConfigExtended.submit(),
                  text: l10n.sendSmsCode,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _sendOTP,
                ),
              ),
            ] else ...[
              Text(
                l10n.codeSentTo(
                  '${_selectedCountry.dialCode}${_phoneController.text}',
                ),
                style: isIOS
                    ? AppStyles.bodyText.copyWith(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                        fontSize: 16,
                      )
                    : AppStyles.bodyText.copyWith(
                        color: AppStyles.grey600,
                        fontSize: 16,
                      ),
              ),
              const SizedBox(height: 20),
              PlatformWidgets.platformTextField(
                controller: _codeController,
                placeholder: l10n.smsCode,
                hintText: l10n.smsCodeHintExample,
                prefixIcon: PlatformWidgets.platformIcon(CupertinoIcons.lock),
                keyboardType: TextInputType.number,
                maxLines: 1,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: AdaptiveButton(
                  key: const Key('phone_login_verify_code_button'),
                  config: AdaptiveButtonConfigExtended.submit(),
                  text: l10n.verifyCode,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _verifyOTP,
                ),
              ),
              AdaptiveButton(
                key: const Key('phone_login_change_number_button'),
                config: AdaptiveButtonConfig.secondary(),
                text: l10n.changeNumber,
                onPressed: () {
                  setState(() {
                    _codeSent = false;
                    _verificationId = '';
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() async {
    final result = await showCupertinoModalPopup<Country>(
      context: context,
      builder: (context) => CountryPickerModal(
        initialCountry: _selectedCountry,
        showOffset: false,
        onSelected: (country) {
          setState(() {
            _selectedCountry = country;
          });
          Navigator.of(context).pop(country);
        },
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCountry = result;
      });
    }
  }

  Future<void> _sendOTP() async {
    setState(() => _isLoading = true);

    final phoneNumber =
        '${_selectedCountry.dialCode}${_phoneController.text.trim()}';

    final isIOSSimulator =
        PlatformDetection.isIOS &&
        (const bool.fromEnvironment('dart.vm.product') != true);

    if (isIOSSimulator) {
      if (!mounted) return;

      final l10n = context.l10n;

      final result = await PlatformDialogHelpers.showPlatformConfirmDialog(
        context,
        title: l10n.iosSimulatorDetected,
        message:
            'Firebase Phone Auth is not supported on iOS Simulator.\n\n'
            'For testing, we will use a mock authentication flow.\n\n'
            'Press "Continue" to proceed with test user ID 21 (Kate Bell).',
        confirmText: 'Continue with Test User',
        cancelText: l10n.cancel,
      );

      if (result == true) {
        await _performTestAuthentication();
      }

      setState(() => _isLoading = false);
      return;
    }

    try {
      await FirebaseAuthService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuthService.signInWithPhoneCredential(credential);
            await _onAuthSuccess();
          } catch (e) {
            if (mounted && context.mounted) {
              final l10n = context.l10n;
              PlatformDialogHelpers.showSnackBar(
                context: context,
                message: l10n.automaticVerificationError,
                isError: true,
              );
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted || !context.mounted) return;
          final l10n = context.l10n;
          String errorMessage = l10n.verificationError;

          switch (e.code) {
            case 'simulator-not-supported':
              errorMessage = e.message ?? l10n.firebasePhoneAuthSimulatorError;
              break;
            case 'invalid-phone-number':
              errorMessage = l10n.invalidPhone;
              break;
            case 'too-many-requests':
              errorMessage = l10n.tooManyRequests;
              break;
            case 'operation-not-allowed':
              errorMessage = l10n.operationNotAllowed;
              break;
            default:
              errorMessage = e.message ?? l10n.unexpectedError;
          }

          PlatformDialogHelpers.showSnackBar(
            context: context,
            message: errorMessage,
            isError: true,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
          });
          if (mounted && context.mounted) {
            final l10n = context.l10n;
            PlatformDialogHelpers.showSnackBar(
              context: context,
              message: l10n.smsCodeSentTo(_phoneController.text),
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted || !context.mounted) return;
      final l10n = context.l10n;
      String errorMessage = l10n.errorSendingCode;

      if (e is FirebaseAuthException && e.code == 'simulator-not-supported') {
        errorMessage = e.message ?? errorMessage;
        _showSimulatorDialog();
      } else {
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: errorMessage,
          isError: true,
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _verifyOTP() async {
    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _codeController.text.trim(),
      );

      await FirebaseAuthService.signInWithPhoneCredential(credential);
      await _onAuthSuccess();
    } catch (e) {
      if (!mounted || !context.mounted) return;
      final l10n = context.l10n;
      String errorMessage = l10n.incorrectCode;

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-verification-code':
            errorMessage = l10n.invalidVerificationCode;
            break;
          case 'session-expired':
            errorMessage = l10n.sessionExpired;
            break;
          default:
            errorMessage = e.message ?? l10n.errorVerifyingCode;
        }
      }

      PlatformDialogHelpers.showSnackBar(
        context: context,
        message: errorMessage,
        isError: true,
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _onAuthSuccess() async {
    try {
      final idToken = await FirebaseAuthService.getCurrentUserToken();
      if (idToken == null) {
        if (mounted && context.mounted) {
          final l10n = context.l10n;
          throw Exception(l10n.couldNotGetFirebaseToken);
        } else {
          throw Exception('Could not get Firebase token');
        }
      }

      final auth = AuthService();
      final user = await auth.verifyTokenAndFetchUser(idToken);

      await ConfigService.instance.setCurrentUserId(user.id);

      try {
        await auth.updateUserOnlineStatus(user.id, true);
      } catch (e) {}

      if (mounted && context.mounted) {
        try {
          context.go('/events');
        } catch (navError) {
          try {
            context.go('/splash');
          } catch (e) {}
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        final l10n = context.l10n;
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: l10n.errorCompletingRegistrationWithMessage(e.toString()),
          isError: true,
        );
      }
    }
  }

  Future<void> _performTestAuthentication() async {
    try {
      const int testUserId = int.fromEnvironment(
        'TEST_USER_ID',
        defaultValue: 24,
      );

      ConfigService.instance.enableTestMode();

      await ConfigService.instance.setCurrentUserId(testUserId);

      if (mounted && context.mounted) {
        try {
          context.go('/events');
        } catch (navError) {
          try {
            context.go('/splash');
          } catch (e) {}
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        PlatformDialogHelpers.showSnackBar(
          context: context,
          message: 'Test authentication failed: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _showSimulatorDialog() {
    final l10n = context.l10n;

    final message = [
      l10n.firebasePhoneAuthLimitationMessage,
      l10n.testPhoneAuthInstructions,
      l10n.usePhysicalIosDevice,
      l10n.useAndroidEmulator,
      l10n.useWebVersion,
    ].join('\n\n');

    PlatformDialogHelpers.showPlatformConfirmDialog(
      context,
      title: l10n.iosSimulatorDetected,
      message: message,
      confirmText: l10n.understood,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}
