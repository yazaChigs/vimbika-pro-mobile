import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vimbika_pro/model/inventory_item.dart';

part 'sale_item.g.dart';

@collection
class SaleItem {
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

  SaleItem({
    this.id,
    InventoryItem? inventoryItem,
    this.quantity = 0.0,
    this.sellingPrice = 0.0,
    this.discountAmount = 0.0,
    this.total = 0.0,
    this.taxAmount = 0.0,
    this.isMobile = false,
    this.amountTendered,
  }) {
    if (inventoryItem != null) {
      this.inventoryItem.value = inventoryItem;
    }
  }

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    final item = SaleItem(
      id: json['id'],
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      isMobile: json['isMobile'] ?? false,
      amountTendered: (json['amountTendered'] as num?)?.toDouble(),
    );
    if (json['inventoryItem'] != null) {
      item.inventoryItem.value = InventoryItem.fromJson(json['inventoryItem']);
    }
    return item;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantity': quantity,
      'sellingPrice': sellingPrice,
      'discountAmount': discountAmount,
      'total': total,
      'taxAmount': taxAmount,
      'isMobile': isMobile,
      'amountTendered': amountTendered,
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
    );
    newItem.inventoryItem.value = inventoryItem ?? this.inventoryItem.value;
    return newItem;
  }
}
