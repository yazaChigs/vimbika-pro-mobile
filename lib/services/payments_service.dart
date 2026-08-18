import 'dart:convert';
import 'dart:io'; // Import for SocketException
import 'dart:async'; // Import for TimeoutException
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:isar/isar.dart';
import 'package:vimbika_pro/services/isar_service.dart';

import '../app_constants/app_constants.dart';
import '../model/online_sale.dart';
import '../model/payment_received.dart';
import '../model/payment_paid.dart';
import '../model/payment_type.dart';
import '../model/currency.dart';
import '../model/branch.dart';
import '../model/user.dart';
import 'base_http_client.dart';

class PaymentsService {
  final BaseHttpClient _client;
  final IsarService _isarService;

  PaymentsService({BaseHttpClient? client, IsarService? isarService})
      : _client = client ?? BaseHttpClient(),
        _isarService = isarService ?? IsarService();

  Future<bool> _checkConnectivity() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult.any((result) => result != ConnectivityResult.none);
  }

  Future<List<PaymentReceived>> fetchPaymentsByAgent({
    required String agentId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.companyId;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String formattedStartDate = '${startDate.toIso8601String().substring(0, 23)}Z';
    final String formattedEndDate = '${endDate.toIso8601String().substring(0, 23)}Z';

    final String endpoint = '/payments/received/get-by-date/$formattedStartDate/$formattedEndDate';

    final String responseStr = await _client.getAuthWithCompanyHeader(
      endpoint,
      companyId,
    );

    final List<dynamic> data = jsonDecode(responseStr) is Map 
        ? [jsonDecode(responseStr)] 
        : jsonDecode(responseStr);
    return data.map((p) => PaymentReceived.fromJson(p)).toList();
  }


  Future<List<PaymentPaid>> fetchPaymentsPaid({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.companyId;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String formattedStartDate = '${startDate.toIso8601String().substring(0, 23)}Z';
    final String formattedEndDate = '${endDate.toIso8601String().substring(0, 23)}Z';

    // The endpoint expects query parameters for 'start' and 'end'
    final String endpoint = "/payments/paid/get-by-date/$formattedStartDate/$formattedEndDate";

    final String responseStr = await _client.getAuthWithCompanyHeader(
      endpoint,
      companyId,
    );

    final List<dynamic> data = jsonDecode(responseStr) is Map 
        ? [jsonDecode(responseStr)] 
        : jsonDecode(responseStr);
    return data.map((p) => PaymentPaid.fromJson(p)).toList();
  }

  Future<List<PaymentType>> fetchPaymentTypes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.companyId;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/payment-method/get-all',
      companyId
    );
    debugPrint(responseStr); // Changed from print to debugPrint

    var decoded = jsonDecode(responseStr);
    
    List<dynamic> data;
    if (decoded is Map<String, dynamic>) {
      // It might be paginated or wrapped in a data field. E.g. {"content": [...]} or {"data": [...]}
      if (decoded.containsKey('content')) {
        data = decoded['content'];
      } else if (decoded.containsKey('data')) {
        data = decoded['data'];
      } else {
        // If it's just a single object returned as map instead of list
        data = [decoded];
      }
    } else if (decoded is List) {
      data = decoded;
    } else {
      data = [];
    }

    final List<PaymentType> paymentTypes = data.map((p) => PaymentType.fromJson(p)).toList();
    debugPrint('Payment types saved to shared preferences ${paymentTypes.first.toJson()}');
    
    // Save to shared preferences
    await prefs.setStringList(AppConstants.keyPaymentTypes, paymentTypes.map((p) => jsonEncode(p.toJson())).toList());
    
    return paymentTypes;
  }

  // Adding the getPaymentTypes method as it was missing and causing an error
  Future<List<PaymentType>> getPaymentTypes() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> paymentTypesJson = prefs.getStringList(AppConstants.keyPaymentTypes) ?? [];
    if (paymentTypesJson.isNotEmpty) {
      return paymentTypesJson.map((json) => PaymentType.fromJson(jsonDecode(json))).toList();
    } else {
      // If not found in local storage, fetch from API
      return await fetchPaymentTypes();
    }
  }

  Future<List<PaymentReceived>> getPayments({
    Branch? branch,
    Currency? currency,
    DateTime? date,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> salesJson = prefs.getStringList(AppConstants.keySales) ?? [];
    
    List<OnlineSale> allSales = salesJson.map((s) => OnlineSale.fromJson(jsonDecode(s))).toList();
    
    List<PaymentReceived> allPayments = [];
    for (var sale in allSales) {
      allPayments.addAll(sale.allPaymentTypes);
    }

    return allPayments.where((payment) {
      bool matchesBranch = true;
      if (branch != null) {
        // Implementation for filtering by branch could be added here
      }

      bool matchesCurrency = true;
      if (currency != null) {
        matchesCurrency = payment.currency.value?.id == currency.id;
      }

      bool matchesDate = true;
      if (date != null) {
        matchesDate = payment.paymentDate != null &&
            DateTime.parse(payment.paymentDate!) .year == date.year &&
            DateTime.parse(payment.paymentDate!).month == date.month &&
            DateTime.parse(payment.paymentDate!).day == date.day;
      }

      return matchesBranch && matchesCurrency && matchesDate;
    }).toList();
  }

  Future<PaymentReceived> savePaymentReceived(PaymentReceived payment) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    final bool isConnected = await _checkConnectivity();

    if (isConnected && !isOfflineMode) {
      try {
        final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
        if (userData == null) throw Exception('User not logged in');
        final user = User.fromJson(jsonDecode(userData));
        final String? companyId = user.companyId;
        if (companyId == null) throw Exception('Company ID not found for user');

        final String jsonPayment = jsonEncode(payment.toJson());
        final String responseStr = await _client.postAuthWithCompanyHeader(
          '/payments/received/receive-payment',
          jsonPayment,
          companyId,
          'POST',
        );
        final Map<String, dynamic> responseData = jsonDecode(responseStr);
        if (responseData.containsKey('item')) {
          return PaymentReceived.fromJson(responseData['item']);
        } else {
          throw Exception('Invalid response format: "item" key not found.');
        }
      } on SocketException catch (e) {
        debugPrint('SocketException during savePaymentReceived: $e. Saving locally.');
        return await savePaymentReceivedLocally(payment);
      } on TimeoutException catch (e) {
        debugPrint('TimeoutException during savePaymentReceived: $e. Saving locally.');
        return await savePaymentReceivedLocally(payment);
      } catch (e) {
        debugPrint('Error during savePaymentReceived: $e. Saving locally.');
        return await savePaymentReceivedLocally(payment);
      }
    } else {
      debugPrint('Offline. Saving payment received locally.');
      return await savePaymentReceivedLocally(payment);
    }
  }

  Future<PaymentReceived> savePaymentReceivedLocally(PaymentReceived payment) async {
    final String posRef = (payment.posReference != null && payment.posReference!.isNotEmpty)
        ? payment.posReference!
        : 'PR_${DateTime.now().microsecondsSinceEpoch}';

    final paymentToSave = payment.copyWith(
      posReference: posRef,
      isSynced: false,
    );
    await _isarService.savePaymentReceived(paymentToSave);
    return paymentToSave;
  }

  Future<List<PaymentReceived>> getUnsyncedReceivedPaymentsLocally() async {
    return await _isarService.getUnsyncedPayments();
  }

  Future<void> removeUnsyncedReceivedPaymentLocally({
    String? paymentId,
    String? posReference,
    Id? isarId,
  }) async {
    await _isarService.deletePaymentReceived(
      paymentId: paymentId,
      posReference: posReference,
      isarId: isarId,
    );
    await _removePaymentFromSharedPreferences(
      posReference: posReference,
      paymentId: paymentId,
    );
  }

  Future<void> _removePaymentFromSharedPreferences({
    String? posReference,
    String? paymentId,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      for (String key in [
        AppConstants.keyUnsyncedReceivedPayments,
        AppConstants.keyOfflinePaymentsReceived,
      ]) {
        final list = prefs.getStringList(key);
        if (list != null && list.isNotEmpty) {
          final updatedList = list.where((item) {
            try {
              final json = jsonDecode(item);
              if (posReference != null &&
                  posReference.isNotEmpty &&
                  json['posReference'] == posReference) {
                return false;
              }
              if (paymentId != null &&
                  paymentId.isNotEmpty &&
                  paymentId != 'null' &&
                  json['id']?.toString() == paymentId) {
                return false;
              }
              return true;
            } catch (_) {
              return true;
            }
          }).toList();
          await prefs.setStringList(key, updatedList);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning payment from SharedPreferences: $e');
    }
  }

  Future<bool> syncReceivedPayment(PaymentReceived payment) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);

    if (userData == null) {
      debugPrint('User not logged in, cannot sync payment.');
      return false;
    }
    final user = User.fromJson(jsonDecode(userData));

    final String? companyId = user.companyId;
    if (companyId == null) {
      debugPrint('Company ID not found for user, cannot sync payment.');
      return false;
    }

    bool isConnected = await _checkConnectivity();
    if (!isConnected) {
      debugPrint('Offline, cannot sync payment.');
      return false;
    }

    // If payment is already synced with a server ID, isolate/remove from unsynced list
    if (payment.isSynced == true && payment.id != null && payment.id!.isNotEmpty && payment.id != 'null') {
      await removeUnsyncedReceivedPaymentLocally(
        paymentId: payment.id,
        posReference: payment.posReference,
        isarId: payment.isarId,
      );
      debugPrint('Payment ${payment.posReference ?? payment.id} is already marked as synced.');
      return true;
    }

    // Ensure payment has a posReference for tracking/isolation
    final String posRef = (payment.posReference != null && payment.posReference!.isNotEmpty)
        ? payment.posReference!
        : 'PR_${DateTime.now().microsecondsSinceEpoch}';
    final paymentToSync = payment.copyWith(posReference: posRef);

    try {
      final String jsonPayment = jsonEncode(paymentToSync.toJson());
      final String responseStr = await _client.postAuthWithCompanyHeader(
        '/payments/received/receive-payment',
        jsonPayment,
        companyId,
        'POST',
      );
      final Map<String, dynamic> responseData = jsonDecode(responseStr);
      if (responseData.containsKey('item')) {
        // If successful, remove/isolate the synced payment using posReference
        await removeUnsyncedReceivedPaymentLocally(
          paymentId: paymentToSync.id,
          posReference: paymentToSync.posReference,
          isarId: paymentToSync.isarId,
        );
        debugPrint('Payment with posReference ${paymentToSync.posReference} synced successfully.');
        return true;
      } else {
        debugPrint('Invalid response format during syncReceivedPayment: "item" key not found.');
        return false;
      }
    } on SocketException catch (e) {
      debugPrint('SocketException during syncReceivedPayment for ${paymentToSync.posReference}: $e');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException during syncReceivedPayment for ${paymentToSync.posReference}: $e');
      return false;
    } catch (e) {
      debugPrint('Error during syncReceivedPayment for ${paymentToSync.posReference}: $e');
      return false;
    }
  }
}
