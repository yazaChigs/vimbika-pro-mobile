import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/ecocash_charge_request.dart';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:vimbika_pro/model/subscription.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:vimbika_pro/services/ecocash_service.dart';
import 'package:vimbika_pro/services/subscription_service.dart';
import 'package:vimbika_pro/services/company_service.dart';
import 'package:vimbika_pro/services/branch_stock_service.dart';
import 'package:vimbika_pro/services/bank_service.dart';
import 'package:vimbika_pro/services/payment_type_service.dart';
import 'package:vimbika_pro/services/customer_service.dart';
import 'package:vimbika_pro/model/jwt_request_model.dart';
import 'package:vimbika_pro/services/base_http_client.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/model/bank.dart';
import 'package:vimbika_pro/model/payment_type.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Import for DateFormat
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import '../../../model/company.dart';
import '../../../model/customer.dart';
import '../../../model/currency.dart';
import '../../../model/company_sync_dto.dart';
import '../../../model/unit.dart';
import '../../../model/category.dart';
import '../../../model/tax.dart';
import '../../../model/supplier.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _currentSubscription = 'Free Tier';
  String? _selectedSubscription;
  String? _renewalDate; // Added state variable for renewal date
  final EcocashService _ecocashService = EcocashService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final CompanyService _companyService = CompanyService();
  final BranchStockService _branchStockService = BranchStockService();
  final BankService _bankService = BankService();
  final PaymentTypeService _paymentTypeService = PaymentTypeService();
  final CustomerService _customerService = CustomerService();
  final BaseHttpClient _client = BaseHttpClient();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false; // Added loading state
  bool _isFetchingSubscriptions = false;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  User? _loggedInUser;

  List<Map<String, dynamic>> _availableSubscriptions = [];
  List<Map<String, dynamic>> _proSubscriptions = [];
  bool _isFetchingProSubscriptions = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadSubscriptionDetails(); // Load subscription details including renewal date
    _fetchSubscriptions();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _phoneController.dispose();
    super.dispose();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
    // Initial check
    Connectivity().checkConnectivity().then(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    setState(() {
      _isOffline = results.isEmpty || results.contains(ConnectivityResult.none);
    });
    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Payments are disabled.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _loadUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOfflineUserData) ?? prefs.getString(AppConstants.keyOnlineUserData);
    if (userData != null) {
      setState(() {
        _loggedInUser = User.fromJson(jsonDecode(userData));
      });
    }
  }

  Future<void> _loadSubscriptionDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? selectedSubscription = prefs.getString(AppConstants.keySelectedSubscription);
    final String? subscriptionEndDate = prefs.getString(AppConstants.keySubscriptionEndDate);

    setState(() {
      if (selectedSubscription != null) {
        _currentSubscription = selectedSubscription;
      }
      _renewalDate = subscriptionEndDate;
    });
  }

  Future<void> _fetchSubscriptions() async {
    setState(() {
      _isFetchingSubscriptions = true;
    });
    try {
      final subscriptions = await _subscriptionService.getAvailableSubscriptions('OFFLINE');
      if (mounted) {
        setState(() {
          _availableSubscriptions = subscriptions.map((item) {
            return {
              'name': item.name,
              'price': item.sellingPrice,
              'displayPrice': '\$${item.sellingPrice} / month',
              'features': item.description?.split(',') ?? ['Basic POS'],
              'item': item,
            };
          }).toList();

          // If currently empty, you might want to add a default Free Tier if not returned by API
          if (_availableSubscriptions.isEmpty) {
            _availableSubscriptions = [
              {
                'name': 'Free Tier',
                'price': 0.0,
                'displayPrice': '\$0 / month',
                'features': ['Basic POS', '1 User', 'Limited Reporting', 'Offline Mode'],
              }
            ];
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching subscriptions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load subscriptions: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingSubscriptions = false;
        });
      }
    }
  }

  Future<void> _fetchProSubscriptions([void Function(void Function())? setDialogState]) async {
    if (setDialogState != null) {
      setDialogState(() {
        _isFetchingProSubscriptions = true;
      });
    } else {
      setState(() {
        _isFetchingProSubscriptions = true;
      });
    }
    try {
      final subscriptions = await _subscriptionService.getPublicSubscriptions('MAIN');
      print('subscriptions: ${subscriptions.length}');
      if (setDialogState != null) {
        setDialogState(() {
          _proSubscriptions = subscriptions.map((item) {
            return {
              'name': item.name,
              'price': item.sellingPrice,
              'displayPrice': '\$${item.sellingPrice} / ${item.renewalInterval}',
              'features': item.description?.split(',') ?? ['Pro Business Features'],
              'item': item,
            };
          }).toList();
        });
      } else {
        setState(() {
          _proSubscriptions = subscriptions.map((item) {
            return {
              'name': item.name,
              'price': item.sellingPrice,
              'displayPrice': '\$${item.sellingPrice} / ${item.renewalInterval}',
              'features': item.description?.split(',') ?? ['Pro Business Features'],
              'item': item,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching pro subscriptions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load Pro subscriptions: $e')),
        );
      }
    } finally {
      if (setDialogState != null) {
        setDialogState(() {
          _isFetchingProSubscriptions = false;
        });
      } else {
        setState(() {
          _isFetchingProSubscriptions = false;
        });
      }
    }
  }

  void _handlePayment() {
    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot proceed with payment while offline.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedSubscription == null || _selectedSubscription == _currentSubscription) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your EcoCash number to pay for the $_selectedSubscription plan.'),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (e.g., 263777222093)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                _initiatePayment();
              },
              child: const Text('Pay Now'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showUpgradeToProDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Check if we need to start fetching
            if (_proSubscriptions.isEmpty && !_isFetchingProSubscriptions) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchProSubscriptions(setDialogState);
              });
            }

            return AlertDialog(
              title: const Text('Select Vimbika Pro Plan'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Your data will now be stored in Vimbika cloud servers and can also be accessed via https://business.vimbika.co.zw',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    if (_isFetchingProSubscriptions)
                      const Center(child: CircularProgressIndicator())
                    else if (_proSubscriptions.isEmpty)
                      const Text('No Pro plans available at the moment.')
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _proSubscriptions.length,
                          itemBuilder: (context, index) {
                            final sub = _proSubscriptions[index];
                            final isSelected = _selectedSubscription == sub['name'];
                            return Card(
                              elevation: isSelected ? 4 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: isSelected ? AppTheme.vimbikaBlue : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ListTile(
                                title: Text(sub['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(sub['displayPrice']),
                                trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.vimbikaBlue) : null,
                                onTap: () {
                                  setDialogState(() {
                                    _selectedSubscription = sub['name'];
                                  });
                                  setState(() {
                                    _selectedSubscription = sub['name'];
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _selectedSubscription == null || _isOffline
                      ? null
                      : () {
                          Navigator.pop(context);
                          _showUpgradePaymentDialog();
                        },
                  child: const Text('Continue to Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUpgradePaymentDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Pro Upgrade'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your EcoCash number to upgrade to $_selectedSubscription.'),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number (e.g., 263777222093)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _initiateUpgradePayment();
              },
              child: const Text('Pay Now'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initiateUpgradePayment() async {
    setState(() {
      _isLoading = true;
    });

    final selectedPlan = _proSubscriptions.firstWhere((sub) => sub['name'] == _selectedSubscription);
    // await _saveUserAndCompanyAfterPayment(selectedPlan);
    final amount = selectedPlan['price'];
    final clientCorrelator = const Uuid().v4();

    // return;
    final request = EcocashChargeRequest(
      clientCorrelator: clientCorrelator,
      notifyUrl: 'https://demo.vimbika.africa/uat-vimbika/api/payments/ecocash/notification',
      referenceCode: 'VIMBIKA_PRO_${const Uuid().v4().substring(0, 8)}',
      tranType: 'MER',
      endUserId: _phoneController.text,
      remarks: 'Vimbika Pro Subscription Upgrade',
      transactionOperationStatus: 'Charged',
      paymentAmount: PaymentAmount(
        charginginformation: ChargingInformation(
          // amount: (amount as num).toDouble(),
          amount: 2.00,
          currency: 'USD',
          description: 'Vimbika Pro Subscription Upgrade',
        ),
        chargeMetaData: ChargeMetaData(
          channel: 'WEB',
          purchaseCategoryCode: 'Online Payment',
          onBeHalfOf: 'Vimbika Pro',
        ),
      ),
      merchantCode: '8003',
      merchantPin: '1234',
      merchantNumber: '789111401',
      currencyCode: 'USD',
      countryCode: 'ZW',
      terminalID: 'TERM123456',
      location: 'HARARE',
      superMerchantName: 'VIMBIKA',
      merchantName: 'Vimbika Pro',
    );

    try {
      final requestDto = {
        "ecocashChargeRequest": request,
        "subscriptionName": _selectedSubscription,
        "customer": Customer(
          name: (_loggedInUser?.userName ?? '').trim().isNotEmpty ? (_loggedInUser?.userName ?? '').trim() : 'Ecocash Subscriber',
          mobilePhone: _phoneController.text,
        ),
      };
      final response = await _ecocashService.initiatePayment(requestDto);

      if (response['transactionOperationStatus'] == 'PENDING SUBSCRIBER VALIDATION') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please approve the transaction on your phone.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        // await _saveUserAndCompanyAfterPayment(selectedPlan);

        final statusResponseMap = await _ecocashService.checkStatus(clientCorrelator);
        final statusResponse = statusResponseMap['status'];

        if (statusResponse == 'COMPLETED') {
          // PAYMENT SUCCESSFUL - NOW SAVE USER AND COMPANY
          await _saveUserAndCompanyAfterPayment(selectedPlan);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment ${statusResponse ?? 'Failed'}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: $response'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred during upgrade: $e'),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint('An error occurred during upgrade: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _attemptLogin(String pass) async {
    if (_loggedInUser == null) return;

    try {
      final username = _loggedInUser!.userName;
      final password = '1234';

      if (username != null && password != null) {
        final jwtRequest = JwtRequestModel(
          userName: username,
          password: password,
        );

        print('username: $username password: $password');

        final responseStr = await _client.post('/authentication', jsonEncode(jwtRequest.toJson()));
        final Map<String, dynamic> data = jsonDecode(responseStr);

        if (data.containsKey('token')) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(AppConstants.CACHED_ACCESS_TOKEN, data['token']);
          debugPrint('Auto-login successful after company save');
        }
      }
    } catch (e) {
      debugPrint('Auto-login failed: $e');
    }
  }

  Future<void> _saveUserAndCompanyAfterPayment(Map<String, dynamic> selectedPlan) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final User? savedUser = _loggedInUser;
      final String password = _loggedInUser!.password!;

      // Prepare company
      Company? company = await _companyService.getCompany();
      if (company == null || savedUser == null) {
        throw Exception('User or company not found');
      }
      Branch? branch;
      final String? offlineBranchJson = prefs.getString(AppConstants.keyOfflineBranch);
      if (offlineBranchJson != null) {
        try {
          final branchData = jsonDecode(offlineBranchJson);
          branch = Branch.fromJson(branchData);
        } catch (e) {
          debugPrint('Error decoding offline branch for defaultBranch: $e');
        }
      }

      // Prepare subscription
      DateTime now = DateTime.now();
      DateTime subscriptionEndDate;
      final InventoryItem? subscriptionItem = selectedPlan['item'] as InventoryItem?;
      final List<String> currenciesJson = prefs.getStringList(AppConstants.keyOfflineCurrencies) ?? [];
      Currency? baseCurrency;
      if (currenciesJson.isNotEmpty) {
        final List<Currency> currencies = currenciesJson.map((e) => Currency.fromJson(jsonDecode(e))).toList();
        baseCurrency = currencies.firstWhere((c) => c.isBaseCurrency == true, orElse: () => currencies.first);
      }
      final InventoryItem? updatedSubscriptionItem = subscriptionItem?.copyWith(
        currency: baseCurrency,
        company: company,
      );
      if (updatedSubscriptionItem?.renewalInterval == 'MONTHLY') {
        subscriptionEndDate = DateTime(now.year, now.month + 1, now.day);
      } else if (subscriptionItem?.renewalInterval == 'QUARTERLY') {
        subscriptionEndDate = DateTime(now.year, now.month + 3, now.day);
      } else if (subscriptionItem?.renewalInterval == 'HALF_YEARLY') {
        subscriptionEndDate = DateTime(now.year, now.month + 6, now.day);
      } else if (subscriptionItem?.renewalInterval == 'ANNUALLY') {
        subscriptionEndDate = DateTime(now.year + 1, now.month, now.day);
      } else if (subscriptionItem?.renewalInterval == 'DAILY') {
        subscriptionEndDate = now.add(const Duration(days: 1));
      } else {
        subscriptionEndDate = DateTime(now.year, now.month + 1, now.day);
      }
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final String formattedEndDate = formatter.format(subscriptionEndDate);
      Subscription currentSubscription = Subscription(
        name: _selectedSubscription!,
        renewalDate: formattedEndDate,
        subscription: updatedSubscriptionItem,
        active: true,
        company: company,
      );

      Supplier companySupplier = Supplier(
        id: company.id != null ? 'supplier_${company.id}' : const Uuid().v4(),
        name: company.name ?? '',
        email: company.email,
        phoneNumber: company.phoneNumber,
        address: company.address,
      );

      // Prepare Inventory Items from BranchStock
      final List<String> stockJsonList = prefs.getStringList(AppConstants.keyOfflineBranchStock) ?? [];
      final List<BranchStock> stocks = stockJsonList.map((s) => BranchStock.fromJson(jsonDecode(s))).toList();
      final List<InventoryItem> inventoryItems = stocks
          .where((s) => s.item.value != null)
          .map((s) {
            final item = s.item.value!;
            final updatedItem = item.copyWith(
              availableItems: s.stock, // The stock count from BranchStock becomes the quantity
              company: company,
              currency: item.currency.value ?? baseCurrency,
              supplier: item.supplier.value ?? companySupplier,
            );
            s.item.value = updatedItem;
            return updatedItem;
          })
          .toList();

      // Prepare other data
      final List<String> bankJsonList = prefs.getStringList(AppConstants.keyOfflineBanks) ?? [];
      final List<Bank> banks = bankJsonList.map((s) => Bank.fromJson(jsonDecode(s))).toList();
      final List<String> paymentTypeJsonList = prefs.getStringList(AppConstants.keyOfflinePaymentTypes) ?? [];
      final List<PaymentType> paymentTypes = paymentTypeJsonList.map((s) => PaymentType.fromJson(jsonDecode(s))).toList();
      final List<String> customerJsonList = prefs.getStringList(AppConstants.keyOfflineCustomers) ?? [];
      final List<Customer> customers = customerJsonList.map((s) => Customer.fromJson(jsonDecode(s))).toList();
      final List<Currency> currencies = currenciesJson.map((e) => Currency.fromJson(jsonDecode(e))).toList();
      final List<String> unitJsonList = prefs.getStringList(AppConstants.keyOfflineUnits) ?? [];
      final List<Unit> units = unitJsonList.map((s) => Unit.fromJson(jsonDecode(s))).toList();
      final List<String> categoryJsonList = prefs.getStringList(AppConstants.keyOfflineCategories) ?? [];
      final List<Category> categories = categoryJsonList.map((s) => Category.fromJson(jsonDecode(s))).toList();
      final List<String> taxJsonList = prefs.getStringList(AppConstants.keyOfflineTaxes) ?? [];
      final List<Tax> taxes = taxJsonList.map((s) => Tax.fromJson(jsonDecode(s))).toList();
      final List<String> supplierJsonList = prefs.getStringList(AppConstants.keyOfflineSuppliers) ?? prefs.getStringList(AppConstants.keySuppliers) ?? [];
      final List<Supplier> suppliers = supplierJsonList.map((s) => Supplier.fromJson(jsonDecode(s))).toList();
      suppliers.add(companySupplier);

      // Create DTO
      final companySyncDto = CompanySyncDto(
        user: savedUser,
        company: company,
        branch: branch!,
        subscription: currentSubscription,
        currencies: currencies,
        banks: banks,
        customers: customers,
        suppliers: suppliers,
        inventoryItems: inventoryItems,
        paymentTypes: paymentTypes,
        units: units,
        categories: categories,
        taxes: taxes,
      );

      // Make the API call
      final response = await _companyService.syncCompanyData(companySyncDto);

      // Process response
      if (response != null) {
        // Save updated data from response
        if (response['company'] != null) {
          final savedCompany = Company.fromJson(response['company']);
          await _companyService.saveOfflineCompany(savedCompany);
        }
        if (response.containsKey('branch') && response['branch'] != null) {
          final branch = Branch.fromJson(response['branch']);
          await prefs.setString(AppConstants.keyOfflineBranch, jsonEncode(branch.toJson()));
        }
        if (response.containsKey('currencies') && response['currencies'] != null) {
          final List<dynamic> currenciesData = response['currencies'];
          final List<String> currenciesJsonList = currenciesData.map((c) => jsonEncode(c)).toList();
          await prefs.setStringList(AppConstants.keyOfflineCurrencies, currenciesJsonList);
        }
        if (response.containsKey('banks') && response['banks'] != null) {
          final List<dynamic> banksData = response['banks'];
          final List<String> banksJsonList = banksData.map((c) => jsonEncode(c)).toList();
          await prefs.setStringList(AppConstants.keyOfflineBanks, banksJsonList);
        }
        if (response.containsKey('paymentTypes') && response['paymentTypes'] != null) {
          final List<dynamic> paymentTypesData = response['paymentTypes'];
          final List<String> paymentTypesJsonList = paymentTypesData.map((c) => jsonEncode(c)).toList();
          await prefs.setStringList(AppConstants.keyOfflinePaymentTypes, paymentTypesJsonList);
        }
        if (response.containsKey('customers') && response['customers'] != null) {
          final List<dynamic> customersData = response['customers'];
          final List<String> customersJsonList = customersData.map((c) => jsonEncode(c)).toList();
          await prefs.setStringList(AppConstants.keyOfflineCustomers, customersJsonList);
        }
        if (response.containsKey('inventoryItems') && response['inventoryItems'] != null) {
          final List<dynamic> inventoryItemsData = response['inventoryItems'];
          final List<String> inventoryItemsJsonList = inventoryItemsData.map((c) => jsonEncode(c)).toList();
          await prefs.setStringList(AppConstants.keyOfflineBranchStock, inventoryItemsJsonList);
        }
        if (response.containsKey('units') && response['units'] != null) {
          final List<dynamic> unitsData = response['units'];
          final List<String> unitsJsonList = unitsData.map((c) => jsonEncode(c)).toList();
          await prefs.setStringList(AppConstants.keyOfflineUnits, unitsJsonList);
        }
        if (response.containsKey('categories') && response['categories'] != null) {
          final List<dynamic> categoriesData = response['categories'];
          final List<String> categoriesJsonList = categoriesData.map((c) => jsonEncode(c)).toList();
          await prefs.setStringList(AppConstants.keyOfflineCategories, categoriesJsonList);
        }
        if (response.containsKey('taxes') && response['taxes'] != null) {
          final List<dynamic> taxesData = response['taxes'];
          final List<String> taxesJsonList = taxesData.map((c) => jsonEncode(c)).toList();
          await prefs.setStringList(AppConstants.keyOfflineTaxes, taxesJsonList);
        }
        if (response.containsKey('suppliers') && response['suppliers'] != null) {
          final List<dynamic> suppliersData = response['suppliers'];
          final List<String> suppliersJsonList = suppliersData.map((c) => jsonEncode(c)).toList();
          await prefs.setStringList(AppConstants.keyOfflineSuppliers, suppliersJsonList);
          // Also update the legacy key for backward compatibility if needed, 
          // though typically sync should transition to the new key.
          await prefs.setStringList(AppConstants.keySuppliers, suppliersJsonList);
        }
        if (response.containsKey('subscription') && response['subscription'] != null) {
          final savedSubscription = Subscription.fromJson(response['subscription']);
          await prefs.setString(AppConstants.keySubscriptions, jsonEncode(savedSubscription.toJson()));
        }
        if (response.containsKey('user') && response['user'] != null) {
          final returnedUser = User.fromJson(response['user']);
          if (mounted) {
            setState(() {
              _loggedInUser = returnedUser;
            });
          }
          await prefs.setString(AppConstants.keyOfflineUserData, jsonEncode(returnedUser.toJson()));
        }

        // Attempt login
        await _attemptLogin(password);

        // Update UI
        if (mounted) {
          setState(() {
            _currentSubscription = _selectedSubscription!;
            _renewalDate = formattedEndDate;
          });
          final SharedPreferences prefsForSub = await SharedPreferences.getInstance();
          await prefsForSub.setString(AppConstants.keySelectedSubscription, _selectedSubscription!);
          await prefsForSub.setString(AppConstants.keySubscriptionEndDate, formattedEndDate);
          final startOfDay = DateTime(now.year, now.month, now.day);
          final daysRemaining = subscriptionEndDate.difference(startOfDay).inDays;
          await prefs.setInt(AppConstants.keySubscriptionDaysRemaining, daysRemaining);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upgrade successful! You are now on $_currentSubscription'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to sync company data');
      }
    } catch (e) {
      debugPrint('Error finalizing upgrade: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finalizing upgrade: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });

    final selectedPlan = _availableSubscriptions.firstWhere((sub) => sub['name'] == _selectedSubscription);
    final amount = selectedPlan['price'];
    final clientCorrelator = const Uuid().v4();

    final request = EcocashChargeRequest(
      clientCorrelator: clientCorrelator,
      notifyUrl: 'https://demo.vimbika.africa/uat-vimbika/api/payments/ecocash/notification',
      referenceCode: 'VIMBIKA_${const Uuid().v4().substring(0, 8)}',
      tranType: 'MER',
      endUserId: _phoneController.text,
      remarks: 'Vimbika Pro Subscription',
      transactionOperationStatus: 'Charged',
      paymentAmount: PaymentAmount(
        charginginformation: ChargingInformation(
          amount: 2.00,
          currency: 'USD',
          description: 'Vimbika Pro Subscription',
        ),
        chargeMetaData: ChargeMetaData(
          channel: 'WEB',
          purchaseCategoryCode: 'Online Payment',
          onBeHalfOf: 'Vimbika Pro',
        ),
      ),
      merchantCode: '8003',
      merchantPin: '1234',
      merchantNumber: '789111401',
      currencyCode: 'USD',
      countryCode: 'ZW',
      terminalID: 'TERM123456',
      location: 'HARARE',
      superMerchantName: 'VIMBIKA',
      merchantName: 'Vimbika Pro',
    );

    try {
      final requestDto = {
        "ecocashChargeRequest": request,
        "subscriptionName": _selectedSubscription,
        "customer":Customer(
          name: (_loggedInUser?.userName ?? '').trim().isNotEmpty
              ? (_loggedInUser?.userName ?? '').trim()
              : 'Ecocash Subscriber',
          mobilePhone: _phoneController.text,
        ),
      };
      final response = await _ecocashService.initiatePayment(requestDto);

      if (response['transactionOperationStatus'] == 'PENDING SUBSCRIBER VALIDATION') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please approve the transaction on your phone.'),
            backgroundColor: Colors.orange,
          ),
        );
        // _ecocashService.charge(request);

        // Await the final status from the backend
        final statusResponseMap = await _ecocashService.checkStatus(clientCorrelator);
        final statusResponse = statusResponseMap['status'];

        if (statusResponse == 'COMPLETED') {
          if (mounted) {
            setState(() {
              _currentSubscription = _selectedSubscription!;
            });

            // Save selected subscription and end date to SharedPreferences
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString(AppConstants.keySelectedSubscription, _selectedSubscription!);

            DateTime now = DateTime.now();
            DateTime subscriptionEndDate;
            final InventoryItem? subscriptionItem = selectedPlan['item'] as InventoryItem?;

            if (subscriptionItem?.renewalInterval == 'MONTHLY') {
              subscriptionEndDate = DateTime(now.year, now.month + 1, now.day);
            } else if (subscriptionItem?.renewalInterval == 'ANNUALLY') {
              subscriptionEndDate = DateTime(now.year + 1, now.month, now.day);
            } else if (subscriptionItem?.renewalInterval == 'DAILY') {
              subscriptionEndDate = now.add(const Duration(days: 1));
            } else {
              // Default to 1 month if interval is not specified or unknown
              subscriptionEndDate = DateTime(now.year, now.month + 1, now.day);
            }

            final DateFormat formatter = DateFormat('yyyy-MM-dd');
            final String formattedEndDate = formatter.format(subscriptionEndDate);
            await prefs.setString(AppConstants.keySubscriptionEndDate, formattedEndDate);
            
            // Update the _renewalDate state variable
            setState(() {
              _renewalDate = formattedEndDate;
            });

            Subscription currentSubscription = Subscription(
              name: _currentSubscription,
              renewalDate: formattedEndDate,
              subscription: selectedPlan['item'],
              active: true,
            );

            final startOfDay = DateTime(now.year, now.month, now.day);
            final daysRemaining = subscriptionEndDate.difference(startOfDay).inDays;
            await prefs.setInt(AppConstants.keySubscriptionDaysRemaining, daysRemaining);
            await prefs.setString(AppConstants.keySubscriptions, jsonEncode(currentSubscription.toJson()));

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully subscribed to $_currentSubscription'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        } else if (statusResponse is String && (statusResponse == 'FAILED' ||
            statusResponse == 'CANCELLED' ||
            statusResponse == 'TIMEOUT' ||
            statusResponse == 'UNKNOWN_TRANSACTION')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment $statusResponse'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Handle any other unexpected status or if the backend returns PENDING for too long
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment status: $statusResponse. Please check your EcoCash app or try again later.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: $response'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Set loading to false
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Subscription', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.wifi_off, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Offline Mode: Payments are currently disabled. Please check your internet connection.',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: AppTheme.vimbikaBlue.withAlpha(20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Current Subscription',
                          style: TextStyle(fontSize: 14, color: AppTheme.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentSubscription,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue),
                        ),
                        if (_renewalDate != null && _currentSubscription != 'Free Tier') // Display renewal date if available and not Free Tier
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Renews on: $_renewalDate',
                              style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                            ),
                          ),
                      ],
                    ),
                    const Icon(Icons.verified, color: AppTheme.vimbikaBlue, size: 40),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Available Plans',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _isFetchingSubscriptions
                ? const Center(child: CircularProgressIndicator())
                : _availableSubscriptions.isEmpty
                    ? const Center(child: Text('No subscription plans available.'))
                    : Column(
                        children: _availableSubscriptions.map((sub) => _buildSubscriptionCard(sub)).toList(),
                      ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_selectedSubscription != null && _selectedSubscription != _currentSubscription && !_isLoading && !_isOffline)
                    ? _handlePayment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.vimbikaBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text(
                        'Make Payment & Switch Plan',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _showUpgradeToProDialog,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.vimbikaBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Upgrade to Pro',
                  style: TextStyle(color: AppTheme.vimbikaBlue, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> sub) {
    final isSelected = _selectedSubscription == sub['name'];
    final isCurrent = _currentSubscription == sub['name'];

    return GestureDetector(
      onTap: isCurrent || _isLoading // Disable tap if loading
          ? null
          : () {
              setState(() {
                _selectedSubscription = sub['name'];
              });
            },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppTheme.vimbikaBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    sub['name'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (isCurrent)
                    const Chip(
                      label: Text('Current', style: TextStyle(fontSize: 10, color: Colors.white)),
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                    )
                  else if (isSelected)
                    const Icon(Icons.check_circle, color: AppTheme.vimbikaBlue),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sub['displayPrice'],
                style: const TextStyle(fontSize: 16, color: AppTheme.vimbikaBlue, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (sub['features'] as List<String>).map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(feature, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
