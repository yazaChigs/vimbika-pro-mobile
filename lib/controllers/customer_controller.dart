import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart'; // Import for firstWhereOrNull

import '../app_constants/app_constants.dart';
import '../model/bank.dart'; // Import the Bank model
import '../model/currency.dart';
import '../model/customer.dart';
import '../model/customer_currency_amount.dart';
import '../model/mobile_pos_shift.dart';
import '../model/mobile_shift_currency_amount.dart';
import '../model/payment_received.dart';
import '../model/payment_type.dart';
import '../services/customer_service.dart';
import '../services/mobile_shift_service.dart';
import '../services/payments_service.dart';
import '../model/branch.dart'; // Import Branch model

class CustomerController extends ChangeNotifier {
  final CustomerService _customerService = CustomerService();
  final PaymentsService _paymentsService = PaymentsService();
  final MobilePosShiftService _shiftService = MobilePosShiftService();

  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  List<Currency> _currencies = [];
  List<PaymentType> _paymentTypes = [];
  bool _isLoading = false;
  String _searchQuery = '';
  bool _isDisposed = false;

  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;

  List<Customer> get customers => _customers;
  List<Customer> get filteredCustomers => _filteredCustomers;
  List<Currency> get currencies => _currencies;
  List<PaymentType> get paymentTypes => _paymentTypes;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  CustomerController() {
    _setupConnectivityListener();
    _loadData();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterCustomers();
     if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        debugPrint('Connectivity changed to online. Attempting to sync unsynced data.');
        _startPeriodicSyncCheck();
      } else {
        debugPrint('Connectivity changed to offline. Stopping periodic sync check.');
        _syncTimer?.cancel();
        _syncTimer = null;
      }
    });
  }

  Future<void> _loadData() async {
    _setLoading(true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    
    // For customers, offline customers and online customers use the same key but when online we can optionally fetch. 
    // Usually they are stored under AppConstants.keyCustomers
    // We get locally either way.
    _customers = await _customerService.getCustomersLocally();

    final String currencyKey = isOfflineMode ? AppConstants.keyOfflineCurrencies : AppConstants.keyCurrencies;
    final List<String> currencyJson = prefs.getStringList(currencyKey) ?? [];
    
    final String paymentTypeKey = isOfflineMode ? AppConstants.keyOfflinePaymentTypes : AppConstants.keyPaymentTypes;
    final List<String> paymentTypeJson = prefs.getStringList(paymentTypeKey) ?? [];
    
    _currencies = currencyJson.map((e) => Currency.fromJson(jsonDecode(e))).toList();
    _paymentTypes = paymentTypeJson
        .map((e) => PaymentType.fromJson(jsonDecode(e)))
        .where((pt) => pt.active)
        .toList();
    
    _filterCustomers();
    _setLoading(false);
  }

  Future<void> _startPeriodicSyncCheck() async {
    if (_syncTimer == null || !_syncTimer!.isActive) {
      await _attemptSyncUnsyncedData();

      // Check if there are still unsynced items after the initial attempt
      if ((await _customerService.getUnsyncedCustomers()).isNotEmpty || (await _paymentsService.getUnsyncedReceivedPaymentsLocally()).isNotEmpty) {
        debugPrint('Unsynced items found. Starting periodic sync check.');
        _syncTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
          _attemptSyncUnsyncedData();
        });
      }
    }
  }

  Future<bool> _checkConnectivity() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult.any((result) => result != ConnectivityResult.none);
  }

  Future<void> _attemptSyncUnsyncedData() async {
    bool isConnected = await _checkConnectivity();

    if (!isConnected) {
      debugPrint('Offline. Cannot sync unsynced data.');
      return;
    }

    // Sync unsynced customers
    List<Customer> unsyncedCustomers = await _customerService.getUnsyncedCustomers();
    if (unsyncedCustomers.isNotEmpty) {
      debugPrint('Attempting to sync ${unsyncedCustomers.length} unsynced customers...');
      for (Customer customer in unsyncedCustomers) {
        try {
          await _customerService.syncCustomer(customer);
        } catch (e) {
          debugPrint('Failed to sync customer "${customer.name}": $e');
        }
      }
    }

    // Sync unsynced payments
    List<PaymentReceived> unsyncedPayments = await _paymentsService.getUnsyncedReceivedPaymentsLocally();
    if (unsyncedPayments.isNotEmpty) {
      debugPrint('Attempting to sync ${unsyncedPayments.length} unsynced payments...');
      for (PaymentReceived payment in unsyncedPayments) {
        try {
          await _paymentsService.syncReceivedPayment(payment);
        } catch (e) {
          debugPrint('Failed to sync payment "${payment.id}": $e');
        }
      }
    }

    await _loadData(); // Reload data to update UI and re-evaluate unsynced count
    if ((await _customerService.getUnsyncedCustomers()).isEmpty && (await _paymentsService.getUnsyncedReceivedPaymentsLocally()).isEmpty) {
      debugPrint('All unsynced data synced. Stopping periodic sync check.');
      _syncTimer?.cancel();
      _syncTimer = null;
    }
  }

  Future<String?> syncCustomers() async {
    _setLoading(true);
    String? message;

    bool isConnected = await _checkConnectivity();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;

    if (!isConnected || isOfflineMode) {
      message = 'Offline mode or no internet connection. Displaying locally saved customers.';
      await _loadData();
    } else {
      await _attemptSyncUnsyncedData(); // Sync both customers and payments

      try {
        await _customerService.fetchCustomers();
        await _loadData();
        message = 'All customers updated from API';
      } catch (e) {
        message = 'Failed to fetch customers from API: $e. Displaying locally saved customers.';
        await _loadData();
      }
    }

    _setLoading(false);
    return message;
  }

  void _filterCustomers() {
    if (_searchQuery.isEmpty) {
      _filteredCustomers = _customers;
    } else {
      _filteredCustomers = _customers.where((customer) {
        final query = _searchQuery.toLowerCase();
        return customer.name.toLowerCase().contains(query) ||
               (customer.email?.toLowerCase().contains(query) ?? false) ||
               (customer.phoneNumber?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  }

  Future<MobilePosShift?> _getCurrentShift() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? currentShiftJson = prefs.getString(AppConstants.keyCurrentOpenShift);
    if (currentShiftJson != null && currentShiftJson.isNotEmpty && currentShiftJson != 'null') {
      try {
        return MobilePosShift.fromRawJson(currentShiftJson);
      } on FormatException catch (e) {
        debugPrint('Error decoding MobilePosShift from SharedPreferences: $e');
        return null;
      }
    }
    return null;
  }

  Future<Branch?> _getDefaultBranch() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? defaultBranchJson = prefs.getString(AppConstants.keyDefaultBranch);
    if (defaultBranchJson != null && defaultBranchJson.isNotEmpty) {
      try {
        return Branch.fromJson(jsonDecode(defaultBranchJson));
      } catch (e) {
        debugPrint('Error decoding default branch from SharedPreferences: $e');
        return null;
      }
    }
    return null;
  }

  Future<PaymentReceived?> addBalance(Customer customer, Currency selectedCurrency, PaymentType selectedPaymentType, double amount, {Bank? selectedBank, bool isDeposit = false}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Branch? defaultBranch = await _getDefaultBranch();
      final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
      
      final newPayment = PaymentReceived(
        paymentType: selectedPaymentType,
        payer: customer,
        currency: selectedCurrency,
        branch: defaultBranch ?? customer.branch, // Use defaultBranch if available, else customer.branch
        amount: amount,
        amountPaid: amount,
        paymentDescription: isDeposit ? 'CUSTOMER_DEPOSIT' : 'PAY_ACCOUNT',
        paymentDate:DateFormat('yyyy-MM-dd').format(DateTime.now()),
        dateTime:DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
        notes: isDeposit ? 'Customer deposit from mobile app' : 'Balance addition from mobile app',
        bank: selectedBank, // Pass the selected Bank object
        isMobile: true,
      );

      // --- Start of local balance update logic ---
      // We perform local operations first so the UI updates quickly whether online or offline
      // Find the customer in the local list
      int customerIndex = _customers.indexWhere((c) => c.id == customer.id);
      if (customerIndex != -1) {
        Customer currentLocalCustomer = _customers[customerIndex];
        List<CustomerCurrencyAmount> updatedCurrencyBalance = [];

        // Check if there's an existing balance for the selected currency
        CustomerCurrencyAmount? existingCca;
        if (currentLocalCustomer.currencyBalance != null) {
          existingCca = currentLocalCustomer.currencyBalance!.firstWhereOrNull(
            (cca) => cca.currency?.id == selectedCurrency.id,
          );
          updatedCurrencyBalance.addAll(currentLocalCustomer.currencyBalance!.where(
            (cca) => cca.currency?.id != selectedCurrency.id,
          ));
        }

        // Create or update the CustomerCurrencyAmount
        CustomerCurrencyAmount newCca;
        if (existingCca != null) {
          newCca = CustomerCurrencyAmount(
            id: existingCca.id,
            balance: (existingCca.balance ?? 0.0) + amount,
            currency: existingCca.currency,
            lastTranxDate: DateTime.now(), // Update last transaction date
            dateCreated: existingCca.dateCreated,
            dateModified:null,
            createdByName: existingCca.createdByName,
            modifiedByName: existingCca.modifiedByName,
            version: existingCca.version,
          );
        } else {
          // If no existing CCA, create a new one
          newCca = CustomerCurrencyAmount(
            id: 'local_cca_${DateTime.now().millisecondsSinceEpoch}', // Generate a local ID
            balance: amount,
            currency: selectedCurrency,
            lastTranxDate: DateTime.now(),
            dateCreated: null,
            dateModified: null,
            createdByName: 'Mobile App',
            modifiedByName: 'Mobile App',
            version: 1,
          );
        }
        updatedCurrencyBalance.add(newCca);

        // Create a new Customer object with the updated currencyBalance
        Customer updatedCustomer = Customer(
          id: currentLocalCustomer.id,
          dateCreated: currentLocalCustomer.dateCreated,
          dateModified: currentLocalCustomer.dateModified,
          createdByName: currentLocalCustomer.createdByName,
          modifiedByName: currentLocalCustomer.modifiedByName,
          version: currentLocalCustomer.version,
          name: currentLocalCustomer.name,
          email: currentLocalCustomer.email,
          phoneNumber: currentLocalCustomer.phoneNumber,
          address: currentLocalCustomer.address,
          accountNumber: currentLocalCustomer.accountNumber,
          taxNumber: currentLocalCustomer.taxNumber,
          tinNumber: currentLocalCustomer.tinNumber,
          currencyBalance: updatedCurrencyBalance, // Use the new list
          company: currentLocalCustomer.company,
          branch: currentLocalCustomer.branch,
          isSynced: currentLocalCustomer.isSynced, // Keep original sync status
        );

        // Replace the old customer with the updated one
        _customers[customerIndex] = updatedCustomer;
        await _customerService.saveCustomerLocally(updatedCustomer); // Persist local change
        _filterCustomers(); // Re-filter to update UI if search query is active
        if (!_isDisposed) {
          notifyListeners(); // Notify listeners about the change
        }
      }
      // --- End of local balance update logic ---

      // Always save locally first to be safe, especially in offline mode. 
      // The `savePaymentReceived` method in PaymentsService already handles online vs offline 
      // by saving locally if the sync fails, but we can also just rely on it.
      final savedPayment = await _paymentsService.savePaymentReceived(newPayment);
      
      if (!isOfflineMode) {
         // We are online. Delegate directly to the service to handle the API call.
         // Wait a tiny bit just in case we need the local customer save to finish
        // Refresh customer list from API to get updated balance if we successfully synced.
        // Even if we fail, local is updated, but syncCustomers will fetch from API and overwrite local.
        // It's probably better to call _startPeriodicSyncCheck here and let background sync handle it,
        // but if we want instant feedback, we can call syncCustomers.
        await syncCustomers(); 
      }

      final MobilePosShift? currentShift = await _getCurrentShift();
      if (currentShift != null && !(currentShift.isShiftClosed ?? true)) {
        final MobileShiftCurrencyAmount shiftAmount = MobileShiftCurrencyAmount(
          id: null,
          timeCreated: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
          active: true,
          currency: selectedCurrency,
          amount: amount,
          notes: isDeposit ? 'Customer Deposit for ${customer.name}' : 'Account Top-up for ${customer.name}',
          amountType: isDeposit ? 'CUSTOMER_DEPOSIT' : 'ACCOUNT_TOP_UP',
          // If online, it's possible savedPayment has no ID yet until synced back, fallback to generated. 
          // Assuming savePaymentReceived returns a valid object or we use local ID
          ref: savedPayment.id ?? 'payment_${DateTime.now().millisecondsSinceEpoch}',
          posReference: '${customer.name}${DateTime.now().microsecondsSinceEpoch}',
          shiftReference: currentShift.shiftReference,
          isCash: selectedPaymentType.isCash,
          paymentType: selectedPaymentType.name,
          bankName: selectedBank?.name, // Pass the selected bank's name
        );
        currentShift.shiftCurrencyAmounts ??= [];
        currentShift.shiftCurrencyAmounts!.add(shiftAmount);

        await prefs.setString(AppConstants.keyCurrentOpenShift, currentShift.toJson());
        _shiftService.createShift(currentShift).catchError((e) {
          debugPrint('Failed to sync shift with API: $e');
          return currentShift;
        });
      }
      return savedPayment;
    } catch (e) {
      debugPrint('Failed to add balance: $e');
      return null;
    }
  }
  
  Future<PaymentReceived?> addDeposit(Customer customer, Currency selectedCurrency, PaymentType selectedPaymentType, double amount, {Bank? selectedBank}) async {
    return addBalance(customer, selectedCurrency, selectedPaymentType, amount, selectedBank: selectedBank, isDeposit: true);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
