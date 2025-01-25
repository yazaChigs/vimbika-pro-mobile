import 'dart:convert';

import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';



class DynamicQueryModel {
  DynamicQueryModel({
    this.branch
  });

  BranchModel? branch;

  factory DynamicQueryModel.fromJson(String str) => DynamicQueryModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory DynamicQueryModel.fromMap(Map<String, dynamic> json) => DynamicQueryModel(
    branch: BranchModel.fromMap(json["branch"]),
  );

  Map<String, dynamic> toMap() => {
    "branch": branch!.toMap(),
  };
}