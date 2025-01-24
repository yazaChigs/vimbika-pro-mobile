import 'dart:convert';

import 'package:vimbika_pos_app/src/shared/models/bank_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

PaymentTypeModel paymentTypeModelFromJson(String str) => PaymentTypeModel.fromJson(json.decode(str));
String paymentTypeModelToJson(PaymentTypeModel data) => json.encode(data.toJson());
class PaymentTypeModel {
  PaymentTypeModel({
    this.id,
    this.name,
    this.paymentNote,
    this.amount,
    this.isCredit,
    this.currency,
    this.banks
  });

  String? id;
  String? name;
  String? paymentNote;
  double? amount = 0.0;
  bool? isCredit = false;
  CurrencyModel? currency;
  List<BankModel>? banks;

  factory PaymentTypeModel.fromJson(String str) => PaymentTypeModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PaymentTypeModel.fromMap(Map<String, dynamic> json) => PaymentTypeModel(
    id: json["id"],
    name: json["name"],
    paymentNote: json["paymentNote"],
    amount: json["amount"] != null ? json["amount"].toDouble() : 0.0,
    isCredit: json["isCredit"],
    currency: json["currency"] != null ? CurrencyModel.fromMap(json["currency"]) : null,
    banks: json["banks"] != null ? List<BankModel>.from(json["banks"].map((x) => BankModel.fromMap(x))) : [],

  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "paymentNote": paymentNote,
    "amount": amount,
    "isCredit": isCredit,
    "currency": currency?.toMap(),
    "banks": banks != null ? List<dynamic>.from(banks!.map((x) => x.toMap())) : [],
  };
}