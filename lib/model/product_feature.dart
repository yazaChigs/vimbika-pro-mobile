import 'base_name_entity.dart';
import 'company.dart';

class ProductFeature extends BaseNameEntity {
  bool? useProductBrands;
  bool? specifyProductDepartment;
  bool? showPricingExcludingTax;
  bool? enableDiscounts;
  bool? enableLoyalCustomer;
  bool? useProduction;
  bool? sellNilItems;
  bool? showPriceOnDelivery;
  bool? showBrands;
  bool? autoDeliver;
  bool? saleOnConsignment;
  bool? useSerialNumbers;
  bool? showAmountBeforeTax;
  bool? enableWaInvReq;
  String? whatsappNumber;
  double? pointsThreshold;
  double? pointsRate;
  bool? enablePromotions;
  bool? submitPreviousYearInvoices;
  Company? company;

  ProductFeature({
    String? id,
    String? dateCreated,
    String? dateModified,
    String? createdByName,
    String? modifiedByName,
    int? version,
    required String name,
    String? description,
    this.useProductBrands,
    this.specifyProductDepartment,
    this.showPricingExcludingTax,
    this.enableDiscounts,
    this.enableLoyalCustomer,
    this.useProduction,
    this.sellNilItems,
    this.showPriceOnDelivery,
    this.showBrands,
    this.autoDeliver,
    this.saleOnConsignment,
    this.useSerialNumbers,
    this.showAmountBeforeTax,
    this.enableWaInvReq,
    this.whatsappNumber,
    this.pointsThreshold,
    this.pointsRate,
    this.enablePromotions,
    this.submitPreviousYearInvoices,
    this.company,
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

  factory ProductFeature.fromJson(Map<String, dynamic> json) {
    return ProductFeature(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated'],
      dateModified: json['dateModified'],
      createdByName: json['createdByName']?.toString(),
      modifiedByName: json['modifiedByName']?.toString(),
      version: json['version'],
      name: json['name']?.toString() ?? 'Unknown Product Feature',
      description: json['description']?.toString(),
      useProductBrands: json['useProductBrands'],
      specifyProductDepartment: json['specifyProductDepartment'],
      showPricingExcludingTax: json['showPricingExcludingTax'],
      enableDiscounts: json['enableDiscounts'],
      enableLoyalCustomer: json['enableLoyalCustomer'],
      useProduction: json['useProduction'],
      sellNilItems: json['sellNilItems'],
      showPriceOnDelivery: json['showPriceOnDelivery'],
      showBrands: json['showBrands'],
      autoDeliver: json['autoDeliver'],
      saleOnConsignment: json['saleOnConsignment'],
      useSerialNumbers: json['useSerialNumbers'],
      showAmountBeforeTax: json['showAmountBeforeTax'],
      enableWaInvReq: json['enableWaInvReq'],
      whatsappNumber: json['whatsappNumber']?.toString(),
      pointsThreshold: json['pointsThreshold'],
      pointsRate: json['pointsRate'],
      enablePromotions: json['enablePromotions'],
      submitPreviousYearInvoices: json['submitPreviousYearInvoices'],
      company: json['company'] != null ? Company.fromJson(json['company']) : null,
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
      'useProductBrands': useProductBrands,
      'specifyProductDepartment': specifyProductDepartment,
      'showPricingExcludingTax': showPricingExcludingTax,
      'enableDiscounts': enableDiscounts,
      'enableLoyalCustomer': enableLoyalCustomer,
      'useProduction': useProduction,
      'sellNilItems': sellNilItems,
      'showPriceOnDelivery': showPriceOnDelivery,
      'showBrands': showBrands,
      'autoDeliver': autoDeliver,
      'saleOnConsignment': saleOnConsignment,
      'useSerialNumbers': useSerialNumbers,
      'showAmountBeforeTax': showAmountBeforeTax,
      'enableWaInvReq': enableWaInvReq,
      'whatsappNumber': whatsappNumber,
      'pointsThreshold': pointsThreshold,
      'pointsRate': pointsRate,
      'enablePromotions': enablePromotions,
      'submitPreviousYearInvoices': submitPreviousYearInvoices,
      'company': company?.toJson(),
    };
  }
}
