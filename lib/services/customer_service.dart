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
  final BaseHttpClient _client = BaseHttpClient();

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
      String key = c.id ?? 'name_${c.name.toLowerCase()}';
      mergedCustomers[key] = c;
    }
    
    // Add/Update with newly fetched customers from API
    for (var c in customers) {
      if (c.id != null) {
        // Find existing by ID or Name
        String? existingKey = mergedCustomers.containsKey(c.id) 
            ? c.id 
            : mergedCustomers.keys.firstWhereOrNull((k) => 
                mergedCustomers[k]!.name.toLowerCase() == c.name.toLowerCase()
              );

        if (existingKey == null) {
          mergedCustomers[c.id!] = c;
        } else {
          final existing = mergedCustomers[existingKey]!;
          // Only overwrite if the local version is already synced
          if (existing.isSynced) {
            // If ID changed (null -> real ID), remove old name-based key
            if (existing.id == null) {
              mergedCustomers.remove(existingKey);
            }
            mergedCustomers[c.id!] = c;
          }
        }
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

    final Customer savedCustomer = Customer.fromJson(jsonDecode(responseStr));
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

    final Customer savedCustomer = Customer.fromJson(jsonDecode(responseStr));
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
      int index = customers.indexWhere((c) =>
          (updatedCustomer.id != null && c.id == updatedCustomer.id) ||
          (updatedCustomer.id == null &&
              c.id == null &&
              c.name == updatedCustomer.name));
      if (index != -1) {
        customers[index] = updatedCustomer;
      } else {
        customers.add(updatedCustomer);
      }
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
      // Attempt to save to API
      final Customer apiCustomer = await saveCustomer(unsyncedCustomer);
      final Customer syncedCustomer = apiCustomer.copyWith(isSynced: true);

      // Update the locally stored customer with the API response (new ID, isSynced: true)
      // We remove by the OLD ID and then save the NEW one.
      // saveCustomersLocally will handle merging and cleaning up other buckets.
      // if (unsyncedCustomer.id != null) {
      //   await removeCustomerLocally(unsyncedCustomer.id!);
      // } // COMMENTED SO THAT CLIENT DOESNT IMMEDIATELY DISAPPEAR AFTER ADDING DEPOSIT
      await saveCustomerLocally(syncedCustomer.copyWith(isSynced: true));

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
