import 'package:flutter/cupertino.dart';

class PlatformRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Widget? sliverChild;

  const PlatformRefresh({super.key, required this.child, required this.onRefresh, this.sliverChild});

  @override
  Widget build(BuildContext context) {
    if (sliverChild != null) {
      return CustomScrollView(physics: const ClampingScrollPhysics(), slivers: [sliverChild!]);
    } else {
      if (child is ScrollView) {
        return child;
      } else {
        return CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [SliverFillRemaining(child: child)],
        );
      }
    }
  }
}

class PlatformRefreshSlivers extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final List<Widget> slivers;

  const PlatformRefreshSlivers({super.key, required this.onRefresh, required this.slivers});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(physics: const ClampingScrollPhysics(), slivers: [...slivers]);
  }
}

class PlatformScrollView extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function() onRefresh;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const PlatformScrollView({super.key, required this.children, required this.onRefresh, this.padding, this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      controller: controller,
      slivers: [
        SliverPadding(
          padding: padding ?? EdgeInsets.zero,
          sliver: SliverList(delegate: SliverChildListDelegate(children)),
        ),
      ],
    );
  }
}

class PlatformListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Future<void> Function() onRefresh;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const PlatformListView({super.key, required this.itemCount, required this.itemBuilder, required this.onRefresh, this.padding, this.controller});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      controller: controller,
      slivers: [
        SliverPadding(
          padding: padding ?? EdgeInsets.zero,
          sliver: SliverList(delegate: SliverChildBuilderDelegate(itemBuilder, childCount: itemCount)),
        ),
      ],
    );
  }
}

class _NonMaterialRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const _NonMaterialRefreshWrapper({required this.child, required this.onRefresh});

  @override
  State<_NonMaterialRefreshWrapper> createState() => _NonMaterialRefreshWrapperState();
}

class _NonMaterialRefreshWrapperState extends State<_NonMaterialRefreshWrapper> {
  bool _refreshing = false;
  DateTime _lastTrigger = DateTime.fromMillisecondsSinceEpoch(0);

  static const _minInterval = Duration(milliseconds: 800);

  Future<void> _maybeTrigger() async {
    final now = DateTime.now();
    if (_refreshing) return;
    if (now.difference(_lastTrigger) < _minInterval) return;
    _lastTrigger = now;
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is OverscrollNotification && notification.overscroll < 0 && notification.metrics.pixels <= 0) {
          _maybeTrigger();
        }
        return false;
      },
      child: Stack(
        children: [
          ScrollConfiguration(behavior: const CupertinoScrollBehavior(), child: widget.child),
          if (_refreshing)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(child: SizedBox(width: 18, height: 18, child: const CupertinoActivityIndicator(radius: 9))),
            ),
        ],
      ),
    );
  }
}
