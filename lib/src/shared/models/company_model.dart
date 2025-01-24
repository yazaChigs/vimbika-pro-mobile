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
    this.logo

  });

  String? id;
  String? name;
  String? companyID;
  bool? fiscalisationEnabled;
  String? logo;

  factory CompanyModel.fromJson(String str) => CompanyModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CompanyModel.fromMap(Map<String, dynamic> json) => CompanyModel(
    id: json["id"],
    name: json["name"],
    companyID: json["companyID"],
    fiscalisationEnabled: json["fiscalisationEnabled"],
    logo: json["logo"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "companyID": companyID,
    "fiscalisationEnabled": fiscalisationEnabled,
    "logo": logo,
  };
}