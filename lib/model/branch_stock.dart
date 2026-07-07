import 'package:isar/isar.dart';
import 'base_entity.dart';
import 'branch.dart';
import 'inventory_item.dart';

part 'branch_stock.g.dart';

@collection
class BranchStock extends BaseEntity {
  Id isarId = Isar.autoIncrement;
  final branch = IsarLink<Branch>();
  final item = IsarLink<InventoryItem>();
  final double stock;

  BranchStock({
    String? id,
    String? dateCreated, // Changed to String?
    String? dateModified, // Changed to String?
    String? createdByName,
    String? modifiedByName,
    int? version,
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
    final branchStock = BranchStock(
      id: json['id'],
      dateCreated: json['dateCreated'], // Pass directly as String?
      dateModified: json['dateModified'], // Pass directly as String?
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
    );

    if (json['branch'] != null && json['branch'] is Map<String, dynamic>) {
      branchStock.branch.value = Branch.fromJson(json['branch']);
    }
    if (json['item'] != null && json['item'] is Map<String, dynamic>) {
      branchStock.item.value = InventoryItem.fromJson(json['item']);
    }

    return branchStock;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateCreated': dateCreated, // Return directly as String?
      'dateModified': dateModified, // Return directly as String?
      'createdByName': createdByName,
      'modifiedByName': modifiedByName,
      'version': version,
      'branch': branch.value?.toJson(),
      'item': item.value?.toJson(),
      'stock': stock,
    };
  }

  BranchStock copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    double? stock,
    IsarLink<Branch>? branch,
    IsarLink<InventoryItem>? item,
  }) {
    final newBranchStock = BranchStock(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      stock: stock ?? this.stock,
    );

    newBranchStock.branch.value = branch?.value ?? this.branch.value;
    newBranchStock.item.value = item?.value ?? this.item.value;

    return newBranchStock;
  }
}
