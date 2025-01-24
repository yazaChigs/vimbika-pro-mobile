import 'dart:convert';

import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';

class SaleItemResponseModel {
  SaleItemResponseModel({
    this.message,
    this.item,
  });

  String? message;
  SaleModel? item;

  factory SaleItemResponseModel.fromJson(String str) => SaleItemResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SaleItemResponseModel.fromMap(Map<String, dynamic> json) => SaleItemResponseModel(
    message: json["message"],
    item: json["item"] != null ? SaleModel.fromMap(json["item"]) : null
  );

  Map<String, dynamic> toMap() => {
    "message": message,
    "item": item!.toMap(),
  };
}