import 'branch.dart';
import 'customer.dart';
import 'currency.dart';
import 'sale_item.dart';
import 'payment_received.dart';
import 'company.dart';
import 'payment_type.dart';
import 'sale_status.dart';

class OnlineSale {
  final String? id;
  final String? referenceNumber;
  final Customer? customer;
  final String? createdByName;
  final Currency? currency;
  final Currency? baseCurrency;
  final double? amountAfterDiscount;
  final double? balance;
  final double? saleCost;
  final double? reSaleCost;
  final String? paymentStatus;
  final double? baseSaleAmount;
  final String? timeIniated;
  final DateTime? followUpDate;
  final bool? isDelivered;
  final List<SaleItem>? items;
  final List<PaymentReceived>? paymentTypes;
  final Company? company;
  final bool? isProformaInvoice;
  final String? status;
  final String? orderNumber;
  final String? dateCreated;
  final DateTime? deliveryDate;
  final String? saleStatus;
  final bool? hasReturns;
  final bool? isRefunded;
  final bool? isReversible;
  final bool? isLessThan12Months;
  final double? totalTaxAmount;
  final double? standardRatedTotal;
  final double? zeroRatedTotal;
  final double? amountPaid;
  final Branch? branch;
  final String? shiftReference;
  final String? posReference;
  final String? receiptQrCode;
  final String? receiptQrData;
  final bool? taxInvoice;
  final double? change;
  final double? tipAmount;
  final String? cashierFullName;
  final bool? fiscalized;
  final PaymentType? paymentType;
  final bool? emailReceipt;
  final bool? isWalkInCustomer;
  final String? ticketName;
  final String? ticketComment;
  final double? totalQuantity;
  final String? amtToAcc;
  final String? customerAccBankType;

  // Added for compatibility with existing UI
  double get grandTotal => amountAfterDiscount ?? baseSaleAmount ?? 0.0;

  OnlineSale({
    this.id,
    this.referenceNumber,
    this.customer,
    this.createdByName,
    this.currency,
    this.baseCurrency,
    this.amountAfterDiscount,
    this.balance,
    this.saleCost,
    this.reSaleCost,
    this.paymentStatus,
    this.baseSaleAmount,
    this.timeIniated,
    this.followUpDate,
    this.isDelivered,
    this.items,
    this.paymentTypes,
    this.company,
    this.isProformaInvoice,
    this.status,
    this.orderNumber,
    this.dateCreated,
    this.deliveryDate,
    this.saleStatus,
    this.hasReturns,
    this.isRefunded,
    this.isReversible,
    this.isLessThan12Months,
    this.totalTaxAmount,
    this.standardRatedTotal,
    this.zeroRatedTotal,
    this.amountPaid,
    this.branch,
    this.shiftReference,
    this.posReference,
    this.receiptQrCode,
    this.receiptQrData,
    this.taxInvoice,
    this.change,
    this.tipAmount,
    this.cashierFullName,
    this.fiscalized,
    this.paymentType,
    this.emailReceipt,
    this.isWalkInCustomer,
    this.ticketName,
    this.ticketComment,
    this.totalQuantity,
    this.amtToAcc,
    this.customerAccBankType,
  });

