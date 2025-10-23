import 'package:flutter/widgets.dart';

class EventListSeparator extends StatelessWidget {
  final double height;
  const EventListSeparator({super.key, this.height = 8.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}
