import 'dart:convert';

import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

class BankModel {
  BankModel({
    this.id,
    this.bankName,
    this.currency,
  });

  String? id;
  String? bankName;
  CurrencyModel? currency;

  factory BankModel.fromJson(String str) => BankModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BankModel.fromMap(Map<String, dynamic> json) => BankModel(
    id: json["id"],
    bankName: json["bankName"],
    currency: json["currency"] != null ? CurrencyModel.fromMap(json["currency"]) : null,
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "bankName": bankName,
    "currency": currency?.toMap(),
  };
}