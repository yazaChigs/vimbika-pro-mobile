import 'base_entity.dart';
import 'customer.dart';
import 'branch.dart';
import 'currency.dart';
import 'sale_item.dart';
import 'payment_received.dart';
import 'online_sale.dart'; // Import OnlineSale
import 'company.dart'; // Import Company
import 'payment_type.dart'; // Import PaymentType

class Sale extends BaseEntity {
  final String? referenceNumber;
  final Customer? customer;
  final Branch? branch;
  final Currency? currency;
  final Currency? baseCurrency;
  final List<SaleItem> items;
  final List<PaymentReceived>? paymentTypes;
  final String timeIniated;
  final String? status; // This maps to OnlineSale.status
  final String? notes;
  final bool? isSynced;
  final double? amountAfterDiscount;
  final double? baseSaleAmount;
  final double? balance;
  final double? saleCost;
  final double? reSaleCost;
  final String? paymentStatus;
  final DateTime? followUpDate;
  final bool? isDelivered;
  final Company? company;
  final bool? isProformaInvoice;
  final String? orderNumber;
  final DateTime? deliveryDate;
  final String? saleStatus; // This maps to OnlineSale.saleStatus
  final bool? hasReturns;
  final bool? isRefunded;
  final bool? isReversible;
  final bool? isLessThan12Months;
  final double? totalTaxAmount;
  final double? standardRatedTotal;
  final double? zeroRatedTotal;
  final double? amountPaid;
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
  final String? totalQuantity;


  // Added for compatibility with existing UI
  double get grandTotal => amountAfterDiscount ?? baseSaleAmount ?? 0.0;


  Sale({
    super.id,
    super.dateCreated,
    super.dateModified,
    super.createdByName,
    super.modifiedByName,
    super.version,
    this.referenceNumber,
    this.customer,
    this.branch,
    this.currency,
    this.baseCurrency,
    required this.items,
    this.paymentTypes,
    required this.timeIniated,
    this.status,
    this.notes,
    this.isSynced,
    this.amountAfterDiscount,
    this.baseSaleAmount,
    this.balance,
    this.saleCost,
    this.reSaleCost,
    this.paymentStatus,
    this.followUpDate,
    this.isDelivered,
    this.company,
    this.isProformaInvoice,
    this.orderNumber,
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
    this.totalQuantity
  });

