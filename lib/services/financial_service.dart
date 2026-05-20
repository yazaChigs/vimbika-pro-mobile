import '../model/payment_received.dart';
import '../model/payment_paid.dart';

class FinancialService {
  /// Calculates the current Cash on Hand based on Cash-only transactions.
  /// Formula: (Cash Received) - (Cash Paid)
  static double calculateCashOnHand({
    required List<PaymentReceived> paymentsReceived,
    required List<PaymentPaid> paymentsPaid,
    double openingBalance = 0.0,
  }) {
    final totalCashReceived = paymentsReceived
        .where((p) => _isCash(p.paymentType?.isCash, p.paymentType?.name))
        .fold(0.0, (sum, p) => sum + p.amount);

    final totalCashPaid = paymentsPaid
        .where((p) => _isCash(p.paymentType?.isCash, p.paymentType?.name))
        .fold(0.0, (sum, p) => sum + p.amount);

    return openingBalance + totalCashReceived - totalCashPaid;
  }

  /// Helper to check if a payment type is "Cash"
  static bool _isCash(bool? isCashFlag, String? typeName) {
    if (isCashFlag == true) return true;
    if (typeName == null) return false;
    
    final normalized = typeName.trim().toLowerCase();
    return normalized == 'cash' || normalized == 'money';
  }
}