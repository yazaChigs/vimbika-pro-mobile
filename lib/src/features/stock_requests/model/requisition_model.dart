import 'dart:convert';

import 'package:vimbika_pos_app/src/features/sale/model/product_image_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/inventory_item_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_item_model.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

RequisitionModel requisitionModelFromJson(String str) => RequisitionModel.fromJson(json.decode(str));
String requisitionModelToJson(RequisitionModel data) => json.encode(data.toJson());

class RequisitionModel {
  RequisitionModel({
    this.id,
    this.uuid,
    this.dateCreated,
    this.createdByName,
    this.company,
    this.requisitionStatus,
    this.timeRequested,
    this.referenceNumber,
    this.quantities,
     this.branch,
     this.warehouse,
     this.requisitionItems,
    this.syncStatus
  });

  String? id;
  String? uuid;
  String? dateCreated;
  String? createdByName;
  BaseNameModel? company;
  String? requisitionStatus;
  String? timeRequested;
  String? referenceNumber;
  double? quantities;
  BranchModel? branch;
  BranchModel? warehouse;
  List<RequisitionItemModel>? requisitionItems;
  bool? syncStatus;


  factory RequisitionModel.fromJson(Map<String, dynamic> json) => RequisitionModel.fromMap(json);
  String toJson() => json.encode(toMap());

  factory RequisitionModel.fromMap(Map<String, dynamic> json) => RequisitionModel(
    id: json["id"],
    uuid: json["uuid"],
    dateCreated: json["dateCreated"],
    createdByName: json["createdByName"],
    company: json["company"] != null ? BaseNameModel.fromMap(json["company"]) : null,
    requisitionStatus: json["requisitionStatus"],
    timeRequested: json["timeRequested"],
    referenceNumber: json["referenceNumber"],
    quantities: json["quantities"],
    branch: json["branch"] != null ? BranchModel.fromMap(json["branch"]) : null,
    warehouse: json["warehouse"] != null ? BranchModel.fromMap(json["warehouse"]) : null,
    requisitionItems: json["requisitionItems"] != null ? List<RequisitionItemModel>.from(json["requisitionItems"].map((x) => RequisitionItemModel.fromMap(x))) : [],
    syncStatus: json["syncStatus"],

  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "uuid": uuid,
    "dateCreated": dateCreated,
    "createdByName": createdByName,
    "company": company != null?  company!.toMap() : null,
    "requisitionStatus": requisitionStatus,
    "timeRequested": timeRequested,
    "referenceNumber": referenceNumber,
    "quantities": quantities,
    "branch": branch != null?  branch!.toMap() : null,
    "warehouse": warehouse != null?  warehouse!.toMap() : null,
    "requisitionItems": requisitionItems != null ? List<dynamic>.from(requisitionItems!.map((x) => x.toMap())) : [],
    "syncStatus": syncStatus,
  };
}
