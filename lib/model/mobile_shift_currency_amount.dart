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
    currency: Currency.fromJson(json["currency"] is String ? jsonDecode(json["currency"]) : json["currency"]),
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
}
