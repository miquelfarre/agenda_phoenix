import 'package:eventypop/ui/helpers/platform/platform_detection.dart';
import 'package:flutter/cupertino.dart';
import 'package:eventypop/ui/helpers/platform/platform_widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<AdaptiveNavigationItem> navigationItems;
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? leading;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.title,
    required this.navigationItems,
    required this.currentIndex,
    required this.onNavigationChanged,
    this.actions,
    this.floatingActionButton,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformDetection.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: title != null
            ? CupertinoNavigationBar(
                transitionBetweenRoutes: false,
                middle: Text(title!),
                leading: leading,
                trailing: actions != null && actions!.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!.take(2).toList(),
                      )
                    : null,
              )
            : null,
        child: SafeArea(
          top: title == null,
          child: Column(
            children: [
              Expanded(child: body),
              CupertinoTabBar(
                items: navigationItems
                    .map(
                      (item) => BottomNavigationBarItem(
                        icon: PlatformWidgets.platformIcon(
                          item.icon,
                          color: AppStyles.grey600,
                        ),
                        activeIcon: PlatformWidgets.platformIcon(
                          item.activeIcon ?? item.icon,
                          color: AppStyles.blue600,
                        ),
                        label: item.label,
                      ),
                    )
                    .toList(),
                currentIndex: currentIndex,
                onTap: onNavigationChanged,
              ),
            ],
          ),
        ),
      );
    } else {
      return SafeArea(
        child: Column(
          children: [
            if (title != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: AppStyles.blue600,
                child: Row(
                  children: [
                    if (leading != null) leading!,
                    Expanded(
                      child: Text(
                        title!,
                        style: AppStyles.headlineSmall.copyWith(
                          color: AppStyles.white,
                        ),
                      ),
                    ),
                    if (actions != null && actions!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!.take(2).toList(),
                      ),
                  ],
                ),
              ),
            Expanded(child: body),
            if (navigationItems.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: AppStyles.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.colorWithOpacity(AppStyles.black, 0.06),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: navigationItems.map((item) {
                    final index = navigationItems.indexOf(item);
                    final selected = index == currentIndex;
                    return GestureDetector(
                      key: Key(
                        'adaptive_scaffold_nav_item_${item.label.replaceAll(' ', '_').toLowerCase()}',
                      ),
                      onTap: () => onNavigationChanged(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PlatformWidgets.platformIcon(
                              item.icon,
                              color: selected
                                  ? AppStyles.blue600
                                  : AppStyles.grey600,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.label,
                              style: AppStyles.bodyText.copyWith(
                                color: selected
                                    ? AppStyles.blue600
                                    : AppStyles.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            if (floatingActionButton != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: floatingActionButton,
              ),
          ],
        ),
      );
    }
  }
}

const double _kToolbarHeight = 56.0;

class AdaptiveNavigationItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final Widget screen;

  const AdaptiveNavigationItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.screen,
  });
}

class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onLeadingPressed;
  final bool automaticallyImplyLeading;

  const AdaptiveAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.onLeadingPressed,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformDetection.isIOS) {
      return CupertinoNavigationBar(
        middle: Text(title),
        leading:
            leading ??
            (automaticallyImplyLeading && Navigator.canPop(context)
                ? CupertinoNavigationBarBackButton(
                    onPressed:
                        onLeadingPressed ??
                        () {
                          Navigator.of(context).pop();
                        },
                  )
                : null),
        trailing: actions != null && actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!.take(2).toList(),
              )
            : null,
      );
    } else {
      return Container(
        height: 56,
        color: AppStyles.blue600,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            if (leading != null) leading!,
            Expanded(
              child: Text(
                title,
                style: AppStyles.headlineSmall.copyWith(color: AppStyles.white),
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!.take(2).toList(),
              ),
          ],
        ),
      );
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(_kToolbarHeight);
}

class AdaptivePageScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? floatingActionButton;

  const AdaptivePageScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformDetection.isIOS) {
      return CupertinoPageScaffold(
        navigationBar: title != null
            ? CupertinoNavigationBar(
                transitionBetweenRoutes: false,
                middle: Text(title!),
                leading:
                    leading ??
                    (automaticallyImplyLeading && Navigator.canPop(context)
                        ? CupertinoNavigationBarBackButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          )
                        : null),
                trailing: actions != null && actions!.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!.take(2).toList(),
                      )
                    : null,
              )
            : null,
        child: body,
      );
    } else {
      return SafeArea(
        child: Column(
          children: [
            if (title != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: AppStyles.blue600,
                child: Row(
                  children: [
                    if (leading != null) leading!,
                    Expanded(
                      child: Text(
                        title!,
                        style: AppStyles.headlineSmall.copyWith(
                          color: AppStyles.white,
                        ),
                      ),
                    ),
                    if (actions != null && actions!.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!.take(2).toList(),
                      ),
                  ],
                ),
              ),
            Expanded(child: body),
            if (floatingActionButton != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: floatingActionButton,
              ),
          ],
        ),
      );
    }
  }
}
