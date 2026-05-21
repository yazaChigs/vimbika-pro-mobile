import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'ledger_row.dart'; // Import the LedgerRow model

class LedgerResponse {
  final double? openingBalance;
  final List<LedgerRow>? lines;
  final double? closingBalance;

  LedgerResponse({
    this.openingBalance,
    this.lines,
    this.closingBalance,
  });

  factory LedgerResponse.fromJson(Map<String, dynamic> json) {
    return LedgerResponse(
      openingBalance: json['openingBalance']?.toDouble(),
      lines: json['lines'] != null
          ? List<LedgerRow>.from(
              json['lines'].map((x) => LedgerRow.fromJson(x)))
          : null,
      closingBalance: json['closingBalance']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'openingBalance': openingBalance,
      'lines': lines?.map((x) => x.toJson()).toList(),
      'closingBalance': closingBalance,
    };
  }

  LedgerResponse copyWith({
    double? openingBalance,
    List<LedgerRow>? lines,
    double? closingBalance,
  }) {
    return LedgerResponse(
      openingBalance: openingBalance ?? this.openingBalance,
      lines: lines ?? this.lines,
      closingBalance: closingBalance ?? this.closingBalance,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LedgerResponse &&
        other.openingBalance == openingBalance &&
        listEquals(other.lines, lines) && // Use listEquals for List comparison
        other.closingBalance == closingBalance;
  }

  @override
  int get hashCode =>
      openingBalance.hashCode ^ listEquals(lines, null).hashCode ^ closingBalance.hashCode;
}
