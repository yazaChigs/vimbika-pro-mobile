import 'dart:convert';

import 'package:vimbika_pos_app/src/features/sale/model/product_image_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/inventory_item_model.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

SaleItemModel saleItemModelFromJson(String str) => SaleItemModel.fromJson(json.decode(str));
String saleItemModelToJson(SaleItemModel data) => json.encode(data.toJson());

class SaleItemModel {
  SaleItemModel({
    this.id,
    required this.sellingPrice,
    required this.baseCurrencySellingPrice,
    required this.quantity,
    required this.total,

    required this.baseCurrencyTotal,
    required this.taxAmount,

    required this.baseTaxAmount,
    required this.inventoryItem,
    required this.branch,
    this.usedCodesString,
    this.isMobile = true,
  });

  String? id;
  double? sellingPrice;
  double? baseCurrencySellingPrice;
  double? quantity;
  double? total;
  Set<String>? usedCodesString;
  double? baseCurrencyTotal;
  double? taxAmount;
  double? baseTaxAmount;
  InventoryItemModel? inventoryItem;
  BranchModel? branch;
  bool? isMobile = true;


  factory SaleItemModel.fromJson(Map<String, dynamic> json) => SaleItemModel.fromMap(json);
  String toJson() => json.encode(toMap());

  factory SaleItemModel.fromMap(Map<String, dynamic> json) => SaleItemModel(
    id: json["id"],
    sellingPrice: json["sellingPrice"],
    baseCurrencySellingPrice: json["baseCurrencySellingPrice"],
    quantity: json["quantity"],
    total: json["total"],

    baseCurrencyTotal: json["baseCurrencyTotal"],
    taxAmount: json["taxAmount"],
    usedCodesString: json["usedCodes"] != null
        ? Set<String>.from(json["usedCodes"].map((x) => x.toString()))
        : {},
    baseTaxAmount: json["baseTaxAmount"],
    inventoryItem: json["inventoryItem"] != null ? InventoryItemModel.fromMap(json["inventoryItem"]) : null,
    branch: json["branch"] != null ? BranchModel.fromMap(json["branch"]) : null,
  isMobile: json["isMobile"] ?? true,


  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "sellingPrice": sellingPrice,
    "baseCurrencySellingPrice": baseCurrencySellingPrice,
    "quantity": quantity,
    "total": total,
    "baseCurrencyTotal": baseCurrencyTotal,
    "taxAmount": taxAmount,
    "baseTaxAmount": baseTaxAmount,
    "inventoryItem": inventoryItem!.toMap(),
    "branch": branch != null?  branch!.toMap() : null,
    "usedCodes": usedCodesString != null ? List<dynamic>.from(usedCodesString!.map((x) => x)) : [],
  "isMobile": isMobile,
  };
}
