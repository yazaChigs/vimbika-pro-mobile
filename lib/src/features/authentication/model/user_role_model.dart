import 'dart:convert';

class UserRoleModel {
  UserRoleModel({
    required this.name,
  });

  String name;

  factory UserRoleModel.fromJson(String str) => UserRoleModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory UserRoleModel.fromMap(Map<String, dynamic> json) => UserRoleModel(
    name: json["name"],
  );

  Map<String, dynamic> toMap() => {
    "name": name,
  };
}