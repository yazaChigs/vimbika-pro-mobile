import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_constants/app_constants.dart';
import '../model/customer.dart';
import '../model/user.dart';
import 'base_http_client.dart';

class CustomerService {
  final BaseHttpClient _client = BaseHttpClient();

  // Fetches customers from API and saves them locally, marking them as synced
  Future<List<Customer>> fetchCustomers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.branch?.company?.id;
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
    List<Customer> unsyncedCustomers = localCustomers.where((c) => !c.isSynced).toList();

    List<Customer> allCustomersToSave = [...customers, ...unsyncedCustomers];
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    // We only fetch when online, but let's be safe. We save online customers to the general customer key.
    if (!isOfflineMode) {
      await prefs.setStringList(AppConstants.keyCustomers, allCustomersToSave.map((c) => jsonEncode(c.toJson())).toList());
    }
    
    return allCustomersToSave;
  }

  // Saves a customer to the API
  Future<Customer> saveCustomer(Customer customer) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);
    
    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));
    
    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    // Ensure the customer being sent to API has isSynced: true for consistency
    // The API doesn't care about this flag, but it's good practice for the model.
    final Customer customerToSend = customer.copyWith(isSynced: true);

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

  // Saves or updates a customer in local storage (SharedPreferences)
  Future<void> saveCustomerLocally(Customer customer) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Customer> customers = await getCustomersLocally();

    int index = customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      customers[index] = customer; // Update existing customer
    } else {
      customers.add(customer); // Add new customer
    }

    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    final String customerKey = isOfflineMode ? AppConstants.keyOfflineCustomers : AppConstants.keyCustomers;
    await prefs.setStringList(customerKey, customers.map((c) => jsonEncode(c.toJson())).toList());
  }

  // Retrieves all customers from local storage
  Future<List<Customer>> getCustomersLocally() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    final String customerKey = isOfflineMode ? AppConstants.keyOfflineCustomers : AppConstants.keyCustomers;
    final List<String> customersJson = prefs.getStringList(customerKey) ?? [];
    return customersJson.map((json) => Customer.fromJson(jsonDecode(json))).toList();
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
      
      // Update the locally stored customer with the API response (new ID, isSynced: true)
      await removeCustomerLocally(unsyncedCustomer.id!); // Remove old unsynced entry
      await saveCustomerLocally(apiCustomer.copyWith(isSynced: true)); // Save the new synced entry
      
      return apiCustomer;
    } catch (e) {
      // If API sync fails, re-throw to indicate failure
      rethrow;
    }
  }

  // Removes a customer from local storage by ID
  Future<void> removeCustomerLocally(String customerId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Customer> customers = await getCustomersLocally();
    customers.removeWhere((c) => c.id == customerId);
    
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    final String customerKey = isOfflineMode ? AppConstants.keyOfflineCustomers : AppConstants.keyCustomers;

    await prefs.setStringList(customerKey, customers.map((c) => jsonEncode(c.toJson())).toList());
  }
}
