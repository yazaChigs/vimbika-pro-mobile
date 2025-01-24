import 'dart:convert';

import 'package:vimbika_pos_app/src/features/sale/model/product_image_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/inventory_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_item_model.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/shared/models/customer_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_received_model.dart';
import 'package:vimbika_pos_app/src/shared/models/payment_type_model.dart';

SaleModel saleModelFromJson(String str) => SaleModel.fromJson(json.decode(str));
String saleModelToJson(SaleModel data) => json.encode(data.toJson());

class SaleModel {
  SaleModel({
     this.id,
    this.cashierFullName,
    this.createdByName,
    required this.saleStatus,

    required this.onHold,
    required this.amountPaid,
    required this.totalQuantity,
    required this.saleCost,


    required this.totalTaxAmount,

    required this.baseSaleAmount,
    required this.referenceNumber,
    required this.change,
    required this.customerAmountPaid,
    required this.timeIniated,
    required this.timeInit,

    required this.currency,
    required this.baseCurrency,
    required this.paymentType,
    required this.items,
    required this.branch,
    required this.amountAfterDiscount,

    required this.shiftReference,
    required this.posReference,
    required this.customer,
    required this.taxInvoice,
    required this.fiscalized,
    required this.emailReceipt,
    required this.isWalkInCustomer,
    required this.totalDiscount,

    required this.ticketName,
    required this.ticketComment,
    this.zeroRatedTotal,
    this.receiptQrCode,
    this.receiptQrData,
    this.paymentTypes

  });

  String? id;
  String? cashierFullName;
  String? createdByName;
  String? saleStatus;
  double? amountPaid;
  double? totalQuantity;
  double? saleCost;

  double? totalTaxAmount;
  double? baseSaleAmount;
  double? change;
  double? customerAmountPaid;
  String? referenceNumber;
  String? timeIniated;
  String? timeInit;
  String? shiftReference;
  String? posReference;
  String? receiptQrCode;

  String? ticketName;
  String? ticketComment;

  CurrencyModel? currency;
  CurrencyModel? baseCurrency;
  PaymentTypeModel? paymentType;
  List<SaleItemModel>? items;
  List<PaymentReceivedModel>? paymentTypes;
  BaseNameModel? branch;
  double? amountAfterDiscount;
  double? totalDiscount;
  double? zeroRatedTotal;
  CustomerModel? customer;
  bool? taxInvoice;
  bool? fiscalized;
  bool? onHold;
  bool? emailReceipt;
  bool? isWalkInCustomer;
  String? receiptQrData;


  factory SaleModel.fromJson(Map<String, dynamic> json) => SaleModel.fromMap(json);
  String toJson() => json.encode(toMap());

  factory SaleModel.fromMap(Map<String, dynamic> json) => SaleModel(
    id: json["id"],
    cashierFullName: json["cashierFullName"],
    createdByName: json["createdByName"],
    saleStatus: json["saleStatus"],
    onHold: json["onHold"],
    amountPaid: json["amountPaid"],
    totalQuantity: json["totalQuantity"],
    saleCost: json["saleCost"],
    totalTaxAmount: json["totalTaxAmount"],
    totalDiscount: json["totalDiscount"],
    zeroRatedTotal: json["zeroRatedTotal"],
    baseSaleAmount: json["baseSaleAmount"],
    change: json["change"],
    customerAmountPaid: json["customerAmountPaid"],
    referenceNumber: json["referenceNumber"],
    timeIniated: json["timeIniated"],
    timeInit: json["timeInit"],
    paymentType: json["paymentType"] != null ? PaymentTypeModel.fromMap(json["paymentType"]) : null,
    currency: json["currency"] != null ? CurrencyModel.fromMap(json["currency"]) : null,
    baseCurrency: json["baseCurrency"] != null ? CurrencyModel.fromMap(json["baseCurrency"]) : null,
    items: json["items"] != null ? List<SaleItemModel>.from(json["items"].map((x) => SaleItemModel.fromMap(x))) : [],
    paymentTypes: json["paymentTypes"] != null ? List<PaymentReceivedModel>.from(json["paymentTypes"].map((x) => PaymentReceivedModel.fromMap(x))) : [],

    branch: json["branch"] != null ? BaseNameModel.fromMap(json["branch"]) : null,
    amountAfterDiscount: json["amountAfterDiscount"],
    receiptQrCode: json["receiptQrCode"],
    receiptQrData: json["receiptQrData"],
    shiftReference: json["shiftReference"],
    posReference: json["posReference"],
    customer: json["customer"] != null ? CustomerModel.fromMap(json["customer"]) : null,
    taxInvoice: json["taxInvoice"],
    fiscalized: json["fiscalized"],
    emailReceipt: json["emailReceipt"],
    isWalkInCustomer: json["isWalkInCustomer"],

    ticketName: json["ticketName"],
    ticketComment: json["ticketComment"],

  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "cashierFullName": cashierFullName,
    "createdByName": createdByName,
    "saleStatus": saleStatus,
    "onHold": onHold,
    "amountPaid": amountPaid,
    "totalTaxAmount": totalTaxAmount,
    "zeroRatedTotal": zeroRatedTotal,
    "baseSaleAmount": baseSaleAmount,
    "totalDiscount": totalDiscount,
    "change": change,
    "customerAmountPaid": customerAmountPaid,
    "referenceNumber": referenceNumber,
    "timeIniated": timeIniated,
    "timeInit": timeInit,
    "currency": currency?.toMap(),
    "baseCurrency": baseCurrency?.toMap(),
    "paymentType": paymentType?.toMap(),
    "items": items != null ? List<dynamic>.from(items!.map((x) => x.toMap())) : [],
    "paymentTypes": paymentTypes != null ? List<dynamic>.from(paymentTypes!.map((x) => x.toMap())) : [],
    "saleCost": saleCost,
    "totalQuantity": totalQuantity,
    "branch": branch?.toMap(),
    "amountAfterDiscount": amountAfterDiscount,

    "shiftReference": shiftReference,
    "posReference": posReference,
    "receiptQrCode": receiptQrCode,
    "receiptQrData": receiptQrData,
    "customer": customer?.toMap(),

    "taxInvoice": taxInvoice,
    "fiscalized": fiscalized,
    "emailReceipt": emailReceipt,
    "isWalkInCustomer": isWalkInCustomer,

    "ticketName": ticketName,
    "ticketComment": ticketComment,

  };
}
