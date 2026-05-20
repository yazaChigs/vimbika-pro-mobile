import 'base_name_entity.dart';

class Tax extends BaseNameEntity {
  final double taxPercentage;

  Tax({
    String? id,
    String? dateCreated, // Changed to String?
    String? dateModified, // Changed to String?
    String? createdByName,
    String? modifiedByName,
    int? version,
    required String name,
    String? description,
    required this.taxPercentage,
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
          name: name,
          description: description,
        );

  factory Tax.fromJson(Map<String, dynamic> json) {
    return Tax(
      id: json['id'],
      dateCreated: json['dateCreated'], // Pass directly as String?
      dateModified: json['dateModified'], // Pass directly as String?
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      name: json['name'] ?? 'Unknown Tax',
      description: json['description'],
      taxPercentage: json['taxPercentage']  ?? 0.0,
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
      'name': name,
      'description': description,
      'taxPercentage': taxPercentage,
    };
  }
}