  Sale copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? referenceNumber,
    Customer? customer,
    Branch? branch,
    Currency? currency,
    Currency? baseCurrency,
    List<SaleItem>? items,
    List<PaymentReceived>? paymentTypes,
    String? timeIniated,
    String? status,
    String? notes,
    bool? isSynced,
    double? amountAfterDiscount,
    double? baseSaleAmount,
    double? balance,
    double? saleCost,
    double? reSaleCost,
    String? paymentStatus,
    DateTime? followUpDate,
    bool? isDelivered,
    Company? company,
    bool? isProformaInvoice,
    String? orderNumber,
    DateTime? deliveryDate,
    String? saleStatus,
    bool? hasReturns,
    bool? isRefunded,
    bool? isReversible,
    bool? isLessThan12Months,
    double? totalTaxAmount,
    double? standardRatedTotal,
    double? zeroRatedTotal,
    double? amountPaid,
    String? shiftReference,
    String? posReference,
    String? receiptQrCode,
    String? receiptQrData,
    bool? taxInvoice,
    double? change,
    double? tipAmount,
    String? cashierFullName,
    bool? fiscalized,
    PaymentType? paymentType,
    bool? emailReceipt,
    bool? isWalkInCustomer,
    String? ticketName,
    String? ticketComment,
    String? totalQuantity,
  }) {
    return Sale(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      customer: customer ?? this.customer,
      branch: branch ?? this.branch,
      currency: currency ?? this.currency,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      items: items ?? this.items,
      paymentTypes: paymentTypes ?? this.paymentTypes,
      timeIniated: timeIniated ?? this.timeIniated,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      amountAfterDiscount: amountAfterDiscount ?? this.amountAfterDiscount,
      baseSaleAmount: baseSaleAmount ?? this.baseSaleAmount,
      balance: balance ?? this.balance,
      saleCost: saleCost ?? this.saleCost,
      reSaleCost: reSaleCost ?? this.reSaleCost,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      followUpDate: followUpDate ?? this.followUpDate,
      isDelivered: isDelivered ?? this.isDelivered,
      company: company ?? this.company,
      isProformaInvoice: isProformaInvoice ?? this.isProformaInvoice,
      orderNumber: orderNumber ?? this.orderNumber,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      saleStatus: saleStatus ?? this.saleStatus,
      hasReturns: hasReturns ?? this.hasReturns,
      isRefunded: isRefunded ?? this.isRefunded,
      isReversible: isReversible ?? this.isReversible,
      isLessThan12Months: isLessThan12Months ?? this.isLessThan12Months,
      totalTaxAmount: totalTaxAmount ?? this.totalTaxAmount,
      standardRatedTotal: standardRatedTotal ?? this.standardRatedTotal,
      zeroRatedTotal: zeroRatedTotal ?? this.zeroRatedTotal,
      amountPaid: amountPaid ?? this.amountPaid,
      shiftReference: shiftReference ?? this.shiftReference,
      posReference: posReference ?? this.posReference,
      receiptQrCode: receiptQrCode ?? this.receiptQrCode,
      receiptQrData: receiptQrData ?? this.receiptQrData,
      taxInvoice: taxInvoice ?? this.taxInvoice,
      change: change ?? this.change,
      tipAmount: tipAmount ?? this.tipAmount,
      cashierFullName: cashierFullName ?? this.cashierFullName,
      fiscalized: fiscalized ?? this.fiscalized,
      paymentType: paymentType ?? this.paymentType,
      emailReceipt: emailReceipt ?? this.emailReceipt,
      isWalkInCustomer: isWalkInCustomer ?? this.isWalkInCustomer,
      ticketName: ticketName ?? this.ticketName,
      ticketComment: ticketComment ?? this.ticketComment,
      totalQuantity: totalQuantity ?? this.totalQuantity,
    );
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Sale(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated']?.toString(), // Pass directly as String?
      dateModified: json['dateModified']?.toString(), // Pass directly as String?
      createdByName: json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName']?.toString(),
      version: (json['version'] as num?)?.toInt(),
      referenceNumber: json['referenceNumber']?.toString(),
      customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      baseCurrency: json['baseCurrency'] != null ? Currency.fromJson(json['baseCurrency']) : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => SaleItem.fromJson(i)).toList()
          : [],
      paymentTypes: json['paymentTypes'] != null
          ? (json['paymentTypes'] as List).map((i) => PaymentReceived.fromJson(i)).toList()
          : null,
      timeIniated: json['timeIniated'].toString(),
      status: json['status']?.toString(),
      notes: json['notes']?.toString(),
      isSynced: json['isSynced'] as bool?,
      amountAfterDiscount: parseDouble(json['amountAfterDiscount']),
      baseSaleAmount: parseDouble(json['baseSaleAmount']),
      balance: parseDouble(json['balance']),
      saleCost: parseDouble(json['saleCost']),
      reSaleCost: parseDouble(json['reSaleCost']),
      paymentStatus: json['paymentStatus']?.toString(),
      followUpDate: json['followUpDate'] != null ? DateTime.parse(json['followUpDate']) : null,
      isDelivered: json['isDelivered'] as bool?,
      company: json['company'] != null ? Company.fromJson(json['company']) : null,
      isProformaInvoice: json['isProformaInvoice'] as bool?,
      orderNumber: json['orderNumber']?.toString(),
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
      saleStatus: json['saleStatus']?.toString(),
      hasReturns: json['hasReturns'] as bool?,
      isRefunded: json['isRefunded'] as bool?,
      isReversible: json['isReversible'] as bool?,
      isLessThan12Months: json['isLessThan12Months'] as bool?,
      totalTaxAmount: parseDouble(json['totalTaxAmount']),
      standardRatedTotal: parseDouble(json['standardRatedTotal']),
      zeroRatedTotal: parseDouble(json['zeroRatedTotal']),
      amountPaid: parseDouble(json['amountPaid']),
      shiftReference: json['shiftReference']?.toString(),
      posReference: json['posReference']?.toString(),
      receiptQrCode: json['receiptQrCode']?.toString(),
      receiptQrData: json['receiptQrData']?.toString(),
      taxInvoice: json['taxInvoice'] as bool?,
      change: parseDouble(json['change']),
      tipAmount: parseDouble(json['tipAmount']),
      cashierFullName: json['cashierFullName']?.toString(),
      fiscalized: json['fiscalized'] as bool?,
      paymentType: json['paymentType'] != null ? PaymentType.fromJson(json['paymentType']) : null,
      emailReceipt: json['emailReceipt'] as bool?,
      isWalkInCustomer: json['isWalkInCustomer'] as bool?,
      ticketName: json['ticketName']?.toString(),
      ticketComment: json['ticketComment']?.toString(),
      totalQuantity: json['totalQuantity']?.toString(),
    );
  }

  factory Sale.fromOnlineSale(OnlineSale onlineSale) {
    final double subTotal = onlineSale.baseSaleAmount ?? 0.0;
    final double amountAfterDiscount = (onlineSale.amountAfterDiscount == null || onlineSale.amountAfterDiscount == 0.0)
        ? subTotal
        : onlineSale.amountAfterDiscount!;
    final double discountTotal = subTotal - amountAfterDiscount;
    final double taxTotal = onlineSale.totalTaxAmount ?? 0.0;
    final double grandTotal = amountAfterDiscount + taxTotal;

    return Sale(
      id: onlineSale.id,
      dateCreated: onlineSale.dateCreated,
      createdByName: onlineSale.createdByName,
      customer: onlineSale.customer,
      branch: onlineSale.branch,
      currency: onlineSale.currency,
      items: onlineSale.items ?? [],
      paymentTypes: onlineSale.paymentTypes,
      timeIniated: onlineSale.timeIniated!,
      status: onlineSale.status,
      isSynced: true,
      referenceNumber: onlineSale.referenceNumber,
      baseCurrency: onlineSale.baseCurrency,
      amountAfterDiscount: onlineSale.amountAfterDiscount,
      baseSaleAmount: onlineSale.baseSaleAmount,
      balance: onlineSale.balance,
      saleCost: onlineSale.saleCost,
      reSaleCost: onlineSale.reSaleCost,
      paymentStatus: onlineSale.paymentStatus,
      followUpDate: onlineSale.followUpDate,
      isDelivered: onlineSale.isDelivered,
      company: onlineSale.company,
      isProformaInvoice: onlineSale.isProformaInvoice,
      orderNumber: onlineSale.orderNumber,
      deliveryDate: onlineSale.deliveryDate,
      saleStatus: onlineSale.saleStatus,
      hasReturns: onlineSale.hasReturns,
      isRefunded: onlineSale.isRefunded,
      isReversible: onlineSale.isReversible,
      isLessThan12Months: onlineSale.isLessThan12Months,
      totalTaxAmount: onlineSale.totalTaxAmount,
      standardRatedTotal: onlineSale.standardRatedTotal,
      zeroRatedTotal: onlineSale.zeroRatedTotal,
      amountPaid: onlineSale.amountPaid,
      shiftReference: onlineSale.shiftReference,
      posReference: onlineSale.posReference,
      receiptQrCode: onlineSale.receiptQrCode,
      receiptQrData: onlineSale.receiptQrData,
      taxInvoice: onlineSale.taxInvoice,
      change: onlineSale.change,
      tipAmount: onlineSale.tipAmount,
      cashierFullName: onlineSale.cashierFullName,
      fiscalized: onlineSale.fiscalized,
      paymentType: onlineSale.paymentType,
      emailReceipt: onlineSale.emailReceipt,
      isWalkInCustomer: onlineSale.isWalkInCustomer,
      ticketName: onlineSale.ticketName,
      ticketComment: onlineSale.ticketComment,
      totalQuantity: onlineSale.totalQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateCreated': dateCreated, // Return directly as String?
      'dateModified': dateModified, // Return directly as String?
      'createdByName': createdByName,
      'modifiedByName': modifiedByName,
      'version': version,
      'referenceNumber': referenceNumber,
      'customer': customer?.toJson(),
      'branch': branch?.toJson(),
      'currency': currency?.toJson(),
      'baseCurrency': baseCurrency?.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
      'paymentTypes': paymentTypes?.map((i) => i.toJson()).toList(),
      'timeIniated': timeIniated,
      'status': status,
      'notes': notes,
      'isSynced': isSynced,
      'amountAfterDiscount': amountAfterDiscount,
      'baseSaleAmount': baseSaleAmount,
      'balance': balance,
      'saleCost': saleCost,
      'reSaleCost': reSaleCost,
      'paymentStatus': paymentStatus,
      'followUpDate': followUpDate?.toIso8601String(),
      'isDelivered': isDelivered,
      'company': company?.toJson(),
      'isProformaInvoice': isProformaInvoice,
      'orderNumber': orderNumber,
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
    };
  }
}
