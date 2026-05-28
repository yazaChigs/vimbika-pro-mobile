import 'base_entity.dart';
import 'branch.dart';
import 'inventory_item.dart';

class BranchStock extends BaseEntity {
  final Branch? branch;
  final InventoryItem? item;
  final double stock;

  BranchStock({
    String? id,
    String? dateCreated, // Changed to String?
    String? dateModified, // Changed to String?
    String? createdByName,
    String? modifiedByName,
    int? version,
    this.branch,
    this.item,
    this.stock = 0.0,
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
        );

  factory BranchStock.fromJson(Map<String, dynamic> json) {
    return BranchStock(
      id: json['id'],
      dateCreated: json['dateCreated'], // Pass directly as String?
      dateModified: json['dateModified'], // Pass directly as String?
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      branch: json['branch'] != null ? Branch.fromJson(json['branch']) : null,
      item: json['item'] != null ? InventoryItem.fromJson(json['item']) : null,
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
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
      'branch': branch?.toJson(),
      'item': item?.toJson(),
      'stock': stock,
    };
  }
}
