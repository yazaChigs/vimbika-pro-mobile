import 'dart:convert';

import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_model.dart';
import 'package:vimbika_pos_app/src/shared/models/customer_model.dart';

class CustomerResponseModel {
  CustomerResponseModel({
    this.message,
    this.item,
  });

  String? message;
  CustomerModel? item;

  factory CustomerResponseModel.fromJson(String str) => CustomerResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CustomerResponseModel.fromMap(Map<String, dynamic> json) => CustomerResponseModel(
      message: json["message"],
      item: json["item"] != null ? CustomerModel.fromMap(json["item"]) : null
  );

  Map<String, dynamic> toMap() => {
    "message": message,
    "item": item != null?  item!.toMap() : null,
  };
}