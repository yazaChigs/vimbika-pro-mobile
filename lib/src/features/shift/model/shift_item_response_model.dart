import 'dart:convert';

import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';

class ShiftItemResponseModel {
  ShiftItemResponseModel({
    this.message,
    this.item,
    this.available = false
  });

  String? message;
  ShiftModel? item;
  bool? available = false;

  factory ShiftItemResponseModel.fromJson(String str) => ShiftItemResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ShiftItemResponseModel.fromMap(Map<String, dynamic> json) => ShiftItemResponseModel(
      message: json["message"],
      item: json["item"] != null ? ShiftModel.fromMap(json["item"]) : null,
    available: json["available"],
  );

  Map<String, dynamic> toMap() => {
    "message": message,
    "item": item!.toMap(),
    "available": available,
  };
}