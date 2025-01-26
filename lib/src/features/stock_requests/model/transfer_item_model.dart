import 'dart:convert';

import 'package:vimbika_pos_app/src/features/sale/model/inventory_item_model.dart';

TransferItemModel transferItemModelFromJson(String str) => TransferItemModel.fromJson(json.decode(str));
String transferItemModelToJson(TransferItemModel data) => json.encode(data.toJson());

class TransferItemModel {
  TransferItemModel({
    required this.quantity,
    required this.allocated,
    required this.inventoryItem,
  });

  double? allocated;
  double? quantity;
  InventoryItemModel? inventoryItem;

  factory TransferItemModel.fromJson(Map<String, dynamic> json) => TransferItemModel.fromMap(json);
  String toJson() => json.encode(toMap());

  factory TransferItemModel.fromMap(Map<String, dynamic> json) => TransferItemModel(
    allocated: json["allocated"],
    quantity: json["quantity"],
    inventoryItem: json["inventoryItem"] != null ? InventoryItemModel.fromMap(json["inventoryItem"]) : null,


  );

  Map<String, dynamic> toMap() => {
    "allocated": allocated,
    "quantity": quantity,
    "inventoryItem": inventoryItem!.toMap(),
  };
}
