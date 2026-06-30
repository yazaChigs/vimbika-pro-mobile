import 'dart:convert';

import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/sale_item.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import 'package:vimbika_pro/model/currency.dart';

class Sale {
  String? id;
  String? dateCreated;
  String? dateModified;
  String? createdByName;
  String? modifiedByName;
  int? version;
  String? cashierFullName;
  Customer? customer;
  Company? company;
  Branch? branch;
  List<SaleItem> items;
  List<PaymentReceived>? paymentTypes;
  String? timeIniated;
  String? timeCompleted;
  String? saleStatus;
  Currency? currency;
  Currency? baseCurrency;
  double? amountAfterDiscount;
  double? baseSaleAmount;
  double? totalTaxAmount;
  bool? isSynced;
  bool? fiscalized;
  bool? taxInvoice;
  double? totalQuantity;
  String? posReference;
  String? referenceNumber;
  String? shiftReference;
  String? ticketName;
  String? amtToAcc;
  String? customerAccBankType;
  double? amountPaid;
  double? change;
  double? amountTendered;
  String? receiptQrCode;
  String? receiptQrData;

  Sale({
    this.id,
    this.dateCreated,
    this.dateModified,
    this.createdByName,
    this.modifiedByName,
    this.version,
    this.cashierFullName,
    this.customer,
    this.company,
    this.branch,
    required this.items,
    this.paymentTypes,
    this.timeIniated,
    this.timeCompleted,
    this.saleStatus,
    this.currency,
    this.baseCurrency,
    this.amountAfterDiscount,
    this.baseSaleAmount,
    this.totalTaxAmount,
    this.isSynced,
    this.fiscalized,
    this.taxInvoice,
    this.totalQuantity,
    this.posReference,
    this.referenceNumber,
    this.shiftReference,
    this.ticketName,
    this.amtToAcc,
    this.customerAccBankType,
    this.amountPaid,
    this.change,
    this.amountTendered,
    this.receiptQrCode,
    this.receiptQrData,
  });

  double get grandTotal => items.fold(0, (sum, item) => sum + item.total);

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'],
      dateCreated: json['dateCreated'],
      dateModified: json['dateModified'],
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: (json['version'] as num?)?.toInt(),
      cashierFullName: json['cashierFullName'],
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      company: json['company'] != null ? Company.fromJson(json['company']) : null,
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      items: ((json['items'] ?? []) as List<dynamic>).map((item) => SaleItem.fromJson(item)).toList(),
      paymentTypes: (json['paymentTypes'] as List<dynamic>?)?.map((item) => PaymentReceived.fromJson(item)).toList(),
      timeIniated: json['timeIniated'],
      timeCompleted: json['timeCompleted'],
      saleStatus: json['saleStatus'],
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      baseCurrency: json['baseCurrency'] != null ? Currency.fromJson(json['baseCurrency']) : null,
      amountAfterDiscount: (json['amountAfterDiscount'] as num?)?.toDouble(),
      baseSaleAmount: (json['baseSaleAmount'] as num?)?.toDouble(),
      totalTaxAmount: (json['totalTaxAmount'] as num?)?.toDouble(),
      isSynced: json['isSynced'],
      fiscalized: json['fiscalized'],
      taxInvoice: json['taxInvoice'],
      totalQuantity: (json['totalQuantity'] as num?)?.toDouble(),
      posReference: json['posReference'],
      referenceNumber: json['referenceNumber'],
      shiftReference: json['shiftReference'],
      ticketName: json['ticketName'],
      amtToAcc: json['amtToAcc'],
      customerAccBankType: json['customerAccBankType'],
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      change: (json['change'] as num?)?.toDouble(),
      amountTendered: (json['amountTendered'] as num?)?.toDouble(),
      receiptQrCode: json['receiptQrCode'],
      receiptQrData: json['receiptQrData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateCreated': dateCreated,
      'dateModified': dateModified,
      'createdByName': createdByName,
      'modifiedByName': modifiedByName,
      'version': version,
      'cashierFullName': cashierFullName,
      'customer': customer?.toJson(),
      'company': company?.toJson(),
      'branch': branch?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'paymentTypes': paymentTypes?.map((item) => item.toJson()).toList(),
      'timeIniated': timeIniated,
      'timeCompleted': timeCompleted,
      'saleStatus': saleStatus,
      'currency': currency?.toJson(),
      'baseCurrency': baseCurrency?.toJson(),
      'amountAfterDiscount': amountAfterDiscount,
      'baseSaleAmount': baseSaleAmount,
      'totalTaxAmount': totalTaxAmount,
      'isSynced': isSynced,
      'fiscalized': fiscalized,
      'taxInvoice': taxInvoice,
      'totalQuantity': totalQuantity,
      'posReference': posReference,
      'referenceNumber': referenceNumber,
      'shiftReference': shiftReference,
      'ticketName': ticketName,
      'amtToAcc': amtToAcc,
      'customerAccBankType': customerAccBankType,
      'amountPaid': amountPaid,
      'change': change,
      'amountTendered': amountTendered,
      'receiptQrCode': receiptQrCode,
      'receiptQrData': receiptQrData,
    };
  }

  Sale copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? cashierFullName,
    Customer? customer,
    Company? company,
    Branch? branch,
    List<SaleItem>? items,
    List<PaymentReceived>? paymentTypes,
    String? timeIniated,
    String? timeCompleted,
    String? saleStatus,
    Currency? currency,
    Currency? baseCurrency,
    double? amountAfterDiscount,
    double? baseSaleAmount,
    double? totalTaxAmount,
    bool? isSynced,
    bool? fiscalized,
    bool? taxInvoice,
    double? totalQuantity,
    String? posReference,
    String? referenceNumber,
    String? shiftReference,
    String? ticketName,
    String? amtToAcc,
    String? customerAccBankType,
    double? amountPaid,
    double? change,
    double? amountTendered,
    String? receiptQrCode,
    String? receiptQrData,
  }) {
    return Sale(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      cashierFullName: cashierFullName ?? this.cashierFullName,
      customer: customer ?? this.customer,
      company: company ?? this.company,
      branch: branch ?? this.branch,
      items: items ?? this.items,
      paymentTypes: paymentTypes ?? this.paymentTypes,
      timeIniated: timeIniated ?? this.timeIniated,
      timeCompleted: timeCompleted ?? this.timeCompleted,
      saleStatus: saleStatus ?? this.saleStatus,
      currency: currency ?? this.currency,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      amountAfterDiscount: amountAfterDiscount ?? this.amountAfterDiscount,
      baseSaleAmount: baseSaleAmount ?? this.baseSaleAmount,
      totalTaxAmount: totalTaxAmount ?? this.totalTaxAmount,
      isSynced: isSynced ?? this.isSynced,
      fiscalized: fiscalized ?? this.fiscalized,
      taxInvoice: taxInvoice ?? this.taxInvoice,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      posReference: posReference ?? this.posReference,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      shiftReference: shiftReference ?? this.shiftReference,
      ticketName: ticketName ?? this.ticketName,
      amtToAcc: amtToAcc ?? this.amtToAcc,
      customerAccBankType: customerAccBankType ?? this.customerAccBankType,
      amountPaid: amountPaid ?? this.amountPaid,
      change: change ?? this.change,
      amountTendered: amountTendered ?? this.amountTendered,
      receiptQrCode: receiptQrCode ?? this.receiptQrCode,
      receiptQrData: receiptQrData ?? this.receiptQrData,
    );
  }
}
