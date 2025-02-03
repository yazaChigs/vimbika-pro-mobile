import 'dart:convert';

import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/transfer_history_model.dart';

class TransferHistoryResponseModel {
  TransferHistoryResponseModel({
    this.message,
    this.item,
  });

  String? message;
  TransferHistoryModel? item;

  factory TransferHistoryResponseModel.fromJson(String str) => TransferHistoryResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory TransferHistoryResponseModel.fromMap(Map<String, dynamic> json) => TransferHistoryResponseModel(
      message: json["message"],
      item: json["item"] != null ? TransferHistoryModel.fromMap(json["item"]) : null
  );

  Map<String, dynamic> toMap() => {
    "message": message,
    "item": item != null?  item!.toMap() : null,
  };
}