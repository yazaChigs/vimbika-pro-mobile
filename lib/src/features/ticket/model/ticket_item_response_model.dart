import 'dart:convert';

import 'package:vimbika_pos_app/src/features/ticket/model/ticket_model.dart';

class TicketItemResponseModel {
  TicketItemResponseModel({
    this.message,
    this.item,
  });

  String? message;
  TicketModel? item;

  factory TicketItemResponseModel.fromJson(String str) => TicketItemResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory TicketItemResponseModel.fromMap(Map<String, dynamic> json) => TicketItemResponseModel(
    message: json["message"],
      item: json["item"] != null ? TicketModel.fromMap(json["item"]) : null
  );

  Map<String, dynamic> toMap() => {
    "message": message,
    "item": item!.toMap(),
  };
}