import 'base_entity.dart';
import 'supplier.dart';
import 'branch.dart';
import 'currency.dart';
import 'purchase_item.dart';
import 'payment_paid.dart';

class Purchase extends BaseEntity {
  final Supplier? supplier;
  final Branch? branch;
  final Currency? currency;
  final List<PurchaseItem> items;
  final List<PaymentPaid>? payments;
  final double subTotal;
  final double taxTotal;
  final double discountTotal;
  final double grandTotal;
  final DateTime purchaseDate;
  final String? status;
  final String? notes;

  Purchase({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    this.supplier,
    this.branch,
    this.currency,
    required this.items,
    this.payments,
    this.subTotal = 0.0,
    this.taxTotal = 0.0,
    this.discountTotal = 0.0,
    this.grandTotal = 0.0,
    required this.purchaseDate,
    this.status,
    this.notes,
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
        );

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      dateCreated: json['dateCreated'] ,
      dateModified: json['dateModified'] ,
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      supplier: json['supplier'] != null ? Supplier.fromJson(json['supplier']) : null,
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => PurchaseItem.fromJson(i)).toList()
          : [],
      payments: json['payments'] != null
          ? (json['payments'] as List).map((i) => PaymentPaid.fromJson(i)).toList()
          : null,
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0.0,
      taxTotal: (json['taxTotal'] as num?)?.toDouble() ?? 0.0,
      discountTotal: (json['discountTotal'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: json['purchaseDate'] != null ? DateTime.parse(json['purchaseDate']) : DateTime.now(),
      status: json['status'],
      notes: json['notes'],
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
      'supplier': supplier?.toJson(),
      'branch': branch?.toJson(),
      'currency': currency?.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
      'payments': payments?.map((i) => i.toJson()).toList(),
      'subTotal': subTotal,
      'taxTotal': taxTotal,
      'discountTotal': discountTotal,
      'grandTotal': grandTotal,
      'purchaseDate': purchaseDate.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }
}
