import 'dart:convert';

class BranchModel {
  BranchModel({
    this.id,
    this.name,
    this.isWarehouse,
    this.alwaysFiscalize,
  });

  String? id;
  String? name;
  bool? isWarehouse;
  bool? alwaysFiscalize;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BranchModel) return false;

    // Prefer id when available
    if (id != null && other.id != null) {
      return id == other.id;
    }
    // Fallback to name
    return name != null && other.name != null && name == other.name;
  }

  @override
  int get hashCode => id?.hashCode ?? name.hashCode;

  factory BranchModel.fromJson(String str) => BranchModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BranchModel.fromMap(Map<String, dynamic> json) => BranchModel(
    id: json["id"],
    name: json["name"],
    isWarehouse: json["isWarehouse"],
    alwaysFiscalize: json["alwaysFiscalize"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "isWarehouse": isWarehouse,
    "alwaysFiscalize": alwaysFiscalize,
  };
}