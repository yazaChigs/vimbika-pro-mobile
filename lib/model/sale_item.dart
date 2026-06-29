import 'package:vimbika_pro/model/inventory_item.dart';

class SaleItem {
  String? id;
  InventoryItem? inventoryItem;
  double quantity;
  double sellingPrice;
  double discountAmount;
  double total;
  double taxAmount;
  bool isMobile;
  double? amountTendered;

  SaleItem({
    this.id,
    this.inventoryItem,
    required this.quantity,
    required this.sellingPrice,
    this.discountAmount = 0.0,
    required this.total,
    required this.taxAmount,
    this.isMobile = false,
    this.amountTendered,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'],
      inventoryItem: json['inventoryItem'] != null ? InventoryItem.fromJson(json['inventoryItem']) : null,
      quantity: (json['quantity'] as num).toDouble(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num).toDouble(),
      taxAmount: (json['taxAmount'] as num).toDouble(),
      isMobile: json['isMobile'] ?? false,
      amountTendered: (json['amountTendered'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventoryItem': inventoryItem?.toJson(),
      'quantity': quantity,
      'sellingPrice': sellingPrice,
      'discountAmount': discountAmount,
      'total': total,
      'taxAmount': taxAmount,
      'isMobile': isMobile,
      'amountTendered': amountTendered,
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
    return SaleItem(
      id: id ?? this.id,
      inventoryItem: inventoryItem ?? this.inventoryItem,
      quantity: quantity ?? this.quantity,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      total: total ?? this.total,
      taxAmount: taxAmount ?? this.taxAmount,
      isMobile: isMobile ?? this.isMobile,
      amountTendered: amountTendered ?? this.amountTendered,
    );
  }
}