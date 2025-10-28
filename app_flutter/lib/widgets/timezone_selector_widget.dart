import 'package:flutter/cupertino.dart';
import '../config/timezone_data.dart';
import '../services/timezone_service.dart';

class TimezoneSelectorWidget extends StatelessWidget {
  final String selectedTimezone;
  final Function(String timezone, String city) onTimezoneChanged;

  const TimezoneSelectorWidget({super.key, required this.selectedTimezone, required this.onTimezoneChanged});

  String _formatDisplay() {
    final city = TimezoneData.getCityFromTimezone(selectedTimezone) ?? selectedTimezone;
    final offset = TimezoneService.getCurrentOffset(selectedTimezone);
    return '$city ($offset)';
  }

  Future<void> _showTimezonePicker(BuildContext context) async {
    final timezones = TimezoneData.getTimezoneList();

    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: [
            const Text('Seleccionar Zona Horaria', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                itemCount: timezones.length,
                itemBuilder: (context, index) {
                  final tz = timezones[index];
                  final timezone = tz['timezone']!;
                  final city = tz['city']!;
                  final offset = TimezoneService.getCurrentOffset(timezone);
                  final isSelected = timezone == selectedTimezone;

                  return GestureDetector(
                    onTap: () {
                      onTimezoneChanged(timezone, city);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: isSelected ? CupertinoColors.systemGrey5 : null, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(city, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                Text(offset, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                              ],
                            ),
                          ),
                          if (isSelected) const Icon(CupertinoIcons.check_mark, color: CupertinoColors.activeBlue),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTimezonePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.globe, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(_formatDisplay(), style: const TextStyle(fontSize: 16))),
            const Icon(CupertinoIcons.chevron_down, size: 20),
          ],
        ),
      ),
    );
  }
}
