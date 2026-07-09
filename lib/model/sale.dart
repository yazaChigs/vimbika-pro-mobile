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
@JsonSerializable(explicitToJson: true)
class Sale {
  @JsonKey(includeFromJson: false, includeToJson: false)
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

  @JsonKey(toJson: _saleItemsToJson, includeFromJson: false)
  final items = IsarLinks<SaleItem>();

  @ignore
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<SaleItem> itemsList = [];

  @ignore
  List<SaleItem> heldItems;
  @ignore
  Currency? heldCurrency;
  @ignore
  @JsonKey(includeToJson: false)
  Branch? heldBranch;
  @ignore
  Customer? heldCustomer;

  @JsonKey(toJson: _paymentsToJson, includeFromJson: false)
  final paymentTypes = IsarLinks<PaymentReceived>();

  @ignore
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<PaymentReceived> paymentsList = [];
  String? timeIniated;
  String? timeCompleted;
  String? saleStatus;
  final currency = IsarLink<Currency>();
  final baseCurrency = IsarLink<Currency>();
  double? amountAfterDiscount;
  double? baseSaleAmount;
  double? totalTaxAmount;
  bool isSynced;
  bool? fiscalized;
  bool? taxInvoice;
  double? totalQuantity;
  double? totalDiscount;
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
    this.isSynced = false,
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
    this.heldItems = const [],
    this.heldCurrency,
    this.heldBranch,
    this.heldCustomer,
    this.totalDiscount,
  });

  @ignore
  List<SaleItem> get allItems {
    if (itemsList.isNotEmpty) return itemsList;
    if (items.isAttached) {
      items.loadSync();
    }
    return items.toList();
  }

  @ignore
  List<PaymentReceived> get allPaymentTypes {
    if (paymentsList.isNotEmpty) return paymentsList;
    if (paymentTypes.isAttached) {
      paymentTypes.loadSync();
    }
    return paymentTypes.toList();
  }

  @ignore
  double get grandTotal {
    return allItems.fold(0.0, (sum, item) => sum + item.total);
  }
  @ignore
  double get ticketTotal {
    return heldItems.fold(0.00, (sum, item) => sum + item.total);
  }

  void syncListsToLinks() {
    if (itemsList.isNotEmpty) {
      items.clear();
      items.addAll(itemsList);
    }
    if (paymentsList.isNotEmpty) {
      paymentTypes.clear();
      paymentTypes.addAll(paymentsList);
    }
  }

  factory Sale.fromJson(Map<String, dynamic> json) {
    // Ensure string fields are strings to avoid type cast errors during _$SaleFromJson
    final stringFields = [
      'id',
      'dateCreated',
      'dateModified',
      'createdByName',
      'modifiedByName',
      'cashierFullName',
      'timeIniated',
      'timeCompleted',
      'saleStatus',
      'posReference',
      'referenceNumber',
      'shiftReference',
      'ticketName',
      'amtToAcc',
      'customerAccBankType',
      'receiptQrCode',
      'receiptQrData',
    ];
    for (var field in stringFields) {
      if (json[field] != null && json[field] is! String) {
        json[field] = json[field].toString();
      }
    }

    final sale = _$SaleFromJson(json);
    if (json['branch'] != null) {
      sale.branch.value =
          Branch.fromJson(json['branch'] as Map<String, dynamic>);
    }
    if (json['currency'] != null) {
      sale.currency.value =
          Currency.fromJson(json['currency'] as Map<String, dynamic>);
    }
    if (json['baseCurrency'] != null) {
      sale.baseCurrency.value =
          Currency.fromJson(json['baseCurrency'] as Map<String, dynamic>);
    }
    if (json['customer'] != null) {
      sale.customer.value =
          Customer.fromJson(json['customer'] as Map<String, dynamic>);
    }
    if (json['company'] != null) {
      sale.company.value =
          Company.fromJson(json['company'] as Map<String, dynamic>);
    }
    final itemsData = json['items'] ?? json['saleItems'] ?? json['sale_items'] ?? json['saleItemsList'];
    if (itemsData != null && itemsData is List) {
      final items = itemsData
          .where((i) => i != null && i is Map<String, dynamic>)
          .map((i) => SaleItem.fromJson(i as Map<String, dynamic>))
          .toList();
      sale.itemsList = items;
      sale.items.clear();
      sale.items.addAll(items);
    }
    final paymentsData = json['paymentTypes'] ??
        json['payments'] ??
        json['payment_types'] ??
        json['salePayments'] ??
        json['sale_payments'] ??
        json['paymentReceiveds'] ??
        json['payment_receiveds'] ??
        json['sale_payment_receiveds'];
    if (paymentsData != null && paymentsData is List) {
      final payments = paymentsData
          .where((p) => p != null && p is Map<String, dynamic>)
          .map((p) => PaymentReceived.fromJson(p as Map<String, dynamic>))
          .toList();
      sale.paymentsList = payments;
      sale.paymentTypes.clear();
      sale.paymentTypes.addAll(payments);
    }
    return sale;
  }

  Map<String, dynamic> toJson() {
    final json = _$SaleToJson(this);
    if (branch.isAttached) {
      branch.loadSync();
    }
    json['branch'] = branch.value?.toJson();

    if (currency.isAttached) {
      currency.loadSync();
    }
    json['currency'] = currency.value?.toJson();

    if (baseCurrency.isAttached) {
      baseCurrency.loadSync();
    }
    json['baseCurrency'] = baseCurrency.value?.toJson();

    json['items'] = allItems.map((item) => item.toJson()).toList();

    if (customer.isAttached) {
      customer.loadSync();
    }
    json['customer'] = customer.value?.toJson();
    json['paymentTypes'] = allPaymentTypes.map((p) => p.toJson()).toList();

    return json;
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
    List<SaleItem>? heldItems,
    Currency? heldCurrency,
    Branch? heldBranch,
    Customer? heldCustomer,
    List<SaleItem>? items,
    IsarLinks<PaymentReceived>? paymentTypes,
    double? totalDiscount,
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
      heldItems: heldItems ?? this.heldItems,
      heldCurrency: heldCurrency ?? this.heldCurrency,
      heldBranch: heldBranch ?? this.heldBranch,
      heldCustomer: heldCustomer ?? this.heldCustomer,
      totalDiscount: totalDiscount ?? this.totalDiscount,
    );

    newSale.isarId = isarId ?? this.isarId;
    newSale.customer.value = customer.value;
    newSale.company.value = company.value;
    newSale.branch.value = branch.value;
    if (items != null) {
      newSale.itemsList = items;
      newSale.items.addAll(items);
    } else {
      newSale.itemsList = List.from(allItems);
      newSale.items.addAll(allItems);
    }
    if (paymentTypes != null) {
      newSale.paymentTypes.addAll(paymentTypes);
      newSale.paymentsList = paymentTypes.toList();
    } else {
      newSale.paymentTypes.addAll(allPaymentTypes);
      newSale.paymentsList = List.from(allPaymentTypes);
    }
    newSale.currency.value = currency.value;
    newSale.baseCurrency.value = baseCurrency.value;

    return newSale;
  }
}

// Custom converter functions
IsarLinks<SaleItem> _saleItemsFromJson(List<dynamic>? json) {
  final links = IsarLinks<SaleItem>();
  if (json != null) {
    final items =
        json.map((i) => SaleItem.fromJson(i as Map<String, dynamic>)).toList();
    links.addAll(items);
  }
  return links;
}

List<Map<String, dynamic>> _saleItemsToJson(IsarLinks<SaleItem> items) {
  if (items.isAttached) {
    items.loadSync();
  }
  return items.map((i) => i.toJson()).toList();
}

List<Map<String, dynamic>> _paymentsToJson(IsarLinks<PaymentReceived> payments) {
  if (payments.isAttached) {
    payments.loadSync();
  }
  return payments.map((p) => p.toJson()).toList();
}

IsarLinks<PaymentReceived> _paymentsFromJson(List<dynamic> json) {
  final links = IsarLinks<PaymentReceived>();
  final payments = json
      .map((p) => PaymentReceived.fromJson(p as Map<String, dynamic>))
      .toList();
  links.addAll(payments);
  return links;
}
