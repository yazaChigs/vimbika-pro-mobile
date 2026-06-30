import 'dart:convert';
import 'package:vimbika_pro/model/company.dart';

import 'base_name_entity.dart';
import 'currency.dart';
import 'inventory_item.dart';

Subscription SubscriptionFromJson(String str) => Subscription.fromJson(json.decode(str));
String SubscriptionToJson(Subscription data) => json.encode(data.toMap());

class Subscription extends BaseNameEntity {
  Subscription({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? name,
    String? description,
    this.active,
    this.currency,
    this.renewalAmount,
    this.renewalDate,
    this.subscription,
    this.company,
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
          name: name ?? '',
          description: description,
        );

  final bool? active;
  final Currency? currency;
  final double? renewalAmount;
  final String? renewalDate;
  final InventoryItem? subscription;
  final Company? company;

  DateTime? getRenewalDate() {
    if (renewalDate != null) {
      try {
        return DateTime.parse(renewalDate!);
      } catch (e) {
        print('Error parsing renewalDate: $e');
      }
    }
    if (dateCreated != null) {
      try {
        return DateTime.parse(dateCreated!);
      } catch (e) {
        print('Error parsing dateCreated for renewalDate: $e');
      }
    }
    return null;
  }

  Subscription copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? name,
    String? description,
    bool? active,
    Currency? currency,
    double? renewalAmount,
    String? renewalDate,
    InventoryItem? subscription,
    Company? company
  }) {
    return Subscription(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      name: name ?? this.name,
      description: description ?? this.description,
      active: active ?? this.active,
      currency: currency ?? this.currency,
      renewalAmount: renewalAmount ?? this.renewalAmount,
      renewalDate: renewalDate ?? this.renewalDate,
      subscription: subscription ?? this.subscription,
      company: company ?? this.company,
    );
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription.fromMap(json);
  }

  Map<String, dynamic> toJson() => toMap();

  factory Subscription.fromMap(Map<String, dynamic> json) => Subscription(
        id: json["id"]?.toString(),
        dateCreated: json["dateCreated"]?.toString(),
        dateModified: json["dateModified"]?.toString(),
        createdByName: json["createdByName"]?.toString(),
        modifiedByName: json["modifiedByName"]?.toString(),
        version: json["version"] is int ? json["version"] : null,
        name: json["name"]?.toString(),
        description: json["description"]?.toString(),
        active: json["active"] == true || json["active"] == 'true',
        currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
        renewalAmount: (json["renewalAmount"] as num?)?.toDouble() ?? 0.0,
        renewalDate: json["renewalDate"]?.toString(),
        subscription: json['subscription'] != null ? InventoryItem.fromJson(json['subscription']) : null,
    company: json['company'] != null ? Company.fromJson(json['company']) : null,
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "dateCreated": dateCreated,
        "dateModified": dateModified,
        "createdByName": createdByName,
        "modifiedByName": modifiedByName,
        "version": version,
        "name": name,
        "description": description,
        "active": active,
        "currency": currency?.toJson(),
        "renewalAmount": renewalAmount,
        "renewalDate": renewalDate,
        "subscription": subscription?.toJson(),
        "company": company?.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subscription &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          dateCreated == other.dateCreated &&
          active == other.active &&
          currency == other.currency &&
          renewalAmount == other.renewalAmount &&
          renewalDate == other.renewalDate &&
          subscription == other.subscription &&
          company == other.company;

  @override
  int get hashCode =>
      id.hashCode ^
      dateCreated.hashCode ^
      active.hashCode ^
      currency.hashCode ^
      renewalAmount.hashCode ^
      renewalDate.hashCode ^
      subscription.hashCode^
      company.hashCode;
}
