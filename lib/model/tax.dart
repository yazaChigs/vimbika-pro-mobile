import 'package:isar/isar.dart';
import 'package:vimbika_pro/model/base_name_entity.dart';

part 'tax.g.dart';

@collection
class Tax extends BaseNameEntity {
  Id isarId = Isar.autoIncrement;
  double? taxPercentage;

  Tax({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    required String name,
    String? description,
    this.taxPercentage,
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
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'],
      dateModified: json['dateModified'],
      createdByName: json['createdByName'],
      modifiedByName: json['modifiedByName'],
      version: json['version'],
      name: json['name']?.toString() ?? 'No Name',
      description: json['description'],
      taxPercentage: (json['taxPercentage'] as num?)?.toDouble(),
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
      'taxPercentage': taxPercentage,
    };
  }
}
