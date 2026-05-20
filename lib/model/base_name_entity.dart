import 'base_entity.dart';

abstract class BaseNameEntity extends BaseEntity {
  final String name;
  final String? description;

  BaseNameEntity({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    required this.name,
    this.description,
  }) : super(
          id: id,
          dateCreated: dateCreated,
          dateModified: dateModified,
          createdByName: createdByName,
          modifiedByName: modifiedByName,
          version: version,
        );
}
