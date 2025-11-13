import 'dart:convert';
import 'dart:ffi';

import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

SettingsModel settingsModelFromJson(String str) => SettingsModel.fromJson(json.decode(str));
String settingsModelToJson(SettingsModel data) => json.encode(data.toJson());
class SettingsModel {
  SettingsModel({
    this.id,
    this.useProductBrands,
    this.specifyProductDepartment,
    this.showPricingExcludingTax,
    this.enableDiscounts,
    this.userSerialNumbers,
    this.useProduction,
    this.sellNilItems,
    this.showPriceOnDelivery,
    this.showBrands,
    this.autoDeliver,
    this.saleOnConsignment,
    this.useSerialNumbers,
    this.showAmountBeforeTax,
    this.pointsThreshold,
    this.pointsRate,
    this.enableWaInvReq = false,
    this.whatsappNumber,

  });

  String? id;
  String? whatsappNumber;
  bool? useProductBrands;
  bool? specifyProductDepartment;
  bool? showPricingExcludingTax;
  bool? enableDiscounts;
  bool? userSerialNumbers;
  bool? useProduction;
  bool? sellNilItems;
  bool? showPriceOnDelivery;
  bool? showBrands;
  bool? autoDeliver;
  bool? saleOnConsignment;
  bool? useSerialNumbers;
  bool? showAmountBeforeTax;
  bool? enableWaInvReq = false;
  double? pointsThreshold;
  double? pointsRate;

  factory SettingsModel.fromJson(String str) => SettingsModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SettingsModel.fromMap(Map<String, dynamic> json) => SettingsModel(
    id: json["id"],
    useProductBrands: json["useProductBrands"],
    specifyProductDepartment: json["specifyProductDepartment"],
    showPricingExcludingTax: json["showPricingExcludingTax"],
    enableDiscounts: json["enableDiscounts"],
    userSerialNumbers: json["userSerialNumbers"],
    useProduction: json["useProduction"],
    sellNilItems: json["sellNilItems"],
    showPriceOnDelivery: json["showPriceOnDelivery"],
    showBrands: json["showBrands"],
    autoDeliver: json["autoDeliver"],
    saleOnConsignment: json["saleOnConsignment"],
    useSerialNumbers: json["useSerialNumbers"],
    showAmountBeforeTax: json["showAmountBeforeTax"],
    pointsThreshold: json["pointsThreshold"],
    pointsRate: json["pointsRate"],
    enableWaInvReq: json["enableWaInvReq"],
    whatsappNumber: json["whatsappNumber"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "useProductBrands": useProductBrands,
    "specifyProductDepartment": specifyProductDepartment,
    "showPricingExcludingTax": showPricingExcludingTax,
    "enableDiscounts": enableDiscounts,
    "userSerialNumbers": userSerialNumbers,
    "useProduction": useProduction,
    "sellNilItems": sellNilItems,
    "showPriceOnDelivery": showPriceOnDelivery,
    "showBrands": showBrands,
    "autoDeliver": autoDeliver,
    "saleOnConsignment": saleOnConsignment,
    "useSerialNumbers": useSerialNumbers,
    "showAmountBeforeTax": showAmountBeforeTax,
    "pointsThreshold": pointsThreshold,
    "pointsRate": pointsRate,
    "enableWaInvReq": enableWaInvReq,
    "whatsappNumber": whatsappNumber,
  };
}