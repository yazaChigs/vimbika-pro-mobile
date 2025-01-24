
import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';

class SaleInfoModel {
  SaleInfoModel({
    required this.sale,
    required this.syncStatus,
  });

  SaleModel? sale;
  bool? syncStatus = false;
  factory SaleInfoModel.fromMap(Map<String, dynamic> json) => SaleInfoModel(
    syncStatus: json["syncStatus"],
    sale: json["sale"] != null ? SaleModel.fromMap(json["sale"]) : null,
  );
  Map<String, dynamic> toMap() => {
    "syncStatus": syncStatus,
    "sale": sale!.toMap(),
  };

}