import 'dart:convert';

import 'package:vimbika_pos_app/src/features/sale/model/product_image_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/inventory_item_model.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

RequisitionItemModel requisitionItemModelFromJson(String str) => RequisitionItemModel.fromJson(json.decode(str));
String requisitionItemModelToJson(RequisitionItemModel data) => json.encode(data.toJson());

class RequisitionItemModel {
  RequisitionItemModel({
    this.name,
    required this.whQtyRequest,
    required this.allocated,
    required this.quantity,
    this.status,
    required this.inventoryItem,
    this.branchQty,
    this.warehouseQty,

  });

  String? name;
  double? whQtyRequest;
  double? allocated;
  double? quantity;
  String? status;
  InventoryItemModel? inventoryItem;
  double? branchQty;
  double? warehouseQty;



  factory RequisitionItemModel.fromJson(Map<String, dynamic> json) => RequisitionItemModel.fromMap(json);
  String toJson() => json.encode(toMap());

  factory RequisitionItemModel.fromMap(Map<String, dynamic> json) => RequisitionItemModel(
    name: json["name"],
    whQtyRequest: json["whQtyRequest"],
    allocated: json["allocated"],
    quantity: json["quantity"],
    status: json["status"],

    branchQty: json["branchQty"],
    warehouseQty: json["warehouseQty"],
    inventoryItem: json["inventoryItem"] != null ? InventoryItemModel.fromMap(json["inventoryItem"]) : null,


  );

  Map<String, dynamic> toMap() => {
    "name": name,
    "whQtyRequest": whQtyRequest,
    "allocated": allocated,
    "quantity": quantity,
    "status": status,
    "branchQty": branchQty,
    "warehouseQty": warehouseQty,
    "inventoryItem": inventoryItem!.toMap(),
  };
}
