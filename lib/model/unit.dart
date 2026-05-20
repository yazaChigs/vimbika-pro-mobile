import 'base_name_entity.dart';

class Unit extends BaseNameEntity {
  final String? abbreviation;

  Unit({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    required String name,
    String? description,
    this.abbreviation,
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

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'],
      dateCreated: json['dateCreated'],
      dateModified: json['dateModified'],
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      name: json['name'] ?? '',
      description: json['description'],
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
    };
  }
}
