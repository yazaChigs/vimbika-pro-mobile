import 'package:vimbika_pro/model/payment_type.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/bank.dart';

class PaymentReceived {
  String? id;
  PaymentType? paymentType;
  Customer? payer;
  Currency? currency;
  Branch? branch;
  double amount;
  double? amountPaid;
  String? paymentDescription;
  String? paymentDate;
  String? dateTime;
  String? notes;
  Bank? bank;
  bool isMobile;
  double? amountTendered;
  String? reference;
  bool isSynced;

  PaymentReceived({
    this.id,
    this.paymentType,
    this.payer,
    this.currency,
    this.branch,
    required this.amount,
    this.amountPaid,
    this.paymentDescription,
    this.paymentDate,
    this.dateTime,
    this.notes,
    this.bank,
    this.isMobile = false,
    this.amountTendered,
    this.reference,
    this.isSynced = true,
  });

  factory PaymentReceived.fromJson(Map<String, dynamic> json) {
    return PaymentReceived(
      id: json['id'],
      paymentType: json['paymentType'] != null ? PaymentType.fromJson(json['paymentType']) : null,
      payer: json['payer'] != null ? Customer.fromJson(json['payer']) : null,
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      amount: (json['amount'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      paymentDescription: json['paymentDescription'],
      paymentDate: json['paymentDate'],
      dateTime: json['dateTime'],
      notes: json['notes'],
      bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null,
      isMobile: json['isMobile'] ?? false,
      amountTendered: (json['amountTendered'] as num?)?.toDouble(),
      reference: json['reference'],
      isSynced: json['isSynced'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentType': paymentType?.toJson(),
      'payer': payer?.toJson(),
      'currency': currency?.toJson(),
      'branch': branch?.toJson(),
      'amount': amount,
      'amountPaid': amountPaid,
      'paymentDescription': paymentDescription,
      'paymentDate': paymentDate,
      'dateTime': dateTime,
      'notes': notes,
      'bank': bank?.toJson(),
      'isMobile': isMobile,
      'amountTendered': amountTendered,
      'reference': reference,
      'isSynced': isSynced,
    };
  }

  PaymentReceived copyWith({
    String? id,
    PaymentType? paymentType,
    Customer? payer,
    Currency? currency,
    Branch? branch,
    double? amount,
    double? amountPaid,
    String? paymentDescription,
    String? paymentDate,
    String? dateTime,
    String? notes,
    Bank? bank,
    bool? isMobile,
    double? amountTendered,
    String? reference,
    bool? isSynced,
  }) {
    return PaymentReceived(
      id: id ?? this.id,
      paymentType: paymentType ?? this.paymentType,
      payer: payer ?? this.payer,
      currency: currency ?? this.currency,
      branch: branch ?? this.branch,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDescription: paymentDescription ?? this.paymentDescription,
      paymentDate: paymentDate ?? this.paymentDate,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      bank: bank ?? this.bank,
      isMobile: isMobile ?? this.isMobile,
      amountTendered: amountTendered ?? this.amountTendered,
      reference: reference ?? this.reference,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
