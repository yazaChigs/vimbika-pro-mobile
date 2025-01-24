import 'dart:convert';


FiscalDeviceModel fiscalModelFromJson(String str) => FiscalDeviceModel.fromJson(json.decode(str));
String fiscalModelToJson(FiscalDeviceModel data) => json.encode(data.toJson());
class FiscalDeviceModel {
  FiscalDeviceModel({
    this.id,
    this.deviceId,
    this.deviceSerialNo,
    this.vatNumber,
    this.isDeviceRegistered,
  });

  String? id;
  int? deviceId;
  String? deviceSerialNo;
  String? vatNumber;
  bool? isDeviceRegistered;

  factory FiscalDeviceModel.fromJson(String str) => FiscalDeviceModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory FiscalDeviceModel.fromMap(Map<String, dynamic> json) => FiscalDeviceModel(
    id: json["id"],
    deviceId: json["deviceId"],
    deviceSerialNo: json["deviceSerialNo"],
    vatNumber: json["vatNumber"],
    isDeviceRegistered: json["isDeviceRegistered"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "deviceSerialNo": deviceSerialNo,
    "deviceId": deviceId,
    "vatNumber": vatNumber,
    "isDeviceRegistered": isDeviceRegistered,
  };
}