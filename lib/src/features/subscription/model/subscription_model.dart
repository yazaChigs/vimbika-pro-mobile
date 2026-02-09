import 'dart:convert';

import '../../../shared/models/currency_model.dart';
import '../../sale/model/inventory_item_model.dart';


SubscriptionModel subscriptionModelFromJson(String str) => SubscriptionModel.fromJson(str);

String subscriptionModelToJson(SubscriptionModel data) => data.toJson();

class SubscriptionModel {
  SubscriptionModel({
    this.id,
    this.active,
    this.currency,
    this.renewalAmount,
    this.renewalDate,
    this.subscription,
  });

  String? id;
  bool? active;
  CurrencyModel? currency;
  double? renewalAmount;
  DateTime? renewalDate;
  InventoryItemModel? subscription;

  factory SubscriptionModel.fromJson(String str) => SubscriptionModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SubscriptionModel.fromMap(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json["id"],
      active: json["active"],
      currency: json["currency"] == null ? null : CurrencyModel.fromMap(json["currency"]),
      renewalAmount: json["renewalAmount"]?.toDouble(),
      renewalDate: json["renewalDate"] == null ? null : DateTime.parse(json["renewalDate"]),
      subscription: json["subscription"] == null ? null : InventoryItemModel.fromMap(json["subscription"]),
    );
  }

  Map<String, dynamic> toMap() => {
    "id": id,
    "active": active,
    "currency": currency?.toMap(),
    "renewalAmount": renewalAmount,
    "renewalDate": renewalDate?.toIso8601String(),
    "subscription": subscription?.toMap(),
  };
}
