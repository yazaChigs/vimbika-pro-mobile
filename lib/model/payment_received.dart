import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vimbika_pro/model/payment_type.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/bank.dart';

part 'payment_received.g.dart';

@collection
class PaymentReceived {
  Id isarId = Isar.autoIncrement;
  String? id;
  final paymentType = IsarLink<PaymentType>();
  final payer = IsarLink<Customer>();
  final currency = IsarLink<Currency>();
  final branch = IsarLink<Branch>();
  double amount;
  double? amountPaid;
  String? paymentDescription;
  String? paymentDate;
  String? dateTime;
  String? notes;
  final bank = IsarLink<Bank>();
  bool isMobile;
  double? amountTendered;
  String? reference;
  bool isSynced;

  PaymentReceived({
    this.id,
    PaymentType? paymentType,
    Customer? payer,
    Currency? currency,
    Branch? branch,
    Bank? bank,
    this.amount = 0.0,
    this.amountPaid,
    this.paymentDescription,
    this.paymentDate,
    this.dateTime,
    this.notes,
    this.isMobile = false,
    this.amountTendered,
    this.reference,
    this.isSynced = true,
  }) {
    if (paymentType != null) {
      this.paymentType.value = paymentType;
    }
    if (payer != null) {
      this.payer.value = payer;
    }
    if (currency != null) {
      this.currency.value = currency;
    }
    if (branch != null) {
      this.branch.value = branch;
    }
    if (bank != null) {
      this.bank.value = bank;
    }
  }

  factory PaymentReceived.fromJson(Map<String, dynamic> json) {
    final payment = PaymentReceived(
      id: json['id'],
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      paymentDescription: json['paymentDescription'],
      paymentDate: json['paymentDate'],
      dateTime: json['dateTime'],
      notes: json['notes'],
      isMobile: json['isMobile'] ?? false,
      amountTendered: (json['amountTendered'] as num?)?.toDouble(),
      reference: json['reference'],
      isSynced: json['isSynced'] ?? true,
    );
    if (json['paymentType'] != null) {
      payment.paymentType.value = PaymentType.fromJson(json['paymentType']);
    }
    if (json['payer'] != null) {
      payment.payer.value = Customer.fromJson(json['payer']);
    }
    if (json['currency'] != null) {
      payment.currency.value = Currency.fromJson(json['currency']);
    }
    if (json['branch'] != null) {
      payment.branch.value = Branch.fromJson(json['branch']);
    }
    if (json['bank'] != null) {
      payment.bank.value = Bank.fromJson(json['bank']);
    }
    return payment;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'amountPaid': amountPaid,
      'paymentDescription': paymentDescription,
      'paymentDate': paymentDate,
      'dateTime': dateTime,
      'notes': notes,
      'isMobile': isMobile,
      'amountTendered': amountTendered,
      'reference': reference,
      'isSynced': isSynced,
      'paymentType': paymentType.value?.toJson(),
      'payer': payer.value?.toJson(),
      'currency': currency.value?.toJson(),
      'branch': branch.value?.toJson(),
      'bank': bank.value?.toJson(),
    };
  }

  PaymentReceived copyWith({
    String? id,
    double? amount,
    double? amountPaid,
    String? paymentDescription,
    String? paymentDate,
    String? dateTime,
    String? notes,
    bool? isMobile,
    double? amountTendered,
    String? reference,
    bool? isSynced,
  }) {
    return PaymentReceived(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentDescription: paymentDescription ?? this.paymentDescription,
      paymentDate: paymentDate ?? this.paymentDate,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      isMobile: isMobile ?? this.isMobile,
      amountTendered: amountTendered ?? this.amountTendered,
      reference: reference ?? this.reference,
      isSynced: isSynced ?? this.isSynced,
    )
      ..paymentType.value = paymentType.value
      ..payer.value = payer.value
      ..currency.value = currency.value
      ..branch.value = branch.value
      ..bank.value = bank.value;
  }
}
