import 'dart:convert';
import 'package:vimbika_pos_app/src/features/authentication/model/user_role_model.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  UserModel({
    this.id,
    this.dateCreated,
    this.active = true,
    required this.firstName,
    required this.lastName,
    required this.userName,
    this.mobilePhone,
    this.userRoles,
    this.companyId,
    this.companyName,
    this.pin,
    this.company,
    this.password,
  });

  String? id;
  String? dateCreated;
  bool? active;
  String firstName;
  String lastName;
  String? userName;
  String? mobilePhone;
  List<UserRoleModel>? userRoles;
  String? password;
  String? companyName;
  String? companyId;
  String? pin;
  BaseNameModel? company;


  factory UserModel.fromJson(String str) => UserModel.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());
  factory UserModel.fromMap(Map<String, dynamic> json) => UserModel(
    id: json["id"],
    dateCreated: json["dateCreated"],
    active: json["active"],
    firstName: json["firstName"] ?? "",
    lastName: json["lastName"]?? "",
    userName: json["userName"] ?? "",
    mobilePhone: json["mobilePhone"],
    userRoles: List<UserRoleModel>.from(json["userRoles"].map((x) => UserRoleModel.fromMap(x))),
    password: json["password"],
    company: BaseNameModel.fromMap(json["company"]),
    companyName: json["companyName"],
    companyId: json["companyId"],
    pin: json["pin"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "dateCreated": dateCreated,
    "active": active,
    "firstName": firstName,
    "lastName": lastName,
    "userName": userName,
    "mobilePhone": mobilePhone,
    "userRoles": List<dynamic>.from(userRoles!.map((x) => x.toMap())),
    "password": password,
    "company": company!.toMap(),
    "companyName": companyName,
    "companyId": companyId,
    "pin": pin,
  };


}