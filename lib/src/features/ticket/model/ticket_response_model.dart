import 'dart:convert';

import 'package:vimbika_pos_app/src/features/ticket/model/ticket_model.dart';

class TicketResponseModel {
  TicketResponseModel({
    this.message,
    this.items,
  });

  String? message;
  List<TicketModel>? items;

  factory TicketResponseModel.fromJson(String str) => TicketResponseModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory TicketResponseModel.fromMap(Map<String, dynamic> json) => TicketResponseModel(
    message: json["message"],
    items: json["items"] != null ? List<TicketModel>.from(json["items"].map((x) => TicketModel.fromMap(x))) : [],
  );

  Map<String, dynamic> toMap() => {
    "message": message,
    "items": items != null ? List<dynamic>.from(items!.map((x) => x.toMap())) : [],
  };
}