import 'package:flutter/widgets.dart';
import '../config/app_constants.dart';
import 'limited_text_field.dart';

class EventBasicFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String? Function(String?)? titleValidator;
  final String? Function(String?)? descriptionValidator;
  final void Function(String)? onTitleChanged;
  final void Function(String)? onDescriptionChanged;
  final bool enabled;

  const EventBasicFields({
    super.key,
    required this.titleController,
    required this.descriptionController,
    this.titleValidator,
    this.descriptionValidator,
    this.onTitleChanged,
    this.onDescriptionChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventTitleField(
          controller: titleController,
          validator: titleValidator,
          onChanged: onTitleChanged,
        ),

        const SizedBox(height: AppConstants.defaultPadding),

        EventDescriptionField(
          controller: descriptionController,
          validator: descriptionValidator,
          onChanged: onDescriptionChanged,
        ),
      ],
    );
  }
}

extension EventBasicFieldsExtension on EventBasicFields {
  bool validate() {
    bool isValid = true;

    if (titleValidator != null) {
      final titleError = titleValidator!(titleController.text);
      if (titleError != null) isValid = false;
    }

    if (descriptionValidator != null) {
      final descriptionError = descriptionValidator!(
        descriptionController.text,
      );
      if (descriptionError != null) isValid = false;
    }

    return isValid;
  }

  String get title => titleController.text.trim();

  String get description => descriptionController.text.trim();

  void clear() {
    titleController.clear();
    descriptionController.clear();
  }
}
