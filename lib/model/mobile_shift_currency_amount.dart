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

  factory MobileShiftCurrencyAmount.fromRawJson(String str) => MobileShiftCurrencyAmount.fromJson(json.decode(str));

  String toJson() => json.encode(toMap());

  factory MobileShiftCurrencyAmount.fromJson(Map<String, dynamic> json) => MobileShiftCurrencyAmount(
    id: json["id"],
    dateCreated: json["dateCreated"],
    active: json["active"],
    createdByName: json["createdByName"],
    amount: json["amount"],
    currency: Currency.fromJson(json["currency"]),
    notes: json["notes"],
    amountType: json["amountType"],
    ref: json["ref"],
    timeCreated: json["timeCreated"],
    shiftReference: json["shiftReference"],
    posReference: json["posReference"],
    isCash: json["isCash"] ?? false,
    paymentType: json["paymentType"],
    bankName: json["bankName"],
  );

  Map<String, dynamic> toMap() => {
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
