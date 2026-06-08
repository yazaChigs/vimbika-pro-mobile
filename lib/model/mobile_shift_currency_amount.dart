import 'dart:convert';

import 'package:vimbika_pro/model/currency.dart';

class MobileShiftCurrencyAmount {
  MobileShiftCurrencyAmount({
    this.id,
    this.createdByName,
    this.dateCreated,
    this.active = true,
    required this.currency,
    this.amount = 0.0,
    this.notes,
    required this.amountType,
    this.ref,
    this.timeCreated,
    this.shiftReference,
    this.posReference,
    this.isCash = false,
    this.paymentType,
    this.bankName,
  });
  String? id;
  String? createdByName;
  String? dateCreated;
  bool? active = true;
  Currency currency;
  double amount;
  String? notes;
  String amountType;
  String? paymentType;
  String? ref;
  String? shiftReference;
  String? posReference;
  bool? isCash = false;
  String? timeCreated;
  String? bankName;

  factory MobileShiftCurrencyAmount.fromJson(Map<String, dynamic> json) => MobileShiftCurrencyAmount(
    id: json["id"]?.toString(),
    dateCreated: json["dateCreated"]?.toString(),
    active: json["active"] == true || json["active"] == 'true',
    createdByName: json["createdByName"]?.toString(),
    amount: (json["amount"] as num?)?.toDouble() ?? 0.0,
    currency: json["currency"] != null
        ? (json["currency"] is String
            ? Currency.fromRawJson(json["currency"])
            : Currency.fromJson(json["currency"] as Map<String, dynamic>))
        : Currency(), // Fallback to empty currency if null
    notes: json["notes"]?.toString(),
    amountType: json["amountType"]?.toString() ?? 'UNKNOWN',
    ref: json["ref"]?.toString(),
    timeCreated: json["timeCreated"]?.toString(),
    shiftReference: json["shiftReference"]?.toString(),
    posReference: json["posReference"]?.toString(),
    isCash: json["isCash"] == true || json["isCash"] == 'true',
    paymentType: json["paymentType"]?.toString(),
    bankName: json["bankName"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "active": active,
    "dateCreated": dateCreated,
    "createdByName": createdByName,
    "amount": amount,
    "currency": currency.toMap(),
    "notes": notes,
    "amountType": amountType,
    "ref": ref,
    "timeCreated": timeCreated,
    "shiftReference": shiftReference,
    "posReference": posReference,
    "paymentType": paymentType,
    "isCash": isCash,
    "bankName": bankName,
  };

  MobileShiftCurrencyAmount copyWith({
    String? id,
    String? createdByName,
    String? dateCreated,
    bool? active,
    Currency? currency,
    double? amount,
    String? notes,
    String? amountType,
    String? ref,
    String? timeCreated,
    String? shiftReference,
    String? posReference,
    bool? isCash,
    String? paymentType,
    String? bankName,
  }) {
    return MobileShiftCurrencyAmount(
      id: id ?? this.id,
      createdByName: createdByName ?? this.createdByName,
      dateCreated: dateCreated ?? this.dateCreated,
      active: active ?? this.active,
      currency: currency ?? this.currency,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      amountType: amountType ?? this.amountType,
      ref: ref ?? this.ref,
      timeCreated: timeCreated ?? this.timeCreated,
      shiftReference: shiftReference ?? this.shiftReference,
      posReference: posReference ?? this.posReference,
      isCash: isCash ?? this.isCash,
      paymentType: paymentType ?? this.paymentType,
      bankName: bankName ?? this.bankName,
    );
  }
}
