import 'package:intl/intl.dart';

class AppFormatters {
  static final _dateFormat = DateFormat('MMM d, yyyy');
  static final _dateTimeFormat = DateFormat('MMM d, yyyy · hh:mm a');
  static final _timeFormat = DateFormat('hh:mm a');
  static final _currencyFormat =
      NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  static final _compactFormat = NumberFormat.compact();

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatTime(DateTime date) => _timeFormat.format(date);
  static String formatCurrency(double amount) => _currencyFormat.format(amount);
  static String formatCompact(num value) => _compactFormat.format(value);

  static String formatQuantity(int qty) {
    if (qty >= 1000) return _compactFormat.format(qty);
    return qty.toString();
  }

  static String transactionTypeLabel(String type) {
    switch (type) {
      case 'OPENING':
        return 'Opening Stock';
      case 'PURCHASE':
        return 'Stock In';
      case 'SALE':
        return 'Sale';
      case 'RETURN_IN':
        return 'Return In';
      case 'RETURN_OUT':
        return 'Return Out';
      case 'ADJUSTMENT':
        return 'Adjustment';
      case 'DAMAGE':
        return 'Damage';
      case 'TRANSFER':
        return 'Transfer';
      default:
        return type;
    }
  }

  static bool isStockIn(String type) =>
      ['OPENING', 'PURCHASE', 'RETURN_IN', 'ADJUSTMENT'].contains(type);
}
