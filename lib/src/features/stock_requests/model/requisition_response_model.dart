import 'dart:convert';

import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_model.dart';

class RequisitionResponseModel {
  RequisitionResponseModel({
    this.message,
    this.item,
  });

  String? message;
  RequisitionModel? item;

  factory RequisitionResponseModel.fromJson(String str) => RequisitionResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RequisitionResponseModel.fromMap(Map<String, dynamic> json) => RequisitionResponseModel(
      message: json["message"],
      item: json["item"] != null ? RequisitionModel.fromMap(json["item"]) : null
  );

  Map<String, dynamic> toMap() => {
    "message": message,
    "item": item!.toMap(),
  };
}