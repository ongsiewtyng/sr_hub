// lib/utils/date_input_formatter.dart
import 'package:flutter/services.dart';

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;

    // Remove any non-digit characters except slashes
    String digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    // Limit to 8 digits (ddmmyyyy)
    if (digitsOnly.length > 8) {
      digitsOnly = digitsOnly.substring(0, 8);
    }

    String formatted = '';

    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 2 || i == 4) {
        formatted += '/';
      }
      formatted += digitsOnly[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Date validation helper
class DateValidator {
  static bool isValidDate(String date) {
    if (date.length != 10) return false;

    final parts = date.split('/');
    if (parts.length != 3) return false;

    try {
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      if (day < 1 || day > 31) return false;
      if (month < 1 || month > 12) return false;
      if (year < 1900 || year > DateTime.now().year) return false;

      // Create DateTime to validate the actual date
      final dateTime = DateTime(year, month, day);
      return dateTime.day == day &&
          dateTime.month == month &&
          dateTime.year == year;
    } catch (e) {
      return false;
    }
  }

  static DateTime? parseDate(String date) {
    if (!isValidDate(date)) return null;

    final parts = date.split('/');
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}