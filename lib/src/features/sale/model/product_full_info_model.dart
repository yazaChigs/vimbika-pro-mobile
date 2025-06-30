import 'dart:convert';

import 'package:vimbika_pos_app/src/features/sale/model/inventory_item_model.dart';



ProductFullInfoModel productFullInfoModelFromJson(String str) => ProductFullInfoModel.fromJson(json.decode(str));
String productFullInfoModelToJson(ProductFullInfoModel data) => json.encode(data.toJson());

class ProductFullInfoModel {
  ProductFullInfoModel({
    required this.id,
    required this.item,
    required this.category,
    required this.count,
    required this.stock,
    required this.stockValue,
    required this.alertQuantity,
    this.barCodes

  });

  String? id;
  String? category;
  InventoryItemModel? item;
  List<String>? barCodes;
  int count = 0;
  double? stock;
  double? stockValue;
  double? alertQuantity;


  factory ProductFullInfoModel.fromJson(String str) => ProductFullInfoModel.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());
  factory ProductFullInfoModel.fromMap(Map<String, dynamic> json) => ProductFullInfoModel(
    id: json["id"],
    item: json["item"] != null ? InventoryItemModel.fromMap(json["item"]) : null,
    category: json["category"],
    count: json["count"] ?? 0,
    barCodes: json["barCodes"] != null ? List<String>.from(json["barCodes"].map((x) => x.toString())) : null,
    stock: json["stock"] ?? 0.0,
    stockValue: json["stockValue"] ?? 0.0,
    alertQuantity: json["alertQuantity"] ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "category": category,
    "item": item!.toMap(),
    "count": count,
    "stock": stock,
    "stockValue": stockValue,
    "alertQuantity": alertQuantity,
    "barcodes":barCodes
  };
}