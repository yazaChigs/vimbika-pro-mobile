import 'dart:convert';
import 'dart:io'; // Import for SocketException
import 'dart:async'; // Import for TimeoutException
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus
import 'package:flutter/foundation.dart'; // For debugPrint

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
  final BaseHttpClient _client = BaseHttpClient();

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
    
    final String? companyId = user.branch?.company?.id;
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
    
    final String? companyId = user.branch?.company?.id;
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
    
    final String? companyId = user.branch?.company?.id;
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
      if (sale.paymentTypes != null) {
        allPayments.addAll(sale.paymentTypes!);
      }
    }

    return allPayments.where((payment) {
      bool matchesBranch = true;
      if (branch != null) {
        // Implementation for filtering by branch could be added here
      }

      bool matchesCurrency = true;
      if (currency != null) {
        matchesCurrency = payment.currency?.id == currency.id;
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
        final String? companyId = user.branch?.company?.id;
        if (companyId == null) throw Exception('Company ID not found for user');

        final String jsonPayment = jsonEncode(payment.toJson());
        final String responseStr = await _client.postAuthWithCompanyHeader(
          '/payments/received/receive-payment',
          jsonPayment,
          companyId,
          'POST',
        );
        return PaymentReceived.fromJson(jsonDecode(responseStr));
      } on SocketException catch (e) {
        debugPrint('SocketException during savePaymentReceived: $e. Saving locally.');
        return await _savePaymentReceivedLocally(payment);
      } on TimeoutException catch (e) {
        debugPrint('TimeoutException during savePaymentReceived: $e. Saving locally.');
        return await _savePaymentReceivedLocally(payment);
      } catch (e) {
        debugPrint('Error during savePaymentReceived: $e. Saving locally.');
        return await _savePaymentReceivedLocally(payment);
      }
    } else {
      debugPrint('Offline. Saving payment received locally.');
      return await _savePaymentReceivedLocally(payment);
    }
  }

  Future<PaymentReceived> _savePaymentReceivedLocally(PaymentReceived payment) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<PaymentReceived> unsyncedPayments = await getUnsyncedReceivedPaymentsLocally();

    // Assign a temporary ID if it doesn't have one (e.g., if it's a new offline payment)
    if (payment.id == null || payment.id!.isEmpty) {
      payment = payment.copyWith(id: 'local_${DateTime.now().millisecondsSinceEpoch}');
    }
    
    // Check if payment already exists in unsynced
    int existingIndex = unsyncedPayments.indexWhere((p) => p.id == payment.id);
    if (existingIndex != -1) {
      unsyncedPayments[existingIndex] = payment.copyWith(isSynced: false); // Update existing
    } else {
      unsyncedPayments.add(payment.copyWith(isSynced: false)); // Add new to unsynced
    }
    
    await prefs.setStringList(
      AppConstants.keyUnsyncedReceivedPayments,
      unsyncedPayments.map((p) => jsonEncode(p.toJson())).toList(),
    );

    // Also add to the general offline payments list so it shows up in reports
    final List<String> offlinePaymentsJson = prefs.getStringList(AppConstants.keyOfflinePaymentsReceived) ?? [];
    List<PaymentReceived> allOfflinePayments = offlinePaymentsJson.map((json) => PaymentReceived.fromJson(jsonDecode(json))).toList();
    
    int existingOfflineIndex = allOfflinePayments.indexWhere((p) => p.id == payment.id);
    if (existingOfflineIndex != -1) {
       allOfflinePayments[existingOfflineIndex] = payment;
    } else {
       allOfflinePayments.add(payment);
    }
    
    await prefs.setStringList(AppConstants.keyOfflinePaymentsReceived, allOfflinePayments.map((p) => jsonEncode(p.toJson())).toList());


    return payment;
  }

  Future<List<PaymentReceived>> getUnsyncedReceivedPaymentsLocally() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> unsyncedPaymentsJson = prefs.getStringList(AppConstants.keyUnsyncedReceivedPayments) ?? [];
    return unsyncedPaymentsJson.map((json) => PaymentReceived.fromJson(jsonDecode(json))).toList();
  }

  Future<void> removeUnsyncedReceivedPaymentLocally(String paymentId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<PaymentReceived> unsyncedPayments = await getUnsyncedReceivedPaymentsLocally();
    unsyncedPayments.removeWhere((p) => p.id == paymentId);
    await prefs.setStringList(
      AppConstants.keyUnsyncedReceivedPayments,
      unsyncedPayments.map((p) => jsonEncode(p.toJson())).toList(),
    );
  }

  Future<bool> syncReceivedPayment(PaymentReceived payment) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);

    if (userData == null) {
      debugPrint('User not logged in, cannot sync payment.');
      return false;
    }
    final user = User.fromJson(jsonDecode(userData));

    final String? companyId = user.branch?.company?.id;
    if (companyId == null) {
      debugPrint('Company ID not found for user, cannot sync payment.');
      return false;
    }

    bool isConnected = await _checkConnectivity();
    if (!isConnected) {
      debugPrint('Offline, cannot sync payment.');
      return false;
    }

    try {
      final String jsonPayment = jsonEncode(payment.toJson());
      await _client.postAuthWithCompanyHeader( // Removed unused variable assignment
        '/payments/received/receive-payment',
        jsonPayment,
        companyId,
        'POST',
      );
      
      // If successful, remove from local unsynced list
      await removeUnsyncedReceivedPaymentLocally(payment.id!);
      debugPrint('Payment ${payment.id} synced successfully.');
      return true;
    } on SocketException catch (e) {
      debugPrint('SocketException during syncReceivedPayment for ${payment.id}: $e');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('TimeoutException during syncReceivedPayment for ${payment.id}: $e');
      return false;
    } catch (e) {
      debugPrint('Error during syncReceivedPayment for ${payment.id}: $e');
      return false;
    }
  }
}
