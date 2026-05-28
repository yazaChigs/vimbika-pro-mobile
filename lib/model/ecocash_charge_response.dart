class EcocashChargeResponse {
  final int id;
  final int version;
  final String clientCorrelator;
  final int endTime;
  final int startTime;
  final String notifyUrl;
  final String referenceCode;
  final String endUserId;
  final String serverReferenceCode;
  final String transactionOperationStatus;
  final PaymentAmountResponse paymentAmount;
  final String? ecocashReference;
  final String merchantCode;
  final String merchantPin;
  final String merchantNumber;
  final String? notificationFormat;
  final String? serviceId;
  final String? originalServerReferenceCode;
  final String? originalEcocashReference;
  final int transactionDate;
  final String? orginalMerchantReference;
  final String? type;
  final String? source;
  final String? countryCode;
  final String? currencyCode;
  final String? superMerchantName;
  final String? merchantName;
  final String? terminalID;
  final String? location;
  final String? tranType;
  final String? originalClientCorrelator;
  final String? responseCode;
  final String remarks;

  EcocashChargeResponse({
    required this.id,
    required this.version,
    required this.clientCorrelator,
    required this.endTime,
    required this.startTime,
    required this.notifyUrl,
    required this.referenceCode,
    required this.endUserId,
    required this.serverReferenceCode,
    required this.transactionOperationStatus,
    required this.paymentAmount,
    this.ecocashReference,
    required this.merchantCode,
    required this.merchantPin,
    required this.merchantNumber,
    this.notificationFormat,
    this.serviceId,
    this.originalServerReferenceCode,
    this.originalEcocashReference,
    required this.transactionDate,
    this.orginalMerchantReference,
    this.type,
    this.source,
    this.countryCode,
    this.currencyCode,
    this.superMerchantName,
    this.merchantName,
    this.terminalID,
    this.location,
    this.tranType,
    this.originalClientCorrelator,
    this.responseCode,
    required this.remarks,
  });

  factory EcocashChargeResponse.fromJson(Map<String, dynamic> json) {
    return EcocashChargeResponse(
      id: json['id'],
      version: json['version'],
      clientCorrelator: json['clientCorrelator'],
      endTime: json['endTime'],
      startTime: json['startTime'],
      notifyUrl: json['notifyUrl'],
      referenceCode: json['referenceCode'],
      endUserId: json['endUserId'],
      serverReferenceCode: json['serverReferenceCode'],
      transactionOperationStatus: json['transactionOperationStatus'],
      paymentAmount: PaymentAmountResponse.fromJson(json['paymentAmount']),
      ecocashReference: json['ecocashReference'],
      merchantCode: json['merchantCode'],
      merchantPin: json['merchantPin'],
      merchantNumber: json['merchantNumber'],
      notificationFormat: json['notificationFormat'],
      serviceId: json['serviceId'],
      originalServerReferenceCode: json['originalServerReferenceCode'],
      originalEcocashReference: json['originalEcocashReference'],
      transactionDate: json['transactionDate'],
      orginalMerchantReference: json['orginalMerchantReference'],
      type: json['type'],
      source: json['source'],
      countryCode: json['countryCode'],
      currencyCode: json['currencyCode'],
      superMerchantName: json['superMerchantName'],
      merchantName: json['merchantName'],
      terminalID: json['terminalID'],
      location: json['location'],
      tranType: json['tranType'],
      originalClientCorrelator: json['originalClientCorrelator'],
      responseCode: json['responseCode'],
      remarks: json['remarks'],
    );
  }
}

class PaymentAmountResponse {
  final double totalAmountCharged;
  final ChargingInformationResponse charginginformation;
  final ChargeMetaDataResponse chargeMetaData;

  PaymentAmountResponse({
    required this.totalAmountCharged,
    required this.charginginformation,
    required this.chargeMetaData,
  });

  factory PaymentAmountResponse.fromJson(Map<String, dynamic> json) {
    return PaymentAmountResponse(
      totalAmountCharged: json['totalAmountCharged'],
      charginginformation:
          ChargingInformationResponse.fromJson(json['charginginformation']),
      chargeMetaData: ChargeMetaDataResponse.fromJson(json['chargeMetaData']),
    );
  }
}

class ChargingInformationResponse {
  final double amount;
  final String? cashbackAmount;
  final String currency;
  final String description;

  ChargingInformationResponse({
    required this.amount,
    this.cashbackAmount,
    required this.currency,
    required this.description,
  });

  factory ChargingInformationResponse.fromJson(Map<String, dynamic> json) {
    return ChargingInformationResponse(
      amount: json['amount'],
      cashbackAmount: json['cashbackAmount'],
      currency: json['currency'],
      description: json['description'],
    );
  }
}

class ChargeMetaDataResponse {
  final String channel;
  final String purchaseCategoryCode;
  final String onBeHalfOf;
  final String? serviceId;

  ChargeMetaDataResponse({
    required this.channel,
    required this.purchaseCategoryCode,
    required this.onBeHalfOf,
    this.serviceId,
  });

  factory ChargeMetaDataResponse.fromJson(Map<String, dynamic> json) {
    return ChargeMetaDataResponse(
      channel: json['channel'],
      purchaseCategoryCode: json['purchaseCategoryCode'],
      onBeHalfOf: json['onBeHalfOf'],
      serviceId: json['serviceId'],
    );
  }
}
