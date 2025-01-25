import 'dart:convert';

class BranchModel {
  BranchModel({
    this.id,
    this.name,
    this.isWarehouse
  });

  String? id;
  String? name;
  bool? isWarehouse;

  factory BranchModel.fromJson(String str) => BranchModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BranchModel.fromMap(Map<String, dynamic> json) => BranchModel(
    id: json["id"],
    name: json["name"],
    isWarehouse: json["isWarehouse"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "isWarehouse": isWarehouse,
  };
}