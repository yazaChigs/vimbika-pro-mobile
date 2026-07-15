import 'package:isar/isar.dart';
import 'package:vimbika_pro/model/base_name_entity.dart';
import 'package:vimbika_pro/model/category.dart';
import 'package:vimbika_pro/model/item_type.dart';
import 'package:vimbika_pro/model/unit.dart';
import 'package:vimbika_pro/model/tax.dart';
import 'package:vimbika_pro/model/supplier.dart';
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
  final purchaseTax = IsarLink<Tax>();
  final supplier = IsarLink<Supplier>();
  final currency = IsarLink<Currency>(); // Added currency field
  final double purchasePrice;
  final double sellingPrice;
  final double priceWithoutTax;
  final double taxAmount;
  final double availableItems;
  final double reorderLevel;
  final bool isService;
  final String? imageUrl;
  @Enumerated(EnumType.name)
  final ItemType? itemType;
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
    this.priceWithoutTax = 0.0,
    this.taxAmount = 0.0,
    this.availableItems = 0.0,
    this.reorderLevel = 0.0,
    this.isService = false,
    this.imageUrl,
    this.itemType,
    this.isSynced = false, // Default to false
    this.renewalInterval,
    Category? category,
    Unit? unit,
    Tax? tax,
    Tax? purchaseTax,
    Supplier? supplier,
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
    if (purchaseTax != null) {
      this.purchaseTax.value = purchaseTax;
    }
    if (supplier != null) {
      this.supplier.value = supplier;
    }
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated']?.toString(),
      dateModified: json['dateModified']?.toString(),
      createdByName: json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName']?.toString(),
      version: json['version'] is int
          ? json['version']
          : (json['version'] is num ? (json['version'] as num).toInt() : null),
      name: json['name']?.toString() ?? 'Unknown Item',
      description: json['description']?.toString(),
      itemCode: json['itemCode']?.toString(),
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      priceWithoutTax: (json['priceWithoutTax'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      availableItems: (json['availableItems'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0.0,
      isService: json['isService'] as bool? ?? false,
      imageUrl: json['imageUrl']?.toString(),
      itemType: json['itemType'] != null
          ? ItemType.values.firstWhere(
              (e) => e.toString().split('.').last == json['itemType'],
              orElse: () => ItemType.INVENTORY)
          : ItemType.INVENTORY,
      isSynced: json['isSynced'] as bool? ?? false, // Parse isSynced
      renewalInterval: json['renewalInterval']?.toString(),
      category: json['category'] != null && json['category'] is Map<String, dynamic>
          ? Category.fromJson(json['category'])
          : null,
      unit: json['unit'] != null && json['unit'] is Map<String, dynamic>
          ? Unit.fromJson(json['unit'])
          : null,
      tax: json['tax'] != null && json['tax'] is Map<String, dynamic>
          ? Tax.fromJson(json['tax'])
          : null,
      purchaseTax: json['purchaseTax'] != null && json['purchaseTax'] is Map<String, dynamic>
          ? Tax.fromJson(json['purchaseTax'])
          : null,
      supplier: json['supplier'] != null && json['supplier'] is Map<String, dynamic>
          ? Supplier.fromJson(json['supplier'])
          : null,
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
      'name': name,
      'description': description,
      'itemCode': itemCode,
      'category': category.value?.toJson(),
      'unit': unit.value?.toJson(),
      'tax': tax.value?.toJson(),
      'purchaseTax': purchaseTax.value?.toJson(),
      'supplier': supplier.value?.toJson(),
      'currency': currency.value?.toJson(),
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'priceWithoutTax': priceWithoutTax,
      'taxAmount': taxAmount,
      'availableItems': availableItems,
      'reorderLevel': reorderLevel,
      'isService': isService,
      'imageUrl': imageUrl,
      'itemType': itemType?.toString().split('.').last,
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
    double? priceWithoutTax,
    double? taxAmount,
    double? availableItems,
    double? reorderLevel,
    bool? isService,
    String? imageUrl,
    ItemType? itemType,
    bool? isSynced,
    String? renewalInterval,
    Category? category,
    Unit? unit,
    Tax? tax,
    Tax? purchaseTax,
    Supplier? supplier,
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
      priceWithoutTax: priceWithoutTax ?? this.priceWithoutTax,
      taxAmount: taxAmount ?? this.taxAmount,
      availableItems: availableItems ?? this.availableItems,
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
    newItem.purchaseTax.value = purchaseTax ?? this.purchaseTax.value;
    newItem.supplier.value = supplier ?? this.supplier.value;
    newItem.currency.value = currency ?? this.currency.value;
    newItem.company.value = company ?? this.company.value;

    return newItem;
  }
}
