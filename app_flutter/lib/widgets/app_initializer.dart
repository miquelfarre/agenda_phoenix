import 'package:flutter/widgets.dart';

/// AppInitializer is now simplified since all repository initialization
/// happens in the SplashScreen before navigation.
/// This widget now just passes through to its child.
class AppInitializer extends StatelessWidget {
  final Widget child;

  const AppInitializer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
