import 'customer.dart';
import 'inventory_item.dart';

class EcocashChargeRequest {
  final String clientCorrelator;
  final String notifyUrl;
  final String referenceCode;
  final String tranType;
  final String endUserId;
  final String remarks;
  final String transactionOperationStatus;
  final PaymentAmount paymentAmount;
  final String merchantCode;
  final String merchantPin;
  final String merchantNumber;
  final String currencyCode;
  final String countryCode;
  final String terminalID;
  final String location;
  final String superMerchantName;
  final String merchantName;
  final Customer customer;
  final InventoryItem? subscriptionItem;

  EcocashChargeRequest({
    required this.clientCorrelator,
    required this.notifyUrl,
    required this.referenceCode,
    required this.tranType,
    required this.endUserId,
    required this.remarks,
    required this.transactionOperationStatus,
    required this.paymentAmount,
    required this.merchantCode,
    required this.merchantPin,
    required this.merchantNumber,
    required this.currencyCode,
    required this.countryCode,
    required this.terminalID,
    required this.location,
    required this.superMerchantName,
    required this.merchantName,
    required this.customer,
    this.subscriptionItem,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientCorrelator': clientCorrelator,
      'notifyUrl': notifyUrl,
      'referenceCode': referenceCode,
      'tranType': tranType,
      'endUserId': endUserId,
      'remarks': remarks,
      'transactionOperationStatus': transactionOperationStatus,
      'paymentAmount': paymentAmount.toJson(),
      'merchantCode': merchantCode,
      'merchantPin': merchantPin,
      'merchantNumber': merchantNumber,
      'currencyCode': currencyCode,
      'countryCode': countryCode,
      'terminalID': terminalID,
      'location': location,
      'superMerchantName': superMerchantName,
      'merchantName': merchantName,
      'customer': customer.toJson(),
      'subscriptionItem': subscriptionItem?.toJson(),

    };
  }
}

class PaymentAmount {
  final ChargingInformation charginginformation;
  final ChargeMetaData chargeMetaData;

  PaymentAmount({
    required this.charginginformation,
    required this.chargeMetaData,
  });

  Map<String, dynamic> toJson() {
    return {
      'charginginformation': charginginformation.toJson(),
      'chargeMetaData': chargeMetaData.toJson(),
    };
  }
}

class ChargingInformation {
  final double amount;
  final String currency;
  final String description;

  ChargingInformation({
    required this.amount,
    required this.currency,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'description': description,
    };
  }
}

class ChargeMetaData {
  final String channel;
  final String purchaseCategoryCode;
  final String onBeHalfOf;

  ChargeMetaData({
    required this.channel,
    required this.purchaseCategoryCode,
    required this.onBeHalfOf,
  });

  Map<String, dynamic> toJson() {
    return {
      'channel': channel,
      'purchaseCategoryCode': purchaseCategoryCode,
      'onBeHalfOf': onBeHalfOf,
    };
  }
}
