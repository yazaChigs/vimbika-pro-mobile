import 'dart:convert';

class BaseNameModel {
  BaseNameModel({
    this.id,
    this.name,
  });

  String? id;
  String? name;

  factory BaseNameModel.fromJson(String str) => BaseNameModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BaseNameModel.fromMap(Map<String, dynamic> json) => BaseNameModel(
    id: json["id"],
    name: json["name"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
  };
}