import 'base_entity.dart';
import 'inventory_item.dart';

class PurchaseItem extends BaseEntity {
  final InventoryItem? inventoryItem;
  final double quantity;
  final double price;
  final double taxAmount;
  final double discountAmount;
  final double total;

  PurchaseItem({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    this.inventoryItem,
    this.quantity = 0.0,
    this.price = 0.0,
    this.taxAmount = 0.0,
    this.discountAmount = 0.0,
    this.total = 0.0,
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
        );

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'],
      dateCreated: json['dateCreated'],
      dateModified: json['dateModified'] ,
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      inventoryItem: json['inventoryItem'] != null ? InventoryItem.fromJson(json['inventoryItem']) : null,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
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
      'price': price,
      'taxAmount': taxAmount,
      'discountAmount': discountAmount,
      'total': total,
    };
  }
}
