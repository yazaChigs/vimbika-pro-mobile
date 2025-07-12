import 'dart:convert';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

class CurrencyAmount {
  CurrencyAmount({
    this.id,
    this.createdByName,
    this.dateCreated,
    this.active,
    required this.currency,
    this.amount = 0.0,
    this.notes,
    required this.amountType,
    required this.ref,
    required this.timeCreated,
    required this.shiftReference,
    this.posReference,
    this.isCash = false,
  });
  String? id;
  String? createdByName;
  String? dateCreated;
  bool? active = true;
  CurrencyModel currency;
  Rx<CurrencyModel?> selectedCurrency = Rx<CurrencyModel?>(null);
  double amount;
  String? notes;
  String amountType;
  String? ref;
  String? shiftReference;
  String? posReference;
  bool? isCash = false;
  String timeCreated;

  factory CurrencyAmount.fromJson(String str) => CurrencyAmount.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CurrencyAmount.fromMap(Map<String, dynamic> json) => CurrencyAmount(
    id: json["id"],
    dateCreated: json["dateCreated"],
    active: json["active"],
    createdByName: json["createdByName"],
    amount: json["amount"],
    currency: CurrencyModel.fromMap(json["currency"]),
    notes: json["notes"],
    amountType: json["amountType"],
    ref: json["ref"],
    timeCreated: json["timeCreated"],
    shiftReference: json["shiftReference"],
    posReference: json["posReference"],
    isCash: json["isCash"] ?? false,
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
    "isCash": isCash,
  };
}

