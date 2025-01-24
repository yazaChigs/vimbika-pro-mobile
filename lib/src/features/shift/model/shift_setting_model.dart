import 'dart:convert';
import 'package:vimbika_pos_app/src/features/authentication/model/user_role_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/currency_amount.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';

ShiftSettingModel shiftSettingModelFromJson(String str) => ShiftSettingModel.fromJson(json.decode(str));

String shiftSettingModelToJson(ShiftSettingModel data) => json.encode(data.toJson());

class ShiftSettingModel {
  ShiftSettingModel({
    this.id,
    this.shiftDuration,
  });

  String? id;
  int? shiftDuration;

  factory ShiftSettingModel.fromJson(String str) => ShiftSettingModel.fromMap(json.decode(str));
  String toJson() => json.encode(toMap());
  factory ShiftSettingModel.fromMap(Map<String, dynamic> json) => ShiftSettingModel(
    id: json["id"],
    shiftDuration: json["shiftDuration"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "shiftDuration": shiftDuration,
  };


}