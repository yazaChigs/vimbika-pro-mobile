
import 'dart:convert';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';


class JwtResponseModel {
  JwtResponseModel({
    this.token,
    this.user,
  });

  String? token;
  UserModel? user;

  factory JwtResponseModel.fromJson(String str) => JwtResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory JwtResponseModel.fromMap(Map<String, dynamic> json) => JwtResponseModel(
    token: json["token"],
    user: UserModel.fromMap(json["user"]),
  );

  Map<String, dynamic> toMap() => {
    "token": token,
    "user": user!.toMap(),
  };
}