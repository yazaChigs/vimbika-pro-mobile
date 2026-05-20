import 'base_entity.dart';
import 'inventory_item.dart';

class SaleItem extends BaseEntity {
  final InventoryItem? inventoryItem;
  final double quantity;
  final double sellingPrice;
  final double taxAmount;
  final double discountAmount;
  final double total;
  bool? isMobile;

  SaleItem({
    super.id,
    super.dateCreated,
    super.dateModified,
    super.createdByName,
    super.modifiedByName,
    super.version,
    this.inventoryItem,
    this.quantity = 0.0,
    this.sellingPrice = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.total = 0.0,
    this.isMobile,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) {

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    
    return SaleItem(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'] ,
      dateModified: json['dateModified'],
      createdByName: json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName']?.toString(),
      version: (json['version'] as num?)?.toInt(),
      inventoryItem: json['inventoryItem'] != null ? InventoryItem.fromJson(json['inventoryItem']) : null,
      quantity: parseDouble(json['quantity'] ) ?? 0.0,
      sellingPrice: parseDouble(json['sellingPrice'])  ?? 0.0,
      taxAmount: parseDouble(json['taxAmount'] ) ?? 0.0,
      discountAmount: parseDouble(json['discountAmount'] ) ?? 0.0,
      total: parseDouble(json['total']) ?? 0.0,
      isMobile: json['isMobile'] ?? false,
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
      'inventoryItem': inventoryItem?.toJson(),
      'quantity': quantity,
      'sellingPrice': sellingPrice,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'total': total,
      'isMobile': isMobile,
    };
  }
}
