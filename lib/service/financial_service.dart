import '../model/payment_received.dart';
import '../model/payment_paid.dart';

class FinancialService {
  /// Calculates Cash on Hand by only considering transactions 
  /// where the PaymentType is "Cash".
  static double calculateCashOnHand({
    required List<PaymentReceived> paymentsReceived,
    required List<PaymentPaid> paymentsPaid,
    double openingBalance = 0.0,
  }) {
    // 1. Filter and sum received cash
    double totalCashReceived = paymentsReceived
        .where((p) => _isCashType(p.paymentType.value?.name))
        .fold(0.0, (sum, item) => sum + item.amount);

    // 2. Filter and sum paid cash
    double totalCashPaid = paymentsPaid
        .where((p) => _isCashType(p.paymentType?.name))
        .fold(0.0, (sum, item) => sum + item.amount);

    // 3. Formula: Opening + (Received - Paid)
    return openingBalance + totalCashReceived - totalCashPaid;
  }

  /// Helper to determine if a payment type is "Cash"
  static bool _isCashType(String? typeName) {
    if (typeName == null) return false;
    return typeName.trim().toLowerCase() == 'cash';
  }
  
  /// Returns only the Cash-specific transactions for ledger views
  static List<T> filterCashTransactions<T>(
      List<T> transactions, String? Function(T) getTypeName) {
    return transactions.where((t) => _isCashType(getTypeName(t))).toList();
  }
}