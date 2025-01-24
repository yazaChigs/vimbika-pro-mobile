import 'dart:convert';

import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';

class ShiftResponseModel {
  ShiftResponseModel({
    this.message,
    this.items,
  });

  String? message;
  List<ShiftModel>? items;

  factory ShiftResponseModel.fromJson(String str) => ShiftResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ShiftResponseModel.fromMap(Map<String, dynamic> json) => ShiftResponseModel(
    message: json["message"],
    items: json["items"] != null ? List<ShiftModel>.from(json["items"].map((x) => ShiftModel.fromMap(x))) : [],
  );

  Map<String, dynamic> toMap() => {
    "message": message,
    "items": items != null ? List<dynamic>.from(items!.map((x) => x.toMap())) : [],
  };
}