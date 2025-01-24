import 'dart:convert';
import 'base_name_model.dart';

CustomerModel customerModelFromJson(String str) => CustomerModel.fromJson(json.decode(str));
String customerModelToJson(CustomerModel data) => json.encode(data.toJson());
class CustomerModel {
  CustomerModel({
    this.id,
    this.name,
    this.companyName,
    this.email,
    this.mobilePhone,
    this.customerId,
    this.branch,
    this.description,
    this.tinNumber,
    this.taxNumber,
    this.street

  });

  String? id;
  String? name;
  String? companyName;
  String?  email;
  String?  mobilePhone;
  String?  customerId;
  BaseNameModel? branch;
  String?  description;
  String? tinNumber;
  String? taxNumber;
  String? street;

  factory CustomerModel.fromJson(String str) => CustomerModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CustomerModel.fromMap(Map<String, dynamic> json) => CustomerModel(
    id: json["id"],
    name: json["name"],
    companyName: json["companyName"],
    email: json["email"],
    mobilePhone: json["mobilePhone"],
    customerId: json["customerId"],
    branch: json["branch"] != null ? BaseNameModel.fromMap(json["branch"]) : null,
    description: json["description"],

    tinNumber: json["tinNumber"],
    taxNumber: json["taxNumber"],
    street: json["street"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "companyName": companyName,
    "email": email,
    "mobilePhone": mobilePhone,
    "customerId": customerId,
    "branch": branch?.toMap(),
    "description": description,

    "tinNumber": tinNumber,
    "taxNumber": taxNumber,
    "street": street,
  };
}