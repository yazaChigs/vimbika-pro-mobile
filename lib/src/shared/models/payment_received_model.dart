import 'dart:convert';

import 'package:vimbika_pos_app/src/shared/models/bank_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/customer_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';

import 'branch_model.dart';

PaymentReceivedModel paymentReceivedModelFromJson(String str) => PaymentReceivedModel.fromJson(json.decode(str));
String paymentReceivedModelToJson(PaymentReceivedModel data) => json.encode(data.toJson());
class PaymentReceivedModel {
  PaymentReceivedModel({
    this.id,
    this.paymentType,
    this.reference,
    this.amount,
    this.amountPaid,
    this.isPaid,
    this.currency,
    this.paymentDescription,
    this.dateTime,
    this.bank,
    this.payer,
    this.accountBalance,
    this.branch,
    this.balance,
    this.isMobile = true,
  });

  String? id;
  PaymentTypeModel? paymentType;
  String? reference;
  double? amount = 0.0;
  double? accountBalance = 0.0;
  double? amountPaid = 0.0;
  double? balance = 0.0;
  bool? isPaid = false;
  CurrencyModel? currency;
  BranchModel? branch;
  BankModel? bank;
  String? paymentDescription = "SALE";
  String? dateTime;
  bool? isMobile = true;
  CustomerModel? payer;

  factory PaymentReceivedModel.fromJson(String str) => PaymentReceivedModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory PaymentReceivedModel.fromMap(Map<String, dynamic> json) => PaymentReceivedModel(
    id: json["id"],
    reference: json["reference"],
    paymentDescription: json["paymentDescription"],
    amount: json["amount"] != null ? json["amount"].toDouble() : 0.0,
    amountPaid: json["amountPaid"] != null ? json["amountPaid"].toDouble() : 0.0,
    isPaid: json["isPaid"],
    balance: json["balance"] != null ? json["balance"].toDouble() : 0.0,
    currency: json["currency"] != null ? CurrencyModel.fromMap(json["currency"]) : null,
    payer: json["payer"] != null ? CustomerModel.fromMap(json["payer"]) : null,
    branch: json["branch"] != null ? BranchModel.fromMap(json["branch"]) : null,
    paymentType: json["paymentType"] != null ? PaymentTypeModel.fromMap(json["paymentType"]) : null,
    bank: json["bank"] != null ? BankModel.fromMap(json["bank"]) : null,
    dateTime: json["dateTime"],
    accountBalance: json["accountBalance"] != null ? json["accountBalance"].toDouble() : 0.0,
    isMobile: json["isMobile"] ?? true,
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "reference": reference,
    "paymentDescription": paymentDescription,
    "amount": amount,
    "amountPaid": amountPaid,
    "isPaid": isPaid,
    "currency": currency?.toMap(),
    "paymentType": paymentType?.toMap(),
    "payer": payer?.toMap(),
    "bank": bank?.toMap(),
    "accountBalance": accountBalance,
    "dateTime": dateTime,
    "balance": balance,
    "isMobile": isMobile,
    "branch": branch?.toMap(),
  };
}