import 'dart:convert';

import 'package:vimbika_pos_app/src/features/shift/model/currency_amount.dart';

class ShiftCurrencyResponseModel {
  ShiftCurrencyResponseModel({
    this.message,
    this.items,
  });

  String? message;
  List<CurrencyAmount>? items;

  factory ShiftCurrencyResponseModel.fromJson(String str) => ShiftCurrencyResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ShiftCurrencyResponseModel.fromMap(Map<String, dynamic> json) => ShiftCurrencyResponseModel(
    message: json["message"],
    items: json["items"] != null ? List<CurrencyAmount>.from(json["items"].map((x) => CurrencyAmount.fromMap(x))) : [],
  );

  Map<String, dynamic> toMap() => {
    "message": message,
    "items": items != null ? List<dynamic>.from(items!.map((x) => x.toMap())) : [],
  };
}