import 'base_entity.dart';
import 'payment_type.dart';
import 'customer.dart';
import 'currency.dart';
import 'branch.dart';
import 'bank.dart'; // Import the new Bank model

class PaymentReceived extends BaseEntity {
  final PaymentType? paymentType;
  final Customer? payer;
  final Currency? currency;
  final Branch? branch;
  final double amount;
  final double amountPaid;
  final String? transactionId;
  final String? paymentDate;
  final String? dateTime;
  final String? reference;
  final String? notes;
  final String? paymentDescription;
  final Bank? bank; // Changed from bankName (String) to bank (Bank model)
  bool? isMobile;
  bool? isSynced; // Added isSynced field

  PaymentReceived({
    super.id,
    super.dateCreated,
    super.dateModified,
    super.createdByName,
    super.modifiedByName,
    super.version,
    this.paymentType,
    this.payer,
    this.currency,
    this.branch,
    required this.amount,
    this.transactionId,
    this.paymentDate,
    this.notes,
    this.paymentDescription,
    this.bank, // Initialize bank
    this.isMobile,
    this.isSynced, // Initialize isSynced
    this.dateTime,
    this.reference,
    this.amountPaid = 0.0

  });

  factory PaymentReceived.fromJson(Map<String, dynamic> json) {
    return PaymentReceived(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'] ,
      dateModified: json['dateModified'] ,
      createdByName: json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName']?.toString(),
      version: (json['version'] as num?)?.toInt(),
      paymentType: json['paymentType'] != null ? PaymentType.fromJson(json['paymentType']) : null,
      payer: json['payer'] != null ? Customer.fromJson(json['payer']) : null,
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionId: json['transactionId']?.toString(),
      paymentDate: json['paymentDate'] ,
      notes: json['notes']?.toString(),
      paymentDescription: json['paymentDescription']?.toString(),
      bank: json['bank'] != null ? Bank.fromJson(json['bank']) : null, // Deserialize bank
      isMobile: json['isMobile'] ?? false,
      isSynced: json['isSynced'] ?? true, // Default to true if not specified
      dateTime: json['dateTime'],
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      reference: json['reference']?.toString(),

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateCreated': dateCreated,
      'dateModified': dateModified,
      'createdByName': createdByName,
      'modifiedByName': modifiedByName,
      'version': version,
      'paymentType': paymentType?.toJson(),
      'payer': payer?.toJson(),
      'currency': currency?.toJson(),
      'branch': branch?.toJson(),
      'amount': amount,
      'transactionId': transactionId,
      'paymentDate': paymentDate,
      'notes': notes,
      'paymentDescription': paymentDescription,
      'bank': bank?.toJson(), // Include bank in JSON
      'isMobile': isMobile,
      'isSynced': isSynced, // Include in toJson
      'dateTime': dateTime,
      'reference': reference,
      'amountPaid': amountPaid,
    };
  }

  // Add copyWith method
  PaymentReceived copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    PaymentType? paymentType,
    Customer? payer,
    Currency? currency,
    Branch? branch,
    double? amount,
    String? transactionId,
    String? paymentDate,
    String? notes,
    String? paymentDescription,
    Bank? bank, // Add bank to copyWith
    bool? isMobile,
    bool? isSynced,
    String? dateTime,
    double? amountPaid,
    String? reference,
  }) {
    return PaymentReceived(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      paymentType: paymentType ?? this.paymentType,
      payer: payer ?? this.payer,
      currency: currency ?? this.currency,
      branch: branch ?? this.branch,
      amount: amount ?? this.amount,
      transactionId: transactionId ?? this.transactionId,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      paymentDescription: paymentDescription ?? this.paymentDescription,
      bank: bank ?? this.bank, // Copy bank
      isMobile: isMobile ?? this.isMobile,
      isSynced: isSynced ?? this.isSynced,
      dateTime: dateTime ?? this.dateTime,
      amountPaid: amountPaid ?? this.amountPaid,
      reference: reference ?? this.reference,
    );
  }
}
