import 'dart:convert';


ProductImageModel productImageModelFromJson(String str) => ProductImageModel.fromJson(json.decode(str));
String productImageModelToJson(ProductImageModel data) => json.encode(data.toJson());

class ProductImageModel {
  ProductImageModel({
     this.big,
     this.small,
     this.medium,
  });

  String? big;
  String? small;
  String? medium;

  factory ProductImageModel.fromJson(String str) => ProductImageModel.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());
  factory ProductImageModel.fromMap(Map<String, dynamic> json) => ProductImageModel(
    big: json["big"],
    small: json["small"],
    medium: json["medium"],

  );

  Map<String, dynamic> toMap() => {
    "big": big,
    "small": small,
    "medium": medium
  };
}