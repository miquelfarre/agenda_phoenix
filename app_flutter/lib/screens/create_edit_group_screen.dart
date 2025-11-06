import 'package:flutter/cupertino.dart';
import '../models/group.dart';
import '../services/config_service.dart';
import '../ui/helpers/l10n/l10n_helpers.dart';
import '../ui/styles/app_styles.dart';
import 'base/base_form_screen.dart';
import '../core/state/app_state.dart';
import 'package:eventypop/ui/helpers/platform/dialog_helpers.dart';

class CreateEditGroupScreen extends BaseFormScreen {
  final Group? group;

  const CreateEditGroupScreen({super.key, this.group});

  @override
  CreateEditGroupScreenState createState() => CreateEditGroupScreenState();
}

class CreateEditGroupScreenState extends BaseFormScreenState<CreateEditGroupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool get isEditMode => widget.group != null;
  int get currentUserId => ConfigService.instance.currentUserId;

  @override
  void initializeFormData() {
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  String get screenTitle => isEditMode ? context.l10n.editGroup : context.l10n.createGroup;

  @override
  String get submitButtonText => isEditMode ? context.l10n.saveChanges : context.l10n.createGroup;

  @override
  bool get showSaveInNavBar => false;

  @override
  Future<bool> validateForm() async {
    final l10n = context.l10n;

    if (_nameController.text.trim().isEmpty) {
      setFieldError('name', l10n.fieldRequired(l10n.groupName));
      return false;
    }

    return true;
  }

  @override
  Future<bool> submitForm() async {
    try {
      final repo = ref.read(groupRepositoryProvider);

      if (isEditMode) {
        await repo.updateGroup(
          groupId: widget.group!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );
      } else {
        await repo.createGroup(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        );
      }

      ref.invalidate(groupsStreamProvider);
      return true;
    } catch (e) {
      if (mounted) {
        setError('Error: $e');
      }
      return false;
    }
  }

  @override
  void onFormSubmitSuccess() {
    final l10n = context.l10n;
    PlatformDialogHelpers.showSnackBar(
      message: isEditMode ? l10n.groupUpdated : l10n.groupCreated,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  List<Widget> buildFormFields() {
    final l10n = context.l10n;
    return [
      buildTextField(
        fieldName: 'name',
        label: l10n.groupName,
        placeholder: l10n.groupNamePlaceholder,
        controller: _nameController,
        required: true,
      ),
      const SizedBox(height: 16),
      buildTextField(
        fieldName: 'description',
        label: l10n.description,
        placeholder: l10n.groupDescriptionPlaceholder,
        controller: _descriptionController,
        maxLines: 3,
      ),
      if (isEditMode && widget.group!.canManageGroup(currentUserId)) ...[
        const SizedBox(height: 32),
        _buildDeleteSection(),
      ],
    ];
  }

  Widget _buildDeleteSection() {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppStyles.colorWithOpacity(AppStyles.errorColor, 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppStyles.colorWithOpacity(AppStyles.errorColor, 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.delete,
                color: AppStyles.errorColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.deleteGroup,
                style: AppStyles.bodyText.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.deleteGroupConfirmation,
            style: AppStyles.bodyText.copyWith(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              key: const Key('edit_group_delete_button'),
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: AppStyles.errorColor,
              borderRadius: BorderRadius.circular(12),
              onPressed: _showDeleteConfirmation,
              child: Text(
                l10n.deleteGroup,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation() async {
    final l10n = context.l10n;

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l10n.deleteGroup),
        content: Text(l10n.deleteGroupConfirmation),
        actions: [
          CupertinoDialogAction(
            key: const Key('delete_group_cancel_button'),
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          CupertinoDialogAction(
            key: const Key('delete_group_confirm_button'),
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteGroup();
    }
  }

  Future<void> _deleteGroup() async {
    try {
      final repo = ref.read(groupRepositoryProvider);
      await repo.deleteGroup(groupId: widget.group!.id);

      ref.invalidate(groupsStreamProvider);

      if (mounted) {
        final l10n = context.l10n;
        PlatformDialogHelpers.showSnackBar(message: l10n.groupDeleted);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setError('${context.l10n.failedToDeleteGroup}: $e');
      }
    }
  }
}
