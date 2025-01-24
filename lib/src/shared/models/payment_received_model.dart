import 'dart:convert';

import 'package:vimbika_pos_app/src/shared/models/bank_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';

PaymentReceivedModel paymentReceivedModelFromJson(String str) => PaymentReceivedModel.fromJson(json.decode(str));
String paymentReceivedModelToJson(PaymentReceivedModel data) => json.encode(data.toJson());
class PaymentReceivedModel {
  PaymentReceivedModel({
    this.id,
    this.paymentType,
    this.reference,
    this.amount,
    this.isPaid,
    this.currency,
    this.paymentDescription,
    this.dateTime,
    this.bank
  });

  String? id;
  PaymentTypeModel? paymentType;
  String? reference;
  double? amount = 0.0;
  bool? isPaid = false;
  CurrencyModel? currency;
  BankModel? bank;
  String? paymentDescription = "SALE";
  String? dateTime;

  factory PaymentReceivedModel.fromJson(String str) => PaymentReceivedModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PaymentReceivedModel.fromMap(Map<String, dynamic> json) => PaymentReceivedModel(
    id: json["id"],
    reference: json["reference"],
    paymentDescription: json["paymentDescription"],
    amount: json["amount"] != null ? json["amount"].toDouble() : 0.0,
    isPaid: json["isPaid"],
    currency: json["currency"] != null ? CurrencyModel.fromMap(json["currency"]) : null,
    paymentType: json["paymentType"] != null ? PaymentTypeModel.fromMap(json["paymentType"]) : null,
    bank: json["bank"] != null ? BankModel.fromMap(json["bank"]) : null,
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "reference": reference,
    "paymentDescription": paymentDescription,
    "amount": amount,
    "isPaid": isPaid,
    "currency": currency?.toMap(),
    "paymentType": paymentType?.toMap(),
    "bank": bank?.toMap(),
  };
}