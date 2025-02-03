import 'dart:convert';

import 'package:vimbika_pos_app/src/features/sale/model/product_image_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/inventory_item_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_item_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/transfer_item_model.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

TransferHistoryModel transferHistoryModelFromJson(String str) => TransferHistoryModel.fromJson(json.decode(str));
String transferHistoryModelToJson(TransferHistoryModel data) => json.encode(data.toJson());

class TransferHistoryModel {
  TransferHistoryModel({
    this.id,
    this.dateCreated,
    this.createdByName,
    this.company,
    this.status,
    this.dateTime,
    this.reference,
    required this.fromBranch,
    required this.toBranch,
    required this.transferItems,
    this.syncStatus
  });

  String? id;
  String? dateCreated;
  String? createdByName;
  BaseNameModel? company;
  String? status;
  String? dateTime;
  String? reference;
  BranchModel? fromBranch;
  BranchModel? toBranch;
  List<TransferItemModel>? transferItems;
  bool? syncStatus;


  factory TransferHistoryModel.fromJson(Map<String, dynamic> json) => TransferHistoryModel.fromMap(json);
  String toJson() => json.encode(toMap());

  factory TransferHistoryModel.fromMap(Map<String, dynamic> json) => TransferHistoryModel(
    id: json["id"],
    dateCreated: json["dateCreated"],
    createdByName: json["createdByName"],
    company: json["company"] != null ? BaseNameModel.fromMap(json["company"]) : null,
    status: json["status"],
    dateTime: json["dateTime"],
    reference: json["reference"],
    fromBranch: json["fromBranch"] != null ? BranchModel.fromMap(json["fromBranch"]) : null,
    toBranch: json["toBranch"] != null ? BranchModel.fromMap(json["toBranch"]) : null,
    transferItems: json["transferItems"] != null ? List<TransferItemModel>.from(json["transferItems"].map((x) => TransferItemModel.fromMap(x))) : [],
    syncStatus: json["syncStatus"],

  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "dateCreated": dateCreated,
    "createdByName": createdByName,
    "company": company != null?  company!.toMap() : null,
    "status": status,
    "dateTime": dateTime,
    "reference": reference,
    "fromBranch": fromBranch != null?  fromBranch!.toMap() : null,
    "toBranch": toBranch != null?  toBranch!.toMap() : null,
    "transferItems": transferItems != null ? List<dynamic>.from(transferItems!.map((x) => x.toMap())) : [],
    "syncStatus": syncStatus,
  };
}
