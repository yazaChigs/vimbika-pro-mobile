import 'dart:convert';

import 'package:vimbika_pro/model/base_name_model.dart';
import 'package:vimbika_pro/model/mobile_shift_currency_amount.dart';

MobilePosShift shiftModelFromJson(String str) => MobilePosShift.fromRawJson(str);

String shiftModelToJson(MobilePosShift data) => json.encode(data.toMap());

class MobilePosShift {
  MobilePosShift({
    this.id,
    this.createdByName,
    this.dateCreated,
    this.active,
    this.userId,
    this.userFullName,
    this.isShiftClosed = false,
    this.shiftCurrencyAmounts,
    this.company,
    this.openingTime,
    this.closingTime,
    this.shiftReference,
    this.synced = false,
    this.stopSync = false,
    this.kotNumber,
  });

  String? id;
  String? createdByName;
  String? dateCreated;
  bool? active = true;
  String? userId;
  bool? isShiftClosed = false;
  String? userFullName;
  List<MobileShiftCurrencyAmount>? shiftCurrencyAmounts;
  BaseNameModel? company;
  String? openingTime;
  String? closingTime;
  String? shiftReference;
  bool? synced = false;
  bool? stopSync = false;
  int? kotNumber = 0;


  factory MobilePosShift.fromRawJson(String str) {
    final dynamic decoded = json.decode(str);
    if (decoded is Map<String, dynamic>) {
      return MobilePosShift.fromJson(decoded);
    } else {
      throw FormatException("Invalid JSON for MobilePosShift: Expected a JSON object, but got a ${decoded.runtimeType}");
    }
  }
  String toJson() => json.encode(toMap());
  factory MobilePosShift.fromJson(Map<String, dynamic> json) => MobilePosShift(
    id: json["id"],
    userId: json["userId"],
    isShiftClosed: json["isShiftClosed"],
    userFullName: json["userFullName"] ?? "",
    dateCreated: json["dateCreated"],
    kotNumber: json["kotNumber"], // Fixed typo here
    createdByName: json["createdByName"],
    active: json["active"],
    shiftCurrencyAmounts: json["shiftCurrencyAmounts"] != null
        ? List<MobileShiftCurrencyAmount>.from(json["shiftCurrencyAmounts"].map((x) => MobileShiftCurrencyAmount.fromJson(x)))
        : null,
    company: json["company"] != null ? BaseNameModel.fromJson(json["company"]) : null,
    openingTime: json["openingTime"],
    closingTime: json["closingTime"],
    shiftReference: json["shiftReference"],
    synced: json["synced"],
    stopSync: json["stopSync"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "userId": userId,
    "isShiftClosed": isShiftClosed,
    "userFullName": userFullName,
    "dateCreated": dateCreated,
    "active": active,
    "createdByName": createdByName,
    "shiftCurrencyAmounts": shiftCurrencyAmounts != null ? List<dynamic>.from(shiftCurrencyAmounts!.map((x) => x.toMap())) : null,
    "company": company?.toMap(),
    "openingTime": openingTime,
    "closingTime": closingTime,
    "shiftReference": shiftReference,
    "synced": synced,
    "stopSync": stopSync,
    "kotNumber": kotNumber // Fixed typo here
  };


}