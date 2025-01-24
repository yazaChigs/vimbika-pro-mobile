import 'dart:convert';

import 'package:vimbika_pos_app/src/features/sale/model/cart_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/company_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';

class TicketModel {
  TicketModel({
    required this.id,
    required this.branch,
    required this.ticketName,
    required this.openedBy,
    required this.ticketStatus,
    required this.cartItems,
    required this.ticketComment,
    required this.timeInitiated,
    this.company,
    this.timeClosed,
    required this.reference,
    required this.totalAmount,
    required this.currency,
     this.closedBy,
    this.synced
  });
  String? id;
  BaseNameModel branch;
  String ticketStatus;
  String openedBy;
  String? closedBy;
  List<CartItemModel>? cartItems;
  String? ticketName;

  String? ticketComment;
  String? timeInitiated;
  String? timeClosed;
  String? reference;
  double? totalAmount;
  CurrencyModel? currency;
  bool? synced;
  CompanyModel? company;
  factory TicketModel.fromJson(Map<String, dynamic> json) => TicketModel.fromMap(json);
  String toJson() => json.encode(toMap());
  factory TicketModel.fromMap(Map<String, dynamic> json) => TicketModel(
    id: json["id"],
    ticketName: json["ticketName"],
    ticketStatus: json["ticketStatus"],
    branch: BaseNameModel.fromMap(json["branch"]),
    openedBy: json["openedBy"],
    closedBy: json["closedBy"],
    cartItems: json["cartItems"] != null ? List<CartItemModel>.from(json["cartItems"].map((x) => CartItemModel.fromMap(x))) : [],
    ticketComment: json["ticketComment"],
    company: CompanyModel.fromMap(json["company"]),
    timeInitiated: json["timeInitiated"],
    timeClosed: json["timeClosed"],
    synced: json["synced"],
    reference: json["reference"],
    totalAmount: json["totalAmount"],
    currency: json["currency"] != null ? CurrencyModel.fromMap(json["currency"]) : null,
  );
  Map<String, dynamic> toMap() => {
    "id": id,
    "ticketName": ticketName,
    "branch": branch.toMap(),
    "company": company!.toMap(),
    "ticketStatus": ticketStatus,
    "openedBy": openedBy,
    "closedBy": closedBy,
    "cartItems": cartItems != null ? List<dynamic>.from(cartItems!.map((x) => x.toMap())) : [],
    "ticketComment": ticketComment,
    "timeInitiated": timeInitiated,
    "timeClosed": timeClosed,
    "reference": reference,
    "totalAmount": totalAmount,
    "synced": synced,
    "currency": currency!.toMap(),
  };

}