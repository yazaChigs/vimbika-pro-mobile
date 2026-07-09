import 'base_entity.dart';
import 'payment_type.dart';
import 'currency.dart';
import 'supplier.dart';
import 'branch.dart';

class PaymentPaid extends BaseEntity {
  final PaymentType? paymentType;
  final Supplier? supplier;
  final Currency? currency;
  final Branch? branch;
  final double amount;
  final String? transactionId;
  final DateTime? paymentDate;
  final String? notes;
  final String? paymentDescription;

  PaymentPaid({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    this.paymentType,
    this.supplier,
    this.currency,
    this.branch,
    required this.amount,
    this.transactionId,
    this.paymentDate,
    this.notes,
    this.paymentDescription,
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
        );

  PaymentPaid copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    PaymentType? paymentType,
    Supplier? supplier,
    Currency? currency,
    Branch? branch,
    double? amount,
    String? transactionId,
    DateTime? paymentDate,
    String? notes,
    String? paymentDescription,
  }) {
    return PaymentPaid(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      paymentType: paymentType ?? this.paymentType,
      supplier: supplier ?? this.supplier,
      currency: currency ?? this.currency,
      branch: branch ?? this.branch,
      amount: amount ?? this.amount,
      transactionId: transactionId ?? this.transactionId,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      paymentDescription: paymentDescription ?? this.paymentDescription,
    );
  }

  factory PaymentPaid.fromJson(Map<String, dynamic> json) {
    return PaymentPaid(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'] ,
      dateModified: json['dateModified'] ,
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      paymentType: json['paymentType'] != null ? PaymentType.fromJson(json['paymentType']) : null,
      supplier: json['supplier'] != null ? Supplier.fromJson(json['supplier']) : null,
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      transactionId: json['transactionId'],
      paymentDate: json['paymentDate'] != null ? DateTime.parse(json['paymentDate']) : null,
      notes: json['notes'],
      paymentDescription: json['paymentDescription'],
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
      'supplier': supplier?.toJson(),
      'currency': currency?.toJson(),
      'branch': branch?.toJson(),
      'amount': amount,
      'transactionId': transactionId,
      'paymentDate': paymentDate?.toIso8601String(),
      'notes': notes,
      'paymentDescription': paymentDescription,
    };
  }
}
