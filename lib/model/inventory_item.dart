import 'base_name_entity.dart';
import 'category.dart';
import 'unit.dart';
import 'tax.dart';
import 'currency.dart'; // Import Currency
import 'company.dart'; // Import Company

class InventoryItem extends BaseNameEntity {
  final String? itemCode;
  final Category? category;
  final Unit? unit;
  final Tax? tax;
  final Currency? currency; // Added currency field
  final double purchasePrice;
  final double sellingPrice;
  final double quantity;
  final double reorderLevel;
  final bool isService;
  final String? imageUrl;
  final String? itemType;
  final String? renewalInterval;
  final Company? company; // Added company field
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
    this.category,
    this.unit,
    this.tax,
    this.currency,
    this.purchasePrice = 0.0,
    this.sellingPrice = 0.0,
    this.quantity = 0.0,
    this.reorderLevel = 0.0,
    this.isService = false,
    this.imageUrl,
    this.itemType,
    this.company,
    this.isSynced = false, // Default to false
    this.renewalInterval,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'] ,
      dateModified: json['dateModified'] ,
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'] ,
      name: json['name']?.toString() ?? 'Unknown Item',
      description: json['description']?.toString(),
      itemCode: json['itemCode']?.toString(),
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
      tax: json['tax'] != null ? Tax.fromJson(json['tax']) : null,
      currency: json['currency'] != null ? Currency.fromJson(json['currency']) : null,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0.0,
      isService: json['isService'] as bool? ?? false,
      imageUrl: json['imageUrl'],
      itemType: json['itemType'],
      company: json['company'] != null ? Company.fromJson(json['company']) : null,
      isSynced: json['isSynced'] as bool? ?? false, // Parse isSynced
      renewalInterval: json['renewalInterval'],
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
      'category': category?.toJson(),
      'unit': unit?.toJson(),
      'tax': tax?.toJson(),
      'currency': currency?.toJson(),
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'reorderLevel': reorderLevel,
      'isService': isService,
      'imageUrl': imageUrl,
      'itemType': itemType,
      'company': company?.toJson(),
      'isSynced': isSynced, // Include isSynced in toJson
      'renewalInterval': renewalInterval,
    };
  }

  // Add copyWith method
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
    Category? category,
    Unit? unit,
    Tax? tax,
    Currency? currency,
    double? sellingPrice,
    double? quantity,
    double? purchasePrice,
    double? reorderLevel,
    bool? isService,
    String? imageUrl,
    String? itemType,
    Company? company,
    bool? isSynced,
    String? renewalInterval,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      createdByName: createdByName ?? this.createdByName,
      modifiedByName: modifiedByName ?? this.modifiedByName,
      version: version ?? this.version,
      name: name ?? this.name,
      description: description ?? this.description,
      itemCode: itemCode ?? this.itemCode,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      tax: tax ?? this.tax,
      currency: currency ?? this.currency,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      isService: isService ?? this.isService,
      imageUrl: imageUrl ?? this.imageUrl,
      itemType: itemType ?? this.itemType,
      company: company ?? this.company,
      isSynced: isSynced ?? this.isSynced,
      renewalInterval: renewalInterval ?? this.renewalInterval,
    );
  }
}
