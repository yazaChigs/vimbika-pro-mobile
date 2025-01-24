import 'dart:convert';


class JwtRequestModel {
  JwtRequestModel({
    this.userName,
    this.password,
  });

  String? userName;
  String? password;

  factory JwtRequestModel.fromJson(String str) => JwtRequestModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory JwtRequestModel.fromMap(Map<String, dynamic> json) => JwtRequestModel(
    userName: json["userName"],
    password: json["password"]
  );

  Map<String, dynamic> toMap() => {
    "userName": userName,
    "password": password
  };
}