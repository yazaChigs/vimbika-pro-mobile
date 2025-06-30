import 'dart:convert';

import 'package:vimbika_pos_app/src/features/sale/model/product_image_model.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';


InventoryItemModel inventoryItemModelFromJson(String str) => InventoryItemModel.fromJson(json.decode(str));
String inventoryItemModelToJson(InventoryItemModel data) => json.encode(data.toJson());

class InventoryItemModel {
  InventoryItemModel({
    required this.id,
    required this.name,
    required this.sellingPrice,
    this.brand,
    this.currency,
    this.category,
    this.productImages,
    this.images,
    this.image,
    this.fullName,
    this.quantity,
    this.total,
    this.itemType,
    this.itemCode,
    required this.taxAmount,

  });

  String? id;
  String? name;
  double sellingPrice = 0.0;
  BaseNameModel? brand;
  CurrencyModel? currency;
  BaseNameModel? category;
  List<ProductImageModel>? productImages;
  List<String>? images;
  String? image;
  String? fullName;
  double? quantity = 0;
  double? total = 0.0;
  double taxAmount = 0.0;
  String? itemType;
  String? itemCode;

  factory InventoryItemModel.fromJson(String str) => InventoryItemModel.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());
  // factory ProductItemModel.fromMap(Map<String, dynamic> json) => ProductItemModel(
  //
  //   id: json["id"],
  //   name: json["name"],
  //   sellingPrice: json["sellingPrice"],
  //   brand: json["brand"] != null ? BaseNameModel.fromMap(json["brand"]) : null,
  //   currency: json["currency"] != null ? BaseNameModel.fromMap(json["currency"]) : null,
  //   category: json["category"] != null ? BaseNameModel.fromMap(json["category"]) : null,
  //   productImages: json["productImages"] != null ? List<ProductImageModel>.from(json["productImages"].map((x) => ProductImageModel.fromMap(x))) : null,
  //   images: json["images"] != null ? List<String>.from(json["images"].map((x) => x.toString())) : null,
  //   fullName: json["fullName"],
  //   quantity: json["quantity"],
  //   total: json["total"],
  //  // inventoryItem: json["inventoryItem"] != null ? ProductItemModel.fromMap(json["inventoryItem"]) : null,
  // );
  factory InventoryItemModel.fromMap(Map<String, dynamic> json) {
    var productImagesData = json["productImages"];
    List<ProductImageModel> productImages = [];

    if (productImagesData is List) {
      for (var item in productImagesData) {
        if (item is Map<String, dynamic>) {
          productImages.add(ProductImageModel.fromMap(item));
        } else {
         // print("Unexpected item in productImages: ");
        }
      }
    } else {
      //print("productImages is not a List: ");
    }

    return InventoryItemModel(
      id: json["id"],
      name: json["name"],
      itemCode: json["itemCode"],
      sellingPrice: json["sellingPrice"] != null ? json["sellingPrice"].toDouble() : 0.0,
      brand: json["brand"] != null ? BaseNameModel.fromMap(json["brand"]) : null,
      currency: json["currency"] != null ? CurrencyModel.fromMap(json["currency"]) : null,
      category: json["category"] != null ? BaseNameModel.fromMap(json["category"]) : null,
      productImages: productImages.isNotEmpty ? productImages : null,  // Ensure this is nullable if required
      images: json["images"] != null ? List<String>.from(json["images"].map((x) => x.toString())) : null,
      image: json["image"],
      fullName: json["fullName"],
      quantity: json["quantity"] != null ? json["quantity"].toDouble() : 0.0,
      total: json["total"] != null ? json["total"].toDouble() : 0.0,
      taxAmount: json["taxAmount"] != null ? json["taxAmount"].toDouble() : 0.0,
      itemType: json["itemType"],
    );
  }



  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "sellingPrice": sellingPrice,
    "brand": brand?.toMap(),
    "currency": currency?.toMap(),
    "category": category?.toMap(),
    "productImages": productImages!= null ?  List<dynamic>.from(productImages!.map((x) => x)) : null,
    "images": images != null ? List<dynamic>.from(images!.map((x) => x)) : null,
    "image": image,
    "fullName": fullName,
    "quantity": quantity,
    "total": total,
    "taxAmount": taxAmount,
    "itemType": itemType,
    "itemCode": itemCode,
  };
}