import 'dart:convert';


SubscriptionModel subscriptionModelFromJson(String str) => SubscriptionModel.fromJson(json.decode(str));
String subscriptionModelToJson(SubscriptionModel data) => json.encode(data.toJson());
class SubscriptionModel {
  SubscriptionModel({
    this.id,
    this.name,
    this.companyID,
    this.fiscalisationEnabled,

  });

  String? id;
  String? name;
  String? companyID;
  bool? fiscalisationEnabled;

  factory SubscriptionModel.fromJson(String str) => SubscriptionModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SubscriptionModel.fromMap(Map<String, dynamic> json) => SubscriptionModel(
    id: json["id"],
    name: json["name"],
    companyID: json["companyID"],
    fiscalisationEnabled: json["fiscalisationEnabled"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "companyID": companyID,
    "fiscalisationEnabled": fiscalisationEnabled,
  };
}