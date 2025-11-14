import 'dart:convert';
import 'dart:ffi';

import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

CompanyModel companyModelFromJson(String str) => CompanyModel.fromJson(json.decode(str));
String companyModelToJson(CompanyModel data) => json.encode(data.toJson());
class CompanyModel {
  CompanyModel({
    this.id,
    this.name,
    this.companyID,
    this.fiscalisationEnabled,
    this.logo,
    this.street,
    this.city,
    this.stateProvince,
    this.email,
    this.mobilePhone,
  });

  String? id;
  String? name;
  String? companyID;
  bool? fiscalisationEnabled;
  String? logo;
  String? street;
  String? city;
  String? stateProvince;
  String? email;
  String? mobilePhone;

  factory CompanyModel.fromJson(String str) => CompanyModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CompanyModel.fromMap(Map<String, dynamic> json) => CompanyModel(
    id: json["id"],
    name: json["name"],
    companyID: json["companyID"],
    fiscalisationEnabled: json["fiscalisationEnabled"],
    logo: json["logo"],
    street: json["street"],
    city: json["city"],
    stateProvince: json["stateProvince"],
    email: json["email"],
    mobilePhone: json["mobilePhone"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "companyID": companyID,
    "fiscalisationEnabled": fiscalisationEnabled,
    "logo": logo,
    "street": street,
    "city": city,
    "stateProvince": stateProvince,
    "email": email,
    "mobilePhone": mobilePhone,
  };
}