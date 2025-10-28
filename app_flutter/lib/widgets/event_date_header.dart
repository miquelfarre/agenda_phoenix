import 'package:flutter/widgets.dart';
import 'package:eventypop/ui/styles/app_styles.dart';

class EventDateHeader extends StatelessWidget {
  final String text;
  const EventDateHeader({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        text,
        style: AppStyles.headlineSmall.copyWith(color: AppStyles.grey700, fontWeight: FontWeight.bold),
      ),
    );
  }
}
