
import 'dart:convert';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/subscription/model/subscription_model.dart';


class JwtResponseModel {
  JwtResponseModel({
    this.token,
    this.user,
    this.subscriptions,
  });

  String? token;
  UserModel? user;
  List<SubscriptionModel>? subscriptions;

  factory JwtResponseModel.fromJson(String str) => JwtResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory JwtResponseModel.fromMap(Map<String, dynamic> json) => JwtResponseModel(
    token: json["token"],
    user: UserModel.fromMap(json["user"]),
    subscriptions: List<SubscriptionModel>.from(json["subscriptions"].map((x) => SubscriptionModel.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "token": token,
    "user": user!.toMap(),
    "subscriptions": List<dynamic>.from(subscriptions!.map((x) => x.toMap())),
  };
}