  factory OnlineSale.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return OnlineSale(
      id: json['id']?.toString(),
      referenceNumber: json['referenceNumber']?.toString(),
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      createdByName: json['createdByName']?.toString(),
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      baseCurrency: json['baseCurrency'] != null ? Currency.fromJson(json['baseCurrency']) : null,
      amountAfterDiscount: parseDouble(json['amountAfterDiscount']),
      balance: parseDouble(json['balance']),
      saleCost: parseDouble(json['saleCost']),
      reSaleCost: parseDouble(json['reSaleCost']),
      paymentStatus: json['paymentStatus']?.toString(),
      baseSaleAmount: parseDouble(json['baseSaleAmount']),
      timeIniated: json['timeIniated'] ,
      followUpDate: json['followUpDate'] != null ? DateTime.parse(json['followUpDate']) : null,
      isDelivered: json['isDelivered'],
      items: json['items'] != null && json['items'] is List
          ? (json['items'] as List).map((i) => i != null ? SaleItem.fromJson(i) : null).whereType<SaleItem>().toList()
          : null,
      paymentTypes: json['paymentTypes'] != null && json['paymentTypes'] is List
          ? (json['paymentTypes'] as List).map((i) => i != null ? PaymentReceived.fromJson(i) : null).whereType<PaymentReceived>().toList()
          : null,
      company: json['company'] != null ? Company.fromJson(json['company']) : null,
      isProformaInvoice: json['isProformaInvoice'],
      status: json['status']?.toString(),
      orderNumber: json['orderNumber']?.toString(),
      dateCreated: json['dateCreated'] ,
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
      saleStatus: SaleStatus.fromJson(json['saleStatus']?.toString()),
      hasReturns: json['hasReturns'],
      isRefunded: json['isRefunded'],
      isReversible: json['isReversible'],
      isLessThan12Months: json['isLessThan12Months'],
      totalTaxAmount: parseDouble(json['totalTaxAmount']),
      standardRatedTotal: parseDouble(json['standardRatedTotal']),
      zeroRatedTotal: parseDouble(json['zeroRatedTotal']),
      amountPaid: parseDouble(json['amountPaid']),
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      shiftReference: json['shiftReference']?.toString(),
      posReference: json['posReference']?.toString(),
      receiptQrCode: json['receiptQrCode']?.toString(),
      receiptQrData: json['receiptQrData']?.toString(),
      taxInvoice: json['taxInvoice'],
      change: parseDouble(json['change']),
      tipAmount: parseDouble(json['tipAmount']),
      cashierFullName: json['cashierFullName']?.toString(),
      fiscalized: json['fiscalized'],
      // paymentType: json['paymentType'] != null ? PaymentType.fromJson(json['paymentType']) : null,
      emailReceipt: json['emailReceipt'],
      isWalkInCustomer: json['isWalkInCustomer'],
      ticketName: json['ticketName']?.toString(),
      ticketComment: json['ticketComment']?.toString(),
      totalQuantity: parseDouble(json['totalQuantity']),
      amtToAcc: json['amtToAcc']?.toString(),
      customerAccBankType: json['customerAccBankType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referenceNumber': referenceNumber,
      'customer': customer?.toJson(),
      'createdByName': createdByName,
      'currency': currency?.toJson(),
      'baseCurrency': baseCurrency?.toJson(),
      'amountAfterDiscount': amountAfterDiscount,
      'balance': balance,
      'saleCost': saleCost,
      'reSaleCost': reSaleCost,
      'paymentStatus': paymentStatus,
      'baseSaleAmount': baseSaleAmount,
      'timeIniated': timeIniated,
      'followUpDate': followUpDate?.toIso8601String(),
      'isDelivered': isDelivered,
      'items': items?.map((i) => i.toJson()).toList(),
      'paymentTypes': paymentTypes?.map((i) => i.toJson()).toList(),
      'company': company?.toJson(),
      'isProformaInvoice': isProformaInvoice,
      'status': status,
      'orderNumber': orderNumber,
      'dateCreated': dateCreated,
      'deliveryDate': deliveryDate?.toIso8601String(),
      'saleStatus': saleStatus,
      'hasReturns': hasReturns,
      'isRefunded': isRefunded,
      'isReversible': isReversible,
      'isLessThan12Months': isLessThan12Months,
      'totalTaxAmount': totalTaxAmount,
      'standardRatedTotal': standardRatedTotal,
      'zeroRatedTotal': zeroRatedTotal,
      'amountPaid': amountPaid,
      'branch': branch?.toJson(),
      'shiftReference': shiftReference,
      'posReference': posReference,
      'receiptQrCode': receiptQrCode,
      'receiptQrData': receiptQrData,
      'taxInvoice': taxInvoice,
      'change': change,
      'tipAmount': tipAmount,
      'cashierFullName': cashierFullName,
      'fiscalized': fiscalized,
      'paymentType': paymentType?.toJson(),
      'emailReceipt': emailReceipt,
      'isWalkInCustomer': isWalkInCustomer,
      'ticketName': ticketName,
      'ticketComment': ticketComment,
      'totalQuantity': totalQuantity,
      'amtToAcc': amtToAcc,
      'customerAccBankType': customerAccBankType,
    };
  }
}
