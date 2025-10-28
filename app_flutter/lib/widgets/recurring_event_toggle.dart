import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import '../config/app_constants.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:eventypop/ui/styles/app_styles.dart';

class RecurringEventToggle extends StatelessWidget {
  final String? labelText;
  final String? helperText;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const RecurringEventToggle({super.key, this.labelText, this.helperText, required this.value, required this.onChanged, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final isIOS = PlatformDetection.isIOS;

    if (isIOS) {
      return _buildCupertinoToggle(context);
    } else {
      return _buildMaterialToggle(context);
    }
  }

  Widget _buildMaterialToggle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelText ?? context.l10n.recurringEvent,
                    style: AppStyles.bodyText.copyWith(fontSize: AppConstants.bodyFontSize, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    helperText ?? context.l10n.recurringEventHelperText,
                    style: AppStyles.bodyTextSmall.copyWith(fontSize: AppConstants.captionFontSize, color: AppStyles.grey600),
                  ),
                ],
              ),
            ),
            PlatformWidgets.platformSwitch(value: value, onChanged: enabled ? onChanged : null),
          ],
        ),
      ],
    );
  }

  Widget _buildCupertinoToggle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelText ?? context.l10n.recurringEvent,
                    style: TextStyle(fontSize: AppConstants.bodyFontSize, fontWeight: FontWeight.w500, color: CupertinoColors.label.resolveFrom(context), decoration: TextDecoration.none),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    helperText ?? context.l10n.recurringEventHelperText,
                    style: TextStyle(fontSize: AppConstants.captionFontSize, color: CupertinoColors.secondaryLabel.resolveFrom(context), decoration: TextDecoration.none),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(value: value, onChanged: enabled ? onChanged : null),
          ],
        ),
      ],
    );
  }
}
