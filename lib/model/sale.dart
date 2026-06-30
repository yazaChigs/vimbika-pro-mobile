import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/sale_item.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import 'package:vimbika_pro/model/currency.dart';

part 'sale.g.dart';

@collection
class Sale {
  Id isarId = Isar.autoIncrement;
  String? id;
  String? dateCreated;
  String? dateModified;
  String? createdByName;
  String? modifiedByName;
  int? version;
  String? cashierFullName;
  final customer = IsarLink<Customer>();
  final company = IsarLink<Company>();
  final branch = IsarLink<Branch>();
  @ignore
  final items = IsarLinks<SaleItem>();
  @ignore
  final paymentTypes = IsarLinks<PaymentReceived>();
  String? timeIniated;
  String? timeCompleted;
  String? saleStatus;
  final currency = IsarLink<Currency>();
  final baseCurrency = IsarLink<Currency>();
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
    this.timeIniated,
    this.timeCompleted,
    this.saleStatus,
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

  double get grandTotal {
    items.loadSync();
    return items.fold(0.0, (sum, item) => sum + item.total);
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    final sale = Sale(
      id: json['id'],
      dateCreated: json['dateCreated'],
      dateModified: json['dateModified'],
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      cashierFullName: json['cashierFullName'],
      timeIniated: json['timeIniated'],
      timeCompleted: json['timeCompleted'],
      saleStatus: json['saleStatus'],
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
    if (json['customer'] != null) {
      sale.customer.value = Customer.fromJson(json['customer']);
    }
    if (json['company'] != null) {
      sale.company.value = Company.fromJson(json['company']);
    }
    if (json['branch'] != null) {
      sale.branch.value = Branch.fromJson(json['branch']);
    }
    if (json['currency'] != null) {
      sale.currency.value = Currency.fromJson(json['currency']);
    }
    if (json['baseCurrency'] != null) {
      sale.baseCurrency.value = Currency.fromJson(json['baseCurrency']);
    }
    return sale;
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
      'timeIniated': timeIniated,
      'timeCompleted': timeCompleted,
      'saleStatus': saleStatus,
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
      'customer': customer.value?.toJson(),
      'company': company.value?.toJson(),
      'branch': branch.value?.toJson(),
      'currency': currency.value?.toJson(),
      'baseCurrency': baseCurrency.value?.toJson(),
    };
  }

  Sale copyWith({
    Id? isarId,
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? cashierFullName,
    String? timeIniated,
    String? timeCompleted,
    String? saleStatus,
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
    final newSale = Sale(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      cashierFullName: cashierFullName ?? this.cashierFullName,
      timeIniated: timeIniated ?? this.timeIniated,
      timeCompleted: timeCompleted ?? this.timeCompleted,
      saleStatus: saleStatus ?? this.saleStatus,
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

    newSale.isarId = isarId ?? this.isarId;
    newSale.customer.value = customer.value;
    newSale.company.value = company.value;
    newSale.branch.value = branch.value;
    newSale.items.addAll(items);
    newSale.paymentTypes.addAll(paymentTypes);
    newSale.currency.value = currency.value;
    newSale.baseCurrency.value = baseCurrency.value;

    return newSale;
  }
}
