import 'dart:convert';

import 'package:vimbika_pos_app/src/features/sale/model/inventory_item_model.dart';

TransferItemModel transferItemModelFromJson(String str) => TransferItemModel.fromJson(json.decode(str));
String transferItemModelToJson(TransferItemModel data) => json.encode(data.toJson());

class TransferItemModel {
  TransferItemModel({
    this.id,
    this.dateCreated,
    this.createdByName,
    required this.quantity,
    required this.allocated,
    required this.item,
  });

  String? id;
  String? dateCreated;
  String? createdByName;
  double? allocated;
  double? quantity;
  InventoryItemModel? item;

  factory TransferItemModel.fromJson(Map<String, dynamic> json) => TransferItemModel.fromMap(json);
  String toJson() => json.encode(toMap());

  factory TransferItemModel.fromMap(Map<String, dynamic> json) => TransferItemModel(
    id: json["id"],
    dateCreated: json["dateCreated"],
    createdByName: json["createdByName"],
    allocated: json["allocated"],
    quantity: json["quantity"],
    item: json["item"] != null ? InventoryItemModel.fromMap(json["item"]) : null,


  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "dateCreated": dateCreated,
    "createdByName": createdByName,
    "allocated": allocated,
    "quantity": quantity,
    "item": item != null?  item!.toMap() : null,
  };
}
