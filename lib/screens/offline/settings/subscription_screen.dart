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
    await _saveUserAndCompanyAfterPayment(selectedPlan);
    final amount = selectedPlan['price'];
    final clientCorrelator = const Uuid().v4();

    return;
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
          amount: (amount as num).toDouble(),
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
        await _saveUserAndCompanyAfterPayment(selectedPlan);

        final statusResponseMap = await _ecocashService.checkStatus(clientCorrelator);
        final statusResponse = statusResponseMap['status'];

        if (statusResponse == 'COMPLETED') {
          // PAYMENT SUCCESSFUL - NOW SAVE USER AND COMPANY
          await _saveUserAndCompanyAfterPayment(selectedPlan);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment ${statusResponse['status'] ?? 'Failed'}'),
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
      User? savedUser = _loggedInUser;
      String password = _loggedInUser!.password!;
      // Save user to API
      if (_loggedInUser != null) {
        try {
          print('user: ${_loggedInUser!.toJson()}');
          final returnedUser = await _subscriptionService.saveVimbikaUser(_loggedInUser!);
          if (returnedUser != null) {
            savedUser = returnedUser;
            if (mounted) {
              setState(() {
                _loggedInUser = returnedUser;
              });
            }
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString(AppConstants.keyOfflineUserData, jsonEncode(returnedUser.toJson()));
          }
        } catch (e) {
          debugPrint('Error saving user to Vimbika after payment: $e');
        }
      }

      // Save company to API
      Company? company;
      Branch? branch;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      var currentCompany = await _companyService.getCompany();
      if (currentCompany != null && savedUser != null) {
        try {
          String? defaultBranchName;
          final String? offlineBranchJson = prefs.getString(AppConstants.keyOfflineBranch);
          if (offlineBranchJson != null) {
            try {
              final branchData = jsonDecode(offlineBranchJson);
              defaultBranchName = branchData['name'];
            } catch (e) {
              debugPrint('Error decoding offline branch for defaultBranch: $e');
            }
          }

          currentCompany = currentCompany.copyWith(
            // newOfflineUser: savedUser,
            defaultBranch: defaultBranchName,
            name: 'Vimbika Pro Test 3'
          );
          final response = await _companyService.saveCompany(currentCompany);
          if (response != null && response.containsKey('item')) {
            final savedCompany = Company.fromJson(response['item']);
            company = savedCompany;

            // Save currencies from response
            if (response.containsKey('currencies') && response['currencies'] != null) {
              final List<dynamic> currenciesData = response['currencies'];
              final List<String> currenciesJsonList = currenciesData.map((c) => jsonEncode(c)).toList();
              // await prefs.setStringList(AppConstants.keyCurrencies, currenciesJsonList);
              print('currenciesData: ${currenciesJsonList}');
              print('currencies: ${currenciesJsonList.length}');
              await prefs.setStringList(AppConstants.keyOfflineCurrencies, currenciesJsonList);
            }

            if (response.containsKey('branch') && response['branch'] != null) {
              branch = Branch.fromJson(response['branch']);
              await prefs.setString(AppConstants.keyOfflineBranch, jsonEncode(branch.toJson()));
            }
            await _companyService.saveOfflineCompany(savedCompany);

            // Attempt login to get JWT token for subsequent API calls
            await _attemptLogin(password);
          }else if(response != null && response.containsKey('duplicate')){

          }
        } catch (e) {
          company = await _companyService.getCompany();
          debugPrint('Error saving company to Vimbika after payment: $e');
        }
      }

      // Finalize subscription state
      if (mounted) {
        setState(() {
          _currentSubscription = _selectedSubscription!;
        });

        final SharedPreferences prefsForSub = await SharedPreferences.getInstance();
        await prefsForSub.setString(AppConstants.keySelectedSubscription, _selectedSubscription!);

        DateTime now = DateTime.now();
        DateTime subscriptionEndDate;
        final InventoryItem? subscriptionItem = selectedPlan['item'] as InventoryItem?;
        
        // Get base currency to add to inventoryItem/currency
        Currency? baseCurrency;
        final List<String> currenciesJson = prefs.getStringList(AppConstants.keyOfflineCurrencies) ?? [];
        if (currenciesJson.isNotEmpty) {
          final List<Currency> currencies = currenciesJson.map((e) => Currency.fromJson(jsonDecode(e))).toList();
          baseCurrency = currencies.cast<Currency?>().firstWhere(
            (c) => c?.isBaseCurrency == true,
            orElse: () => null,
          );
        }

        final InventoryItem? updatedSubscriptionItem = subscriptionItem?.copyWith(
          currency: baseCurrency,
          company: company,
        );

        if (updatedSubscriptionItem?.renewalInterval == 'MONTHLY') {
          subscriptionEndDate = DateTime(now.year, now.month + 1, now.day);
        } else if (subscriptionItem?.renewalInterval == 'QUARTERLY') {
          subscriptionEndDate = DateTime(now.year , now.month + 3, now.day);
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
        await prefs.setString(AppConstants.keySubscriptionEndDate, formattedEndDate);

        setState(() {
          _renewalDate = formattedEndDate;
        });

        Subscription currentSubscription = Subscription(
          name: _currentSubscription,
          renewalDate: formattedEndDate,
          subscription: updatedSubscriptionItem,
          active: true,
          company: company
        );

        final startOfDay = DateTime(now.year, now.month, now.day);
        final daysRemaining = subscriptionEndDate.difference(startOfDay).inDays;
        await prefs.setInt(AppConstants.keySubscriptionDaysRemaining, daysRemaining);
        await prefs.setString(AppConstants.keySubscriptions, jsonEncode(currentSubscription.toJson()));

        // Save currentSubscription to API via /subscription/save-pro
        try {
          final savedSubscription = await _subscriptionService.saveSubscriptionPro(currentSubscription);
          if (savedSubscription != null) {
            await prefs.setString(AppConstants.keySubscriptions, jsonEncode(savedSubscription.toJson()));
          }
        } catch (e) {
          debugPrint('Error saving subscription to Vimbika after payment: $e');
        }

        // Save all local branchstock to API as list
        try {
          final List<String> stockJsonList = prefs.getStringList(AppConstants.keyOfflineBranchStock) ?? [];
          if (stockJsonList.isNotEmpty && company != null && company.id != null) {
            final List<BranchStock> stocks = stockJsonList.map((s) => BranchStock.fromJson(jsonDecode(s))).toList();
            
            // Get base currency for inventory items
            Currency? baseCurrency;
            final List<String> currenciesJson = prefs.getStringList(AppConstants.keyOfflineCurrencies) ?? [];
            if (currenciesJson.isNotEmpty) {
              final List<Currency> currencies = currenciesJson.map((e) => Currency.fromJson(jsonDecode(e))).toList();
              baseCurrency = currencies.cast<Currency?>().firstWhere(
                (c) => c?.isBaseCurrency == true,
                orElse: () => null,
              );
            }

            final List<InventoryItem> items = stocks
                .where((s) => s.item != null)
                .map((s) => s.item!.copyWith(
                    quantity: s.stock,
                    company: company,
                    currency: s.item!.currency.value ?? baseCurrency,
                ))
                .toList();

            await _branchStockService.saveAllBranchStock(
              list: items,
              company: company,
              branch: branch ?? (stocks.isNotEmpty ? stocks.first.branch : null),
            );
          }
        } catch (e) {
          debugPrint('Error saving branch stocks to Vimbika after payment: $e');
        }

        print('saving banks');
        // Save all none-system created banks to API separately
        try {
          final List<String> bankJsonList = prefs.getStringList(AppConstants.keyOfflineBanks) ?? [];
          print(bankJsonList);
          print(company?.toJson());
          if (bankJsonList.isNotEmpty && company != null && company.id != null) {
            final List<Bank> banks = bankJsonList.map((s) => Bank.fromJson(jsonDecode(s))).toList();
            print('banks: ${banks.length}');
            final List<Bank> updatedBanks = [];

            // Get base currency for banks if they don't have one
            Currency? baseCurrency;
            final List<String> currenciesJson = prefs.getStringList(AppConstants.keyOfflineCurrencies) ?? [];
            if (currenciesJson.isNotEmpty) {
              final List<Currency> currencies = currenciesJson.map((e) => Currency.fromJson(jsonDecode(e))).toList();
              baseCurrency = currencies.cast<Currency?>().firstWhere(
                    (c) => c?.isBaseCurrency == true,
                orElse: () => null,
              );
            }
            print('baseCurrency: ${baseCurrency?.toJson()}');


            for (var bank in banks) {
              print('bank currency: ${bank.currency.value?.toJson()}');
              if (bank.isSystemCreated != true) {
                // Ensure bank has a currency
                final bankWithCurrency = Bank(
                  id: bank.id,
                  name: bank.name,
                  accountNumber: bank.accountNumber,
                  branch: bank.branch,
                  description: bank.description,
                  currency: baseCurrency ?? bank.currency.value,
                  isSystemCreated: bank.isSystemCreated,
                  bankName: bank.bankName,
                  dateCreated: bank.dateCreated,
                  dateModified: bank.dateModified,
                  createdByName: bank.createdByName,
                  modifiedByName: bank.modifiedByName,
                  version: bank.version,
                );

                final savedBank = await _bankService.saveBankWithCompany(bankWithCurrency, company.id!);
                if (savedBank != null) {
                  updatedBanks.add(savedBank);
                } else {
                  updatedBanks.add(bankWithCurrency);
                }
              } else {
                updatedBanks.add(bank);
              }
            }
            await prefs.setStringList(
              AppConstants.keyOfflineBanks,
              updatedBanks.map((b) => jsonEncode(b.toJson())).toList(),
            );
          }
        } catch (e) {
          debugPrint('Error saving banks to Vimbika after payment: $e');
        }

        // Save all none-system created payment methods to API separately
        try {
          final List<String> paymentTypeJsonList = prefs.getStringList(AppConstants.keyOfflinePaymentTypes) ?? [];
          if (paymentTypeJsonList.isNotEmpty && company != null && company.id != null) {
            final List<PaymentType> paymentTypes = paymentTypeJsonList.map((s) => PaymentType.fromJson(jsonDecode(s))).toList();
            final List<PaymentType> updatedPaymentTypes = [];

            // Get base currency for payment types if they don't have one
            Currency? baseCurrency;
            final List<String> currenciesJson = prefs.getStringList(AppConstants.keyOfflineCurrencies) ?? [];
            if (currenciesJson.isNotEmpty) {
              final List<Currency> currencies = currenciesJson.map((e) => Currency.fromJson(jsonDecode(e))).toList();
              baseCurrency = currencies.cast<Currency?>().firstWhere(
                    (c) => c?.isBaseCurrency == true,
                orElse: () => null,
              );
            }

            for (var pt in paymentTypes) {
              if (pt.isSystemCreated != true) {
                // Ensure payment type has a currency
                final ptWithCurrency = pt.copyWith(
                  currency:  baseCurrency ?? pt.currency.value ,
                );

                final savedPt = await _paymentTypeService.savePaymentTypeWithCompany(ptWithCurrency, company.id!);
                if (savedPt != null) {
                  updatedPaymentTypes.add(savedPt);
                } else {
                  updatedPaymentTypes.add(ptWithCurrency);
                }
              } else {
                updatedPaymentTypes.add(pt);
              }
            }
            await prefs.setStringList(
              AppConstants.keyOfflinePaymentTypes,
              updatedPaymentTypes.map((pt) => jsonEncode(pt.toJson())).toList(),
            );
          }
        } catch (e) {
          debugPrint('Error saving payment methods to Vimbika after payment: $e');
        }

        // Save all customers to API separately
        try {
          final List<String> customerJsonList = prefs.getStringList(AppConstants.keyOfflineCustomers) ?? [];
          if (customerJsonList.isNotEmpty && company != null && company.id != null) {
            final List<Customer> customers = customerJsonList.map((s) => Customer.fromJson(jsonDecode(s))).toList();
            final List<Customer> updatedCustomers = [];
            for (var customer in customers) {
              final customerWithBranch = customer.copyWith(
                company: company,
                branch: branch,
              );
              final savedCustomer = await _customerService.saveCustomerWithCompany(customerWithBranch, company.id!);
              updatedCustomers.add(savedCustomer);
            }
            await prefs.setStringList(
              AppConstants.keyOfflineCustomers,
              updatedCustomers.map((c) => jsonEncode(c.toJson())).toList(),
            );
          }
        } catch (e) {
          debugPrint('Error saving customers to Vimbika after payment: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upgrade successful! You are now on $_currentSubscription'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error finalizing upgrade: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error finalizing upgrade: $e'), backgroundColor: Colors.red),
      );
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
