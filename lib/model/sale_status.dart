class SaleStatus {
  static const String ON_HOLD = 'ON_HOLD';
  static const String QUOTE = 'QUOTE';
  static const String COMPLETE = 'COMPLETE';
  static const String REVERSED = 'REVERSED';
  static const String PENDING = 'PENDING';
  static const String CREDIT_NOTE = 'CREDIT_NOTE';

  static const List<String> _values = [
    ON_HOLD,
    QUOTE,
    COMPLETE,
    REVERSED,
    PENDING,
    CREDIT_NOTE,
  ];

  static String fromJson(String? value) {
    if (value != null && _values.contains(value)) {
      return value;
    }
    return PENDING; // Default value
  }

  static List<String> toArray() {
    return _values;
  }
}
