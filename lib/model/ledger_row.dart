import 'dart:convert';

import 'package:flutter/foundation.dart';

class LedgerRow {
  final DateTime? date;
  final String? accountingSource;
  final String? type;
  final String? reference;
  final double? debit;
  final double? credit;
  final double? runningBalance;
  final double? allocatedAmount;
  final String? status;
  final String? sourceDocumentId;
  final String? currency;
  final String? counterPartyName;
  final String? counterPartyId;
  final String? account;
  final String? lineId;
  final bool? reconciled;
  final String? journalId;
  final String? depositId;
  final String? invoiceId;
  final bool? reversed;
  final bool? reversal;
  final bool? canReverse;

  LedgerRow({
    this.date,
    this.accountingSource,
    this.type,
    this.reference,
    this.debit,
    this.credit,
    this.runningBalance,
    this.allocatedAmount,
    this.status,
    this.sourceDocumentId,
    this.currency,
    this.counterPartyName,
    this.counterPartyId,
    this.account,
    this.lineId,
    this.reconciled,
    this.journalId,
    this.depositId,
    this.invoiceId,
    this.reversed,
    this.reversal,
    this.canReverse,
  });

  factory LedgerRow.fromJson(Map<String, dynamic> json) {
    return LedgerRow(
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      accountingSource: json['accountingSource'],
      type: json['type'],
      reference: json['reference'],
      debit: json['debit']?.toDouble(),
      credit: json['credit']?.toDouble(),
      runningBalance: json['runningBalance']?.toDouble(),
      allocatedAmount: json['allocatedAmount']?.toDouble(),
      // status: json['status'] ,
      sourceDocumentId: json['sourceDocumentId'],
      currency: json['currency'],
      counterPartyName: json['counterPartyName'],
      counterPartyId: json['counterPartyId'],
      // account: json['account'] ,
      lineId: json['lineId'],
      reconciled: json['reconciled'],
      journalId: json['journalId'],
      depositId: json['depositId'],
      invoiceId: json['invoiceId'],
      reversed: json['reversed'],
      reversal: json['reversal'],
      canReverse: json['canReverse'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date?.toIso8601String(),
      'accountingSource': accountingSource,
      'type': type,
      'reference': reference,
      'debit': debit,
      'credit': credit,
      'runningBalance': runningBalance,
      'allocatedAmount': allocatedAmount,
      'status': status?.toString().split('.').last,
      'sourceDocumentId': sourceDocumentId,
      'currency': currency,
      'counterPartyName': counterPartyName,
      'counterPartyId': counterPartyId,
      'account': account,
      'lineId': lineId,
      'reconciled': reconciled,
      'journalId': journalId,
      'depositId': depositId,
      'invoiceId': invoiceId,
      'reversed': reversed,
      'reversal': reversal,
      'canReverse': canReverse,
    };
  }

  LedgerRow copyWith({
    DateTime? date,
    String? accountingSource,
    String? type,
    String? reference,
    double? debit,
    double? credit,
    double? runningBalance,
    double? allocatedAmount,
    String? status,
    String? sourceDocumentId,
    String? currency,
    String? counterPartyName,
    String? counterPartyId,
    String? account,
    String? lineId,
    bool? reconciled,
    String? journalId,
    String? depositId,
    String? invoiceId,
    bool? reversed,
    bool? reversal,
    bool? canReverse,
  }) {
    return LedgerRow(
      date: date ?? this.date,
      accountingSource: accountingSource ?? this.accountingSource,
      type: type ?? this.type,
      reference: reference ?? this.reference,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
      runningBalance: runningBalance ?? this.runningBalance,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      status: status ?? this.status,
      sourceDocumentId: sourceDocumentId ?? this.sourceDocumentId,
      currency: currency ?? this.currency,
      counterPartyName: counterPartyName ?? this.counterPartyName,
      counterPartyId: counterPartyId ?? this.counterPartyId,
      account: account ?? this.account,
      lineId: lineId ?? this.lineId,
      reconciled: reconciled ?? this.reconciled,
      journalId: journalId ?? this.journalId,
      depositId: depositId ?? this.depositId,
      invoiceId: invoiceId ?? this.invoiceId,
      reversed: reversed ?? this.reversed,
      reversal: reversal ?? this.reversal,
      canReverse: canReverse ?? this.canReverse,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LedgerRow &&
        other.date == date &&
        other.accountingSource == accountingSource &&
        other.type == type &&
        other.reference == reference &&
        other.debit == debit &&
        other.credit == credit &&
        other.runningBalance == runningBalance &&
        other.allocatedAmount == allocatedAmount &&
        other.status == status &&
        other.sourceDocumentId == sourceDocumentId &&
        other.currency == currency &&
        other.counterPartyName == counterPartyName &&
        other.counterPartyId == counterPartyId &&
        other.account == account &&
        other.lineId == lineId &&
        other.reconciled == reconciled &&
        other.journalId == journalId &&
        other.depositId == depositId &&
        other.invoiceId == invoiceId &&
        other.reversed == reversed &&
        other.reversal == reversal &&
        other.canReverse == canReverse;
  }

  @override
  int get hashCode {
    return date.hashCode ^
        accountingSource.hashCode ^
        type.hashCode ^
        reference.hashCode ^
        debit.hashCode ^
        credit.hashCode ^
        runningBalance.hashCode ^
        allocatedAmount.hashCode ^
        status.hashCode ^
        sourceDocumentId.hashCode ^
        currency.hashCode ^
        counterPartyName.hashCode ^
        counterPartyId.hashCode ^
        account.hashCode ^
        lineId.hashCode ^
        reconciled.hashCode ^
        journalId.hashCode ^
        depositId.hashCode ^
        invoiceId.hashCode ^
        reversed.hashCode ^
        reversal.hashCode ^
        canReverse.hashCode;
  }
}

enum AllocationStatus {
  OPEN,
  ALLOCATED,
  PARTIALLY_ALLOCATED,
  // Add other statuses as needed
}

class AccountingSourceDocument {
  final String? id;
  final String? name;
  // Add other fields as needed for AccountingSourceDocument

  AccountingSourceDocument({
    this.id,
    this.name,
  });

  factory AccountingSourceDocument.fromJson(Map<String, dynamic> json) {
    return AccountingSourceDocument(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AccountingSourceDocument &&
        other.id == id &&
        other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

class ControlAccount {
  final String? id;
  final String? name;
  // Add other fields as needed for ControlAccount

  ControlAccount({
    this.id,
    this.name,
  });

  factory ControlAccount.fromJson(Map<String, dynamic> json) {
    return ControlAccount(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ControlAccount && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
