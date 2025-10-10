import 'dart:convert';
import 'dart:ffi';
import '../../features/customers/model/customer_currency_amount.dart';
import 'base_name_model.dart';

CustomerModel customerModelFromJson(String str) =>
    CustomerModel.fromJson(json.decode(str));
String customerModelToJson(CustomerModel data) => json.encode(data.toJson());

class CustomerModel {
  CustomerModel(
      {this.id,
      this.name,
      this.companyName,
      this.email,
      this.mobilePhone,
      this.customerId,
      this.branch,
      this.description,
      this.tinNumber,
      this.taxNumber,
      this.street,
      this.accountNumber,
      this.isLoyalCustomer,
      this.points,
      this.currencyBalance,
      this.nfcCardId,
      this.nfcCardType,
        this.accountBalance,
              this.updated = false});

  String? id;
  String? name;
  String? companyName;
  String? email;
  String? mobilePhone;
  String? customerId;
  BaseNameModel? branch;
  String? description;
  String? tinNumber;
  String? taxNumber;
  String? street;
  bool? isLoyalCustomer;
  String? accountNumber;
  double? points;
  double? accountBalance;
  String? nfcCardId;
  String? nfcCardType;
  bool? updated;
  List<CustomerCurrencyAmount>? currencyBalance;

  factory CustomerModel.fromJson(String str) =>
      CustomerModel.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CustomerModel.fromMap(Map<String, dynamic> json) => CustomerModel(
        id: json["id"],
        name: json["name"],
        companyName: json["companyName"],
        email: json["email"],
        mobilePhone: json["mobilePhone"],
        customerId: json["customerId"],
        branch: json["branch"] != null
            ? BaseNameModel.fromMap(json["branch"])
            : null,
        description: json["description"],
        currencyBalance: List<CustomerCurrencyAmount>.from(
            json["currencyBalance"]
                .map((x) => CustomerCurrencyAmount.fromMap(x))),
        tinNumber: json["tinNumber"],
        taxNumber: json["taxNumber"],
        street: json["street"],
        updated: json["updated"],
        accountBalance: json["accountBalance"],
        isLoyalCustomer: json["isLoyalCustomer"],
        accountNumber: json["accountNumber"],
        points: json["points"],
        nfcCardId: json["nfcCardId"],
        nfcCardType: json["nfcCardType"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "companyName": companyName,
        "email": email,
        "mobilePhone": mobilePhone,
        "customerId": customerId,
        "branch": branch?.toMap(),
        "description": description,
        "currencyBalance":
            List<dynamic>.from(currencyBalance?.map((x) => x.toMap())??[]),
        "tinNumber": tinNumber,
        "taxNumber": taxNumber,
        "street": street,
        "updated": updated,
        "accountBalance": accountBalance,
        "points": points,
        "accountNumber": accountNumber,
        "isLoyalCustomer": isLoyalCustomer,
        "nfcCardId": nfcCardId,
        "nfcCardType": nfcCardType,
      };
}
