import 'dart:convert';
import 'package:vimbika_pos_app/src/features/authentication/model/user_role_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/currency_amount.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';

ShiftModel shiftModelFromJson(String str) => ShiftModel.fromJson(json.decode(str));

String shiftModelToJson(ShiftModel data) => json.encode(data.toJson());

class ShiftModel {
  ShiftModel({
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
  List<CurrencyAmount>? shiftCurrencyAmounts;
  BaseNameModel? company;
  String? openingTime;
  String? closingTime;
  String? shiftReference;
  bool? synced = false;
  bool? stopSync = false;
  int? kotNumber = 0;


  factory ShiftModel.fromJson(String str) => ShiftModel.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());
  factory ShiftModel.fromMap(Map<String, dynamic> json) => ShiftModel(
    id: json["id"],
    userId: json["userId"],
    isShiftClosed: json["isShiftClosed"],
    userFullName: json["userFullName"] ?? "",
    dateCreated: json["dateCreated"],
    kotNumber: json["kotNUmber"],
    createdByName: json["createdByName"],
    active: json["active"],
    shiftCurrencyAmounts: List<CurrencyAmount>.from(json["shiftCurrencyAmounts"].map((x) => CurrencyAmount.fromMap(x))),
    company: BaseNameModel.fromMap(json["company"]),
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
    "shiftCurrencyAmounts": List<dynamic>.from(shiftCurrencyAmounts!.map((x) => x.toMap())),
    "company": company!.toMap(),
    "openingTime": openingTime,
    "closingTime": closingTime,
    "shiftReference": shiftReference,
    "synced": synced,
    "stopSync": stopSync,
    "kotNUmber": kotNumber
  };


}