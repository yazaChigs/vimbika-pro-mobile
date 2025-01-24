import 'dart:convert';

import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';

class SaleResponseModel {
  SaleResponseModel({
    this.message,
    this.sales,
  });

  String? message;
  List<SaleModel>? sales;

  factory SaleResponseModel.fromJson(String str) => SaleResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory SaleResponseModel.fromMap(Map<String, dynamic> json) => SaleResponseModel(
    message: json["message"],
    sales: json["sales"] != null ? List<SaleModel>.from(json["sales"].map((x) => SaleModel.fromMap(x))) : [],
  );

  Map<String, dynamic> toMap() => {
    "message": message,
    "sales": sales != null ? List<dynamic>.from(sales!.map((x) => x.toMap())) : [],
  };
}