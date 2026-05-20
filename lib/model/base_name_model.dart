import 'dart:convert';

class BaseNameModel {
  BaseNameModel({
    this.id,
    this.name,
  });

  String? id;
  String? name;

  factory BaseNameModel.fromRawJson(String str) => BaseNameModel.fromJson(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BaseNameModel.fromJson(Map<String, dynamic> json) => BaseNameModel(
    id: json["id"],
    name: json["name"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
  };
}