import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventypop/ui/styles/app_styles.dart';
import '../models/domain/user.dart';
import 'package:eventypop/ui/helpers/l10n/l10n_helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/state/app_state.dart';

class UserAvatar extends ConsumerWidget {
  final User user;
  final double radius;
  final bool showOnlineIndicator;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 20,
    this.showOnlineIndicator = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoAsync = ref.watch(logoPathProvider(user.id));
    final localPath = logoAsync.value;
    return Stack(
      children: [
        if (localPath != null)
          _buildLocalAvatar(localPath)
        else
          _buildAvatar(context),
      ],
    );
  }

  Widget _buildLocalAvatar(String path) {
    return ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: FileImage(File(path)),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final profilePicture = user.profilePictureUrl;

    if (profilePicture == null || profilePicture.isEmpty) {
      return _buildInitialsAvatar(context);
    }

    return CachedNetworkImage(
      imageUrl: profilePicture,
      imageBuilder: (context, imageProvider) => ClipOval(
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            shape: BoxShape.circle,
          ),
        ),
      ),
      placeholder: (context, url) => _buildInitialsAvatar(context),
      errorWidget: (context, url, error) => _buildInitialsAvatar(context),
    );
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    final color = _generateColorFromName(user.displayName);

    return ClipOval(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(
          _getInitials(context, user.displayName),
          style: AppStyles.headlineSmall.copyWith(
            fontSize: radius * 0.6,
            fontWeight: FontWeight.w600,
            color: AppStyles.white,
          ),
        ),
      ),
    );
  }

  String _getInitials(BuildContext context, String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return context.l10n.avatarUnknownInitial;
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Color _generateColorFromName(String name) {
    final colors = [
      AppStyles.blue600,
      AppStyles.green600,
      AppStyles.orange600,
      AppStyles.purple600,
      AppStyles.red600,
      AppStyles.teal600,
      AppStyles.indigo600,
      AppStyles.pink600,
      AppStyles.amber600,
      AppStyles.cyan600,
    ];

    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }

    return colors[hash.abs() % colors.length];
  }
}
