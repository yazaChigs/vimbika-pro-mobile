import 'dart:convert';

import 'currency.dart';
import 'inventory_item.dart';


Subscription SubscriptionFromJson(String str) => Subscription.fromJson(json.decode(str));
String SubscriptionToJson(Subscription data) => json.encode(data.toMap());

class Subscription {
  Subscription({
    this.id,
    this.active,
    this.currency,
    this.renewalAmount,
    this.renewalDate,
    this.subscription,
  });

  String? id;
  bool? active;
  Currency? currency;
  double? renewalAmount;
  DateTime? renewalDate;
  InventoryItem? subscription;

  Subscription copyWith({
    String? id,
    bool? active,
    Currency? currency,
    double? renewalAmount,
    DateTime? renewalDate,
    InventoryItem? subscription,
  }) {
    return Subscription(
      id: id ?? this.id,
      active: active ?? this.active,
      currency: currency ?? this.currency,
      renewalAmount: renewalAmount ?? this.renewalAmount,
      renewalDate: renewalDate ?? this.renewalDate,
      subscription: subscription ?? this.subscription,
    );
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription.fromMap(json);
  }

  Map<String, dynamic> toJson() => toMap();

  factory Subscription.fromMap(Map<String, dynamic> json) => Subscription(
    id: json["id"]?.toString(),
    active: json["active"] == true || json["active"] == 'true',
    currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
    renewalAmount: (json["renewalAmount"] as num?)?.toDouble() ?? 0.0,
    renewalDate: json["renewalDate"] != null ? DateTime.parse(json["renewalDate"]) : null,
    subscription: json['subscription'] != null ? InventoryItem.fromJson(json['subscription']) : null,
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "active": active,
    "currency": currency?.toMap(),
    "renewalAmount": renewalAmount,
    "renewalDate": renewalDate?.toIso8601String(),
    "subscription": subscription?.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Subscription &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              active == other.active &&
              currency == other.currency &&
              renewalAmount == other.renewalAmount &&
              renewalDate == other.renewalDate &&
              subscription == other.subscription;

  @override
  int get hashCode =>
      id.hashCode ^
      active.hashCode ^
      currency.hashCode ^
      renewalAmount.hashCode ^
      renewalDate.hashCode ^
      subscription.hashCode;
}
