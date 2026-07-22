import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vimbika_pro/model/inventory_item.dart';

part 'sale_item.g.dart';

@collection
class SaleItem {
  @JsonKey(includeFromJson: false, includeToJson: false)
  Id isarId = Isar.autoIncrement;
  String? id;
  final inventoryItem = IsarLink<InventoryItem>();
  double quantity;
  double sellingPrice;
  double discountAmount;
  double total;
  double taxAmount;
  bool isMobile;
  double? amountTendered;
  String? notes;

  SaleItem({
    this.id,
    // InventoryItem? inventoryItem,
    this.quantity = 0.0,
    this.sellingPrice = 0.0,
    this.discountAmount = 0.0,
    this.total = 0.0,
    this.taxAmount = 0.0,
    this.isMobile = false,
    this.amountTendered,
    this.notes,
  }) {
    // if (inventoryItem != null) {
    //   this.inventoryItem.value = inventoryItem;
    // }
  }

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    double quantity = (json['quantity'] as num?)?.toDouble() ?? 0.0;
    double sellingPrice = (json['sellingPrice'] as num?)?.toDouble() ?? 0.0;
    double discountAmount = (json['discountAmount'] as num?)?.toDouble() ?? 0.0;
    double taxAmount = (json['taxAmount'] as num?)?.toDouble() ?? 0.0;
    double total = (json['total'] as num?)?.toDouble() ?? (quantity * sellingPrice - discountAmount);

    final item = SaleItem(
      id: json['id']?.toString(),
      quantity: quantity,
      sellingPrice: sellingPrice,
      discountAmount: discountAmount,
      total: total,
      taxAmount: taxAmount,
      isMobile: json['isMobile'] ?? false,
      amountTendered: (json['amountTendered'] as num?)?.toDouble(),
      notes: json['notes']?.toString(),
    );
    if (json['inventoryItem'] != null) {
      item.inventoryItem.value = InventoryItem.fromJson(json['inventoryItem']);
    }
    return item;
  }

  Map<String, dynamic> toJson({int? index}) {
    if (inventoryItem.isAttached) {
      inventoryItem.loadSync();
    }
    return {
      'id': id ?? (index??0).toString(),
      'quantity': quantity,
      'sellingPrice': sellingPrice,
      'discountAmount': discountAmount,
      'total': total,
      'taxAmount': taxAmount,
      'isMobile': isMobile,
      'amountTendered': amountTendered,
      'notes': notes,
      'inventoryItem': inventoryItem.value?.toJson(),
    };
  }

  SaleItem copyWith({
    String? id,
    InventoryItem? inventoryItem,
    double? quantity,
    double? sellingPrice,
    double? discountAmount,
    double? total,
    double? taxAmount,
    bool? isMobile,
    double? amountTendered,
    String? notes,
  }) {
    final newItem = SaleItem(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      taxAmount: taxAmount ?? this.taxAmount,
      isMobile: isMobile ?? this.isMobile,
      amountTendered: amountTendered ?? this.amountTendered,
      notes: notes ?? this.notes,
    );
    newItem.inventoryItem.value = inventoryItem ?? this.inventoryItem.value;
    newItem.isarId = isarId;
    return newItem;
  }
}
