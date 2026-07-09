import 'package:isar/isar.dart';
import 'package:vimbika_pro/model/base_name_entity.dart';
import 'package:vimbika_pro/model/category.dart';
import 'package:vimbika_pro/model/unit.dart';
import 'package:vimbika_pro/model/tax.dart';
import 'package:vimbika_pro/model/currency.dart'; // Import Currency
import 'package:vimbika_pro/model/company.dart'; // Import Company

part 'inventory_item.g.dart';

@collection
class InventoryItem extends BaseNameEntity {
  Id isarId = Isar.autoIncrement;
  final String? itemCode;
  final category = IsarLink<Category>();
  final unit = IsarLink<Unit>();
  final tax = IsarLink<Tax>();
  final currency = IsarLink<Currency>(); // Added currency field
  final double purchasePrice;
  final double sellingPrice;
  final double quantity;
  final double reorderLevel;
  final bool isService;
  final String? imageUrl;
  final String? itemType;
  final String? renewalInterval;
  final company = IsarLink<Company>(); // Added company field
  final bool isSynced; // Added isSynced field

  InventoryItem({
    super.id,
    super.dateCreated,
    super.dateModified,
    super.createdByName,
    super.modifiedByName,
    super.version,
    required super.name,
    super.description,
    this.itemCode,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.quantity = 0.0,
    this.reorderLevel = 0.0,
    this.isService = false,
    this.imageUrl,
    this.itemType,
    this.isSynced = false, // Default to false
    this.renewalInterval,
    Category? category,
    Unit? unit,
    Tax? tax,
  }) {
    if (category != null) {
      this.category.value = category;
    }
    if (unit != null) {
      this.unit.value = unit;
    }
    if (tax != null) {
      this.tax.value = tax;
    }
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final inventoryItem = InventoryItem(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated']?.toString(),
      dateModified: json['dateModified']?.toString(),
      createdByName: json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName']?.toString(),
      version: json['version'] is int ? json['version'] : (json['version'] is num ? (json['version'] as num).toInt() : null),
      name: json['name']?.toString() ?? 'Unknown Item',
      description: json['description']?.toString(),
      itemCode: json['itemCode']?.toString(),
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0.0,
      isService: json['isService'] as bool? ?? false,
      imageUrl: json['imageUrl']?.toString(),
      itemType: json['itemType']?.toString(),
      isSynced: json['isSynced'] as bool? ?? false, // Parse isSynced
      renewalInterval: json['renewalInterval']?.toString(),
    );

    if (json['category'] != null && json['category'] is Map<String, dynamic>) {
      inventoryItem.category.value = Category.fromJson(json['category']);
    }
    if (json['unit'] != null && json['unit'] is Map<String, dynamic>) {
      inventoryItem.unit.value = Unit.fromJson(json['unit']);
    }
    if (json['tax'] != null && json['tax'] is Map<String, dynamic>) {
      inventoryItem.tax.value = Tax.fromJson(json['tax']);
    }
    if (json['currency'] != null && json['currency'] is Map<String, dynamic>) {
      inventoryItem.currency.value = Currency.fromJson(json['currency']);
    }
    if (json['company'] != null && json['company'] is Map<String, dynamic>) {
      inventoryItem.company.value = Company.fromJson(json['company']);
    }

    return inventoryItem;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateCreated': dateCreated,
      'dateModified': dateModified,
      'createdByName': createdByName,
      'modifiedByName': modifiedByName,
      'version': version,
      'name': name,
      'description': description,
      'itemCode': itemCode,
      'category': category.value?.toJson(),
      'unit': unit.value?.toJson(),
      'tax': tax.value?.toJson(),
      'currency': currency.value?.toJson(),
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'reorderLevel': reorderLevel,
      'isService': isService,
      'imageUrl': imageUrl,
      'itemType': itemType,
      'company': company.value?.toJson(),
      'isSynced': isSynced, // Include isSynced in toJson
      'renewalInterval': renewalInterval,
    };
  }

  InventoryItem copyWith({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    String? name,
    String? description,
    String? itemCode,
    double? purchasePrice,
    double? sellingPrice,
    double? quantity,
    double? reorderLevel,
    bool? isService,
    String? imageUrl,
    String? itemType,
    bool? isSynced,
    String? renewalInterval,
    Category? category,
    Unit? unit,
    Tax? tax,
    Currency? currency,
    Company? company,
  }) {
    final newItem = InventoryItem(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      name: name ?? this.name,
      description: description ?? this.description,
      itemCode: itemCode ?? this.itemCode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      isService: isService ?? this.isService,
      imageUrl: imageUrl ?? this.imageUrl,
      itemType: itemType ?? this.itemType,
      isSynced: isSynced ?? this.isSynced,
      renewalInterval: renewalInterval ?? this.renewalInterval,
    );

    newItem.category.value = category ?? this.category.value;
    newItem.unit.value = unit ?? this.unit.value;
    newItem.tax.value = tax ?? this.tax.value;
    newItem.currency.value = currency ?? this.currency.value;
    newItem.company.value = company ?? this.company.value;

    return newItem;
  }
}
