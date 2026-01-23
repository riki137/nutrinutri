import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateSwitcher extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<int> onDateChange;

  const DateSwitcher({
    super.key,
    required this.selectedDate,
    required this.onDateChange,
  });

  bool get _isToday {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onDateChange(-1),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _isToday ? "Today" : DateFormat('EEEE').format(selectedDate),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('d MMM y').format(selectedDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _isToday ? null : () => onDateChange(1),
          ),
        ],
      ),
    );
  }
}
