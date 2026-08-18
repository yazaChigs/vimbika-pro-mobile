import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import 'package:vimbika_pro/services/customer_sync_service.dart';
import '../app_constants/app_constants.dart';
import '../model/customer.dart';
import '../model/user.dart';
import '../model/ledger_response.dart'; // Import the LedgerResponse model
import 'base_http_client.dart';

class CustomerService {
  final BaseHttpClient _client;

  CustomerService({BaseHttpClient? client}) : _client = client ?? BaseHttpClient();

  // Fetches customers from API and saves them locally, marking them as synced
  Future<List<Customer>> fetchCustomers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.companyId;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/customer/get-all',
      companyId
    );

    final List<dynamic> data = jsonDecode(responseStr);
    final List<Customer> customers = data.map((c) => Customer.fromJson(c).copyWith(isSynced: true)).toList();
    
    // Save to shared preferences, overwriting existing synced customers
    // but preserving unsynced ones
    List<Customer> localCustomers = await getCustomersLocally();
    
    Map<String, Customer> mergedCustomers = {};
    // Start with all currently known customers
    for (var c in localCustomers) {
      String key = c.id ?? 'name_${c.name.toLowerCase().trim()}';
      mergedCustomers[key] = c;
    }
    
    // Add/Update with newly fetched customers from API
    for (var c in customers) {
      if (c.id != null) {
        // Remove any local existing entries that match this customer by ID or Name
        final keysToRemove = mergedCustomers.keys.where((k) {
          final existing = mergedCustomers[k]!;
          return k == c.id ||
              (existing.id != null && existing.id == c.id) ||
              existing.name.toLowerCase().trim() == c.name.toLowerCase().trim();
        }).toList();

        for (var k in keysToRemove) {
          mergedCustomers.remove(k);
        }

        // Add the fetched customer from API (source of truth)
        mergedCustomers[c.id!] = c;
      }
    }
    
    final List<Customer> allCustomersToSave = mergedCustomers.values.toList();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    
    // We always save to both keys or just the online key if we are online.
    // To be safest, we save the full merged list to the appropriate key.
    final String customerKey = isOfflineMode ? AppConstants.keyOfflineCustomers : AppConstants.keyCustomers;
    await prefs.setStringList(customerKey, allCustomersToSave.map((c) => jsonEncode(c.toJson())).toList());
    
    return allCustomersToSave;
  }

  // Saves a customer to the API
  Future<Customer> saveCustomer(Customer customer) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.companyId;
    if (companyId == null) throw Exception('Company ID not found for user');

    // Ensure the customer being sent to API has branch and company set if missing
    final Customer customerToSend = customer.copyWith(
      isSynced: true,
      company: customer.company.value ?? user.branch?.company.value,
      branch: customer.branch.value ?? user.branch,
    );

    final String jsonCustomer = jsonEncode(customerToSend.toJson());

    final String responseStr = await _client.postAuthWithCompanyHeader(
      '/customer/save',
      jsonCustomer,
      companyId,
      'POST'
    );

    final Map<String, dynamic> responseJson = jsonDecode(responseStr);
    final Customer savedCustomer = Customer.fromJson(responseJson['item']);
    return savedCustomer.copyWith(isSynced: true); // Ensure returned customer is marked as synced
  }

  // Saves a customer to the API with specific company ID
  Future<Customer> saveCustomerWithCompany(Customer customer, String companyId) async {
    // Ensure the customer being sent to API has isSynced: true for consistency
    final Customer customerToSend = customer.copyWith(isSynced: true);

    final String jsonCustomer = jsonEncode(customerToSend.toJson());

    final String responseStr = await _client.postAuthWithCompanyHeader(
      '/customer/save',
      jsonCustomer,
      companyId,
      'POST'
    );

    final Map<String, dynamic> responseJson = jsonDecode(responseStr);
    final Customer savedCustomer = Customer.fromJson(responseJson['item']);
    return savedCustomer.copyWith(isSynced: true);
  }

  // Updates a customer to the API
  Future<Customer> updateCustomer(Customer customer) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
      
      if (userData == null) throw Exception('User not logged in');
      final user = User.fromJson(jsonDecode(userData));
      
      final String? companyId = user.companyId;
      if (companyId == null) throw Exception('Company ID not found for user');

      // Ensure the customer being sent to API has branch and company set if missing
      final Customer customerToSend = customer.copyWith(
        isSynced: true,
        company: customer.company.value ?? user.branch?.company.value,
        branch: customer.branch.value ?? user.branch,
      );

      final String jsonCustomer = jsonEncode(customerToSend.toJson());

      final String responseStr = await _client.postAuthWithCompanyHeader(
        '/customer/update',
        jsonCustomer,
        companyId,
        'PUT'
      );

      final Customer updatedCustomer = Customer.fromJson(jsonDecode(responseStr));
      final Customer syncedCustomer = updatedCustomer.copyWith(isSynced: true);
      await saveCustomerLocally(syncedCustomer);
      return syncedCustomer;
    } catch (e) {
      debugPrint('Failed to update customer to API, queueing for sync: $e');
      final Customer unsyncedCustomer = customer.copyWith(isSynced: false);
      await saveCustomerLocally(unsyncedCustomer);
      CustomerSyncService().startSyncTimer();
      return unsyncedCustomer;
    }
  }

  // Saves or updates a customer in local storage (SharedPreferences)
  Future<void> saveCustomerLocally(Customer customer) async {
    await saveCustomersLocally([customer]);
  }

  // Saves multiple customers to local storage (SharedPreferences)
  Future<void> saveCustomersLocally(List<Customer> updatedCustomers) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Customer> customers = await getCustomersLocally();

    for (var updatedCustomer in updatedCustomers) {
      // Remove any existing entries matching this customer by ID or by name
      customers.removeWhere((c) =>
          (updatedCustomer.id != null && c.id != null && c.id == updatedCustomer.id) ||
          (c.name.toLowerCase().trim() == updatedCustomer.name.toLowerCase().trim()));
      
      customers.add(updatedCustomer);
    }

    final bool isOfflineMode =
        prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    final String customerKey =
        isOfflineMode ? AppConstants.keyOfflineCustomers : AppConstants.keyCustomers;
    await prefs.setStringList(
        customerKey, customers.map((c) => jsonEncode(c.toJson())).toList());
  }

  // Retrieves all customers from local storage (SharedPreferences)
  Future<List<Customer>> getCustomersLocally() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode =
        prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    final String customerKey =
        isOfflineMode ? AppConstants.keyOfflineCustomers : AppConstants.keyCustomers;
    final List<String> customersJson = prefs.getStringList(customerKey) ?? [];
    return customersJson
        .map((json) => Customer.fromJson(jsonDecode(json)))
        .toList();
  }

  // Retrieves customers that have not yet been synced to the API
  Future<List<Customer>> getUnsyncedCustomers() async {
    final List<Customer> allCustomers = await getCustomersLocally();
    return allCustomers.where((customer) => !customer.isSynced).toList();
  }

  // Syncs a single unsynced customer to the API
  Future<Customer> syncCustomer(Customer unsyncedCustomer) async {
    try {
      // Check if this customer has already been synced locally
      List<Customer> currentLocal = await getCustomersLocally();
      final existingSynced = currentLocal.firstWhereOrNull((c) =>
          c.isSynced &&
          ((unsyncedCustomer.id != null && c.id == unsyncedCustomer.id) ||
           (c.name.toLowerCase().trim() == unsyncedCustomer.name.toLowerCase().trim())));
      if (existingSynced != null) {
        debugPrint('Customer ${unsyncedCustomer.name} is already synced.');
        return existingSynced;
      }

      // Attempt to save to API
      final Customer apiCustomer = await saveCustomer(unsyncedCustomer);
      if (apiCustomer.id == null) {
        throw Exception('API did not return a customer ID');
      }
      final Customer syncedCustomer = apiCustomer.copyWith(isSynced: true);

      // Remove the old unsynced customer (by old ID or name) before saving the synced one
      if (unsyncedCustomer.id != null && unsyncedCustomer.id != syncedCustomer.id) {
        await removeCustomerLocally(unsyncedCustomer.id!);
      }
      await removeCustomerLocallyByName(unsyncedCustomer.name);

      await saveCustomerLocally(syncedCustomer);

      return syncedCustomer;
    } catch (e) {
      // If API sync fails, re-throw to indicate failure
      rethrow;
    }
  }

  // Removes a customer from local storage by ID from ALL buckets
  Future<void> removeCustomerLocally(String customerId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Customer> customers = await getCustomersLocally();
    customers.removeWhere((c) => c.id == customerId);
    
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    final String customerKey = isOfflineMode ? AppConstants.keyOfflineCustomers : AppConstants.keyCustomers;

    await prefs.setStringList(customerKey, customers.map((c) => jsonEncode(c.toJson())).toList());
  }

  // Removes a customer from local storage by Name from ALL buckets
  Future<void> removeCustomerLocallyByName(String customerName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Customer> customers = await getCustomersLocally();
    customers.removeWhere((c) => c.name.toLowerCase().trim() == customerName.toLowerCase().trim());
    
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    final String customerKey = isOfflineMode ? AppConstants.keyOfflineCustomers : AppConstants.keyCustomers;

    await prefs.setStringList(customerKey, customers.map((c) => jsonEncode(c.toJson())).toList());
  }

  // Fetches customer statements from the API
  Future<LedgerResponse> getCustomerStatements({
    required String currency,
    String? counterPartyId,
    String? startDate,
    String? endDate,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.companyId;
    if (companyId == null) throw Exception('Company ID not found for user');

    final Map<String, dynamic> requestBody = {
      'currency': currency,
      'accounts':
        ['TRADE_RECEIVABLES', 'CUSTOMER_DEPOSITS']
      ,
    };

    if (counterPartyId != null) {
      requestBody['counterPartyId'] = counterPartyId;
    }
    if (startDate != null) {
      requestBody['startDate'] = startDate;
    }
    if (endDate != null) {
      requestBody['endDate'] = endDate;
    }

    final String jsonBody = jsonEncode(requestBody);

    final String responseStr = await _client.postAuthWithCompanyHeader(
      '/ledger',
      jsonBody,
      companyId,
      'POST'
    );
    return LedgerResponse.fromJson(jsonDecode(responseStr));
  }
}