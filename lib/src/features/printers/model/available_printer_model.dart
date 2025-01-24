import 'dart:convert';

class AvailablePrinterModel {
  AvailablePrinterModel({
    this.id,
    required this.name,
    required this.address,
    required this.productId,
    required this.vendorId,
    required this.isDefault,
    required this.type,

  });

  String? id;
  String? name;
  String? address;
  String? productId;
  String? vendorId;
  bool? isDefault = false;
  String? type;

  factory AvailablePrinterModel.fromJson(String str) => AvailablePrinterModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory AvailablePrinterModel.fromMap(Map<String, dynamic> json) => AvailablePrinterModel(
    id: json["id"],
    name: json["name"],
    address: json["address"],
    productId: json["productId"],
    vendorId: json["vendorId"],
    isDefault: json["isDefault"],
    type: json["type"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "isDefault": isDefault,
    "address": address,
    "productId": productId,
    "vendorId": vendorId,
    "type": type,
  };
}