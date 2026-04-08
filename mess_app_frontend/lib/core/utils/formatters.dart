class AppFormatters {
  static String currency(
    num amount, {
    String symbol = 'Rs.',
    int decimalPlaces = 0,
  }) {
    return '$symbol ${amount.toStringAsFixed(decimalPlaces)}';
  }

  static String nullableText(String? value, {String fallback = 'N/A'}) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }
    return value.trim();
  }

  static String statusText(String value) {
    return value
        .toLowerCase()
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  static String shortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day-$month-$year';
  }

  static String monthYear(int month, int year) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    if (month < 1 || month > 12) return '$month/$year';
    return '${months[month]} $year';
  }

  static String mealUnitSummary({
    required int breakfastUnits,
    required int lunchUnits,
    required int dinnerUnits,
    required int guestUnits,
  }) {
    final total = breakfastUnits + lunchUnits + dinnerUnits + guestUnits;
    return total.toString();
  }
}
