import 'dart:convert';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

class CustomerCurrencyAmount {
  CustomerCurrencyAmount({
    this.id,
    this.createdByName,
    this.dateCreated,
    this.active,
    required this.currency,
    this.balance = 0.0,
    required this.lastTranxDate,
  });
  String? id;
  String? createdByName;
  String? dateCreated;
  bool? active = true;
  CurrencyModel currency;
  Rx<CurrencyModel?> selectedCurrency = Rx<CurrencyModel?>(null);
  double? balance;
  String? lastTranxDate;

  factory CustomerCurrencyAmount.fromJson(String str) => CustomerCurrencyAmount.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CustomerCurrencyAmount.fromMap(Map<String, dynamic> json) => CustomerCurrencyAmount(
    id: json["id"],
    dateCreated: json["dateCreated"],
    active: json["active"],
    createdByName: json["createdByName"],
    balance: json["balance"],
    currency: CurrencyModel.fromMap(json["currency"]),
    lastTranxDate: json["lastTranxDate"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "active": active,
    "dateCreated": dateCreated,
    "createdByName": createdByName,
    "balance": balance,
    "currency": currency.toMap(),
    "lastTranxDate": lastTranxDate,
  };
}

