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
import 'package:vimbika_pro/services/app_exceptions.dart';
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
import '../../../utils/license_key_formatter.dart';

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
  final TextEditingController _licenseKeyController = TextEditingController();
  bool _isLoading = false; // Added loading state
  bool _isRedeemingKey = false;
  bool _isFetchingSubscriptions = false;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  User? _loggedInUser;

  bool _hasPendingUpgrade = false;
  Map<String, dynamic>? _pendingUpgradePlan;
  String? _pendingUpgradeCorrelator;

  List<Map<String, dynamic>> _availableSubscriptions = [];
  List<Map<String, dynamic>> _proSubscriptions = [];
  bool _isFetchingProSubscriptions = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadSubscriptionDetails(); // Load subscription details including renewal date
    _checkPendingUpgrade();
    _fetchSubscriptions();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _phoneController.dispose();
    _licenseKeyController.dispose();
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

  DateTime? _tryParseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is DateTime) return dateValue;
    if (dateValue is int) {
      if (dateValue > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(dateValue * 1000);
      }
    }
    final String str = dateValue.toString().trim();
    if (str.isEmpty) return null;

    final int? timestamp = int.tryParse(str);
    if (timestamp != null) {
      if (timestamp > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    }

    final parsedIso = DateTime.tryParse(str);
    if (parsedIso != null) return parsedIso;

    try {
      if (str.contains('/')) {
        final parts = str.split('/');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          } else if (parts[2].length == 4) {
            return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        }
      }
    } catch (_) {}

    return null;
  }

  DateTime _calculateIncreasedRenewalDate({
    DateTime? currentExpiry,
    DateTime? serverDate,
    String? interval,
    int? durationDays,
  }) {
    final DateTime now = DateTime.now();
    final DateTime baseDate = (currentExpiry != null && currentExpiry.isAfter(now))
        ? currentExpiry
        : now;

    DateTime calculatedDate;
    final String upperInterval = (interval ?? '').toUpperCase();
    if (upperInterval == 'ANNUALLY' || upperInterval == 'YEARLY') {
      calculatedDate = DateTime(baseDate.year + 1, baseDate.month, baseDate.day);
    } else if (upperInterval == 'QUARTERLY') {
      calculatedDate = DateTime(baseDate.year, baseDate.month + 3, baseDate.day);
    } else if (upperInterval == 'HALF_YEARLY' || upperInterval == 'SEMI_ANNUALLY') {
      calculatedDate = DateTime(baseDate.year, baseDate.month + 6, baseDate.day);
    } else if (upperInterval == 'WEEKLY') {
      calculatedDate = baseDate.add(const Duration(days: 7));
    } else if (upperInterval == 'DAILY') {
      calculatedDate = baseDate.add(const Duration(days: 1));
    } else if (durationDays != null && durationDays > 0) {
      calculatedDate = baseDate.add(Duration(days: durationDays));
    } else {
      // Default to 1 month extension
      calculatedDate = DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
    }

    if (serverDate != null && serverDate.isAfter(calculatedDate)) {
      return serverDate;
    }
    if (serverDate != null && serverDate.isAfter(baseDate)) {
      return serverDate;
    }
    return calculatedDate;
  }

  Future<void> _loadSubscriptionDetails() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? selectedSubscription = prefs.getString(AppConstants.keySelectedSubscription);
    String? subscriptionEndDate = prefs.getString(AppConstants.keySubscriptionEndDate);

    if (subscriptionEndDate == null || subscriptionEndDate.isEmpty) {
      final String? subsJson = prefs.getString(AppConstants.keyOfflineSubscriptions) ??
          prefs.getString(AppConstants.keySubscriptions);
      if (subsJson != null) {
        try {
          final decoded = jsonDecode(subsJson);
          if (decoded is List && decoded.isNotEmpty) {
            final sub = Subscription.fromMap(decoded.first);
            subscriptionEndDate = sub.renewalDate;
          } else if (decoded is Map<String, dynamic>) {
            final sub = Subscription.fromMap(decoded);
            subscriptionEndDate = sub.renewalDate;
          }
        } catch (_) {}
      }
    }

    setState(() {
      if (selectedSubscription != null) {
        _currentSubscription = selectedSubscription;
      }
      _renewalDate = subscriptionEndDate;
    });

    await _checkPendingUpgrade();
  }

  Future<void> _checkPendingUpgrade() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isPaid = prefs.getBool(AppConstants.keyPendingUpgradePaid) ?? false;
    final String? correlator = prefs.getString(AppConstants.keyPendingUpgradeCorrelator);
    final String? planJson = prefs.getString(AppConstants.keyPendingUpgradePlan);

    if (isPaid && correlator != null) {
      Map<String, dynamic>? planMap;
      if (planJson != null) {
        try {
          planMap = jsonDecode(planJson);
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _hasPendingUpgrade = true;
          _pendingUpgradeCorrelator = correlator;
          _pendingUpgradePlan = planMap;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasPendingUpgrade = false;
          _pendingUpgradeCorrelator = null;
          _pendingUpgradePlan = null;
        });
      }
    }
  }

  Future<void> _resumePendingUpgrade() async {
    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot complete upgrade while offline. Please connect to the internet.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      Map<String, dynamic>? plan = _pendingUpgradePlan;
      if (plan == null) {
        final String? planJson = prefs.getString(AppConstants.keyPendingUpgradePlan);
        if (planJson != null) {
          try {
            plan = jsonDecode(planJson);
          } catch (_) {}
        }
      }

      if (plan == null && _proSubscriptions.isNotEmpty) {
        for (final sub in _proSubscriptions) {
          if (sub['name'] == _selectedSubscription) {
            plan = Map<String, dynamic>.from(sub);
            break;
          }
        }
        plan ??= Map<String, dynamic>.from(_proSubscriptions.first);
      }

      plan ??= {
        'name': _selectedSubscription ?? 'Pro Plan',
        'price': 2.00,
      };

      final success = await _saveUserAndCompanyAfterPayment(plan);
      if (success) {
        await prefs.remove(AppConstants.keyPendingUpgradeCorrelator);
        await prefs.remove(AppConstants.keyPendingUpgradePlan);
        await prefs.remove(AppConstants.keyPendingUpgradePaid);
        if (mounted) {
          setState(() {
            _hasPendingUpgrade = false;
            _pendingUpgradeCorrelator = null;
            _pendingUpgradePlan = null;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Upgrade setup failed. Your payment is preserved, please tap "Complete Upgrade Now" to retry.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error resuming pending upgrade: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upgrade setup failed: $e. Your payment is preserved, you can retry anytime without repaying.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

  Future<void> _fetchSubscriptions() async {
    setState(() {
      _isFetchingSubscriptions = true;
    });
    try {
      final subscriptions = await _subscriptionService.getAvailableSubscriptions('OFFLINE');
      if (mounted) {
        setState(() {
          _availableSubscriptions = subscriptions.map<Map<String, dynamic>>((item) {
            return <String, dynamic>{
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
              <String, dynamic>{
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
      if (setDialogState != null) {
        setDialogState(() {
          _proSubscriptions = subscriptions.map<Map<String, dynamic>>((item) {
            return <String, dynamic>{
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
          _proSubscriptions = subscriptions.map<Map<String, dynamic>>((item) {
            return <String, dynamic>{
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

  void _showRedeemKeyDialog({String availability = 'OFFLINE'}) {
    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot redeem license key while offline. Please connect to the internet.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String? dialogError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: const [
                  Icon(Icons.vpn_key_rounded, color: AppTheme.vimbikaBlue),
                  SizedBox(width: 8),
                  Text('Redeem License Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your license key or voucher code to renew or upgrade your subscription plan.',
                      style: TextStyle(fontSize: 13, color: AppTheme.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _licenseKeyController,
                      textCapitalization: TextCapitalization.characters,
                      autofocus: true,
                      inputFormatters: [
                        LicenseKeyInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        labelText: 'License Key Code',
                        hintText: 'e.g. ABCD-1234-EFGH-5678',
                        prefixIcon: const Icon(Icons.key, color: AppTheme.vimbikaBlue),
                        suffixIcon: _licenseKeyController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setDialogState(() {
                                    _licenseKeyController.clear();
                                    dialogError = null;
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppTheme.vimbikaBlue, width: 2),
                        ),
                      ),
                      onChanged: (_) {
                        setDialogState(() {
                          dialogError = null;
                        });
                      },
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dialogError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isRedeemingKey ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (_isRedeemingKey || _licenseKeyController.text.trim().isEmpty)
                      ? null
                      : () async {
                          await _redeemLicenseKey(
                            _licenseKeyController.text,
                            setDialogState,
                            availability: availability,
                            onError: (msg) {
                              setDialogState(() {
                                dialogError = msg;
                              });
                            },
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vimbikaBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isRedeemingKey
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Redeem Key'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _redeemLicenseKey(
    String keyCode,
    void Function(void Function()) setDialogState, {
    String availability = 'OFFLINE',
    void Function(String)? onError,
  }) async {
    final trimmedKey = keyCode.trim().toUpperCase().replaceAll(RegExp(r'-+$'), '');
    if (trimmedKey.isEmpty) {
      if (onError != null) {
        onError('Please enter a license key');
      }
      return;
    }

    if (_isOffline) {
      if (onError != null) {
        onError('No internet connection. Please connect to redeem key.');
      }
      return;
    }

    setDialogState(() {
      _isRedeemingKey = true;
    });

    try {
      final Company? company = await _companyService.getCompany();
      final String? companyId = company?.id ?? _loggedInUser?.companyId;

      final response = await _subscriptionService.redeemLicenseKey(
        trimmedKey,
        companyId: companyId,
        availability: availability,
      );

      Map<String, dynamic>? subMap;
      if (response['subscription'] is Map<String, dynamic>) {
        subMap = response['subscription'] as Map<String, dynamic>;
      } else if (response['data'] is Map<String, dynamic>) {
        if (response['data']['subscription'] is Map<String, dynamic>) {
          subMap = response['data']['subscription'] as Map<String, dynamic>;
        } else {
          subMap = response['data'] as Map<String, dynamic>;
        }
      } else if (response['license'] is Map<String, dynamic>) {
        if (response['license']['subscription'] is Map<String, dynamic>) {
          subMap = response['license']['subscription'] as Map<String, dynamic>;
        } else {
          subMap = response['license'] as Map<String, dynamic>;
        }
      } else if (response['status'] == 'SUCCESS' || response['status'] == 'OK' || response['statusCode'] == 200) {
        subMap = response;
      } else if (response.containsKey('renewalDate') || response.containsKey('name') || response.containsKey('id')) {
        subMap = response;
      }

      if (subMap != null) {
        final Subscription updatedSub = Subscription.fromJson(subMap);
        final String planName = (updatedSub.subscription?.name ?? updatedSub.name).trim();

        final dynamic rawDate = subMap['renewalDate'] ??
            subMap['renewal_date'] ??
            subMap['endDate'] ??
            subMap['end_date'] ??
            subMap['expiryDate'] ??
            subMap['expiry_date'] ??
            subMap['expirationDate'] ??
            response['renewalDate'] ??
            response['renewal_date'] ??
            response['endDate'] ??
            response['expiryDate'] ??
            (response['license'] is Map ? response['license']['expiryDate'] ?? response['license']['renewalDate'] : null);

        final DateTime? serverRenewalDate = _tryParseDate(rawDate) ?? updatedSub.getRenewalDate();

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        DateTime? currentRenewalDateTime;
        if (_renewalDate != null) {
          currentRenewalDateTime = _tryParseDate(_renewalDate);
        }
        if (currentRenewalDateTime == null) {
          final String? savedEndDate = prefs.getString(AppConstants.keySubscriptionEndDate);
          if (savedEndDate != null) {
            currentRenewalDateTime = _tryParseDate(savedEndDate);
          }
        }

        final String? interval = updatedSub.subscription?.renewalInterval ??
            (subMap['subscription'] is Map ? subMap['subscription']['renewalInterval']?.toString() : null) ??
            subMap['renewalInterval']?.toString();

        final int? durationDays = (subMap['durationDays'] as num?)?.toInt() ??
            (subMap['duration'] as num?)?.toInt() ??
            (response['license'] is Map ? (response['license']['durationDays'] as num?)?.toInt() : null);

        final DateTime finalRenewalDateTime = _calculateIncreasedRenewalDate(
          currentExpiry: currentRenewalDateTime,
          serverDate: serverRenewalDate,
          interval: interval,
          durationDays: durationDays,
        );

        final DateFormat formatter = DateFormat('yyyy-MM-dd');
        final String formattedRenewalDate = formatter.format(finalRenewalDateTime);

        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final int daysRemaining = finalRenewalDateTime.difference(startOfDay).inDays;

        final Subscription finalSub = updatedSub.copyWith(
          name: planName.isNotEmpty ? planName : (updatedSub.name.isNotEmpty ? updatedSub.name : 'Pro Plan'),
          renewalDate: formattedRenewalDate,
          active: true,
        );

        final String finalPlanName = planName.isNotEmpty ? planName : _currentSubscription;

        if (finalPlanName.isNotEmpty) {
          await prefs.setString(AppConstants.keySelectedSubscription, finalPlanName);
        }
        await prefs.setString(AppConstants.keySubscriptionEndDate, formattedRenewalDate);
        await prefs.setInt(AppConstants.keySubscriptionDaysRemaining, daysRemaining);
        await prefs.setString(AppConstants.keySubscriptions, jsonEncode([finalSub.toJson()]));
        await prefs.setString(AppConstants.keyOfflineSubscriptions, jsonEncode([finalSub.toJson()]));

        if (mounted) {
          setState(() {
            if (finalPlanName.isNotEmpty) {
              _currentSubscription = finalPlanName;
            }
            _renewalDate = formattedRenewalDate;
          });

          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          _licenseKeyController.clear();

          if (availability.toUpperCase() == 'PUBLIC') {
            final planMap = {
              'name': finalPlanName.isNotEmpty ? finalPlanName : 'Pro Plan',
              'item': finalSub.subscription,
              'price': finalSub.renewalAmount ?? finalSub.subscription?.sellingPrice ?? 0,
              'renewalDate': formattedRenewalDate,
            };
            await _saveUserAndCompanyAfterPayment(planMap);
          } else {
            final String successMsg = response['message']?.toString() ??
                'License key redeemed successfully. Subscription extended until $_renewalDate';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMsg),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } else {
        final String errorMsg = response['message']?.toString() ??
            response['error']?.toString() ??
            response['errorMessage']?.toString() ??
            'Failed to redeem license key';
        if (onError != null) {
          onError(errorMsg);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Error redeeming license key: $e');
      String errorMessage = 'Failed to redeem license key';
      String? rawErrorStr;
      if (e is AppException && e.message != null && e.message!.isNotEmpty) {
        rawErrorStr = e.message;
      } else {
        rawErrorStr = e.toString();
      }

      if (rawErrorStr != null) {
        rawErrorStr = rawErrorStr.trim();
        if (rawErrorStr.startsWith('Exception:')) {
          rawErrorStr = rawErrorStr.substring(10).trim();
        }
        if (rawErrorStr.startsWith('Bad Request:')) {
          rawErrorStr = rawErrorStr.substring(12).trim();
        }
        if (rawErrorStr.startsWith('Unable to process:')) {
          rawErrorStr = rawErrorStr.substring(18).trim();
        }

        try {
          final int jsonStart = rawErrorStr.indexOf('{');
          final int jsonEnd = rawErrorStr.lastIndexOf('}');
          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonSub = rawErrorStr.substring(jsonStart, jsonEnd + 1);
            final decoded = jsonDecode(jsonSub);
            if (decoded is Map) {
              if (decoded.containsKey('message') && decoded['message'] != null && decoded['message'].toString().isNotEmpty) {
                errorMessage = decoded['message'].toString();
              } else if (decoded.containsKey('error') && decoded['error'] != null && decoded['error'].toString().isNotEmpty) {
                errorMessage = decoded['error'].toString();
              } else if (decoded.containsKey('errorMessage') && decoded['errorMessage'] != null && decoded['errorMessage'].toString().isNotEmpty) {
                errorMessage = decoded['errorMessage'].toString();
              } else {
                errorMessage = jsonSub;
              }
            } else {
              errorMessage = rawErrorStr;
            }
          } else {
            errorMessage = rawErrorStr;
          }
        } catch (_) {
          errorMessage = rawErrorStr;
        }
      }

      if (onError != null) {
        onError(errorMessage);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setDialogState(() {
        _isRedeemingKey = false;
      });
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
                TextButton(
                  onPressed: _isOffline
                      ? null
                      : () {
                          Navigator.pop(context);
                          _showRedeemKeyDialog(availability: 'PUBLIC');
                        },
                  child: const Text('Redeem Key'),
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
    if (_hasPendingUpgrade) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Upgrade Payment Already Recorded'),
            content: Text(
              'A successful payment for ${_pendingUpgradePlan?['name'] ?? _selectedSubscription ?? 'Pro Plan'} is already verified on this device. You do not need to pay again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resumePendingUpgrade();
                },
                child: const Text('Complete Upgrade Now'),
              ),
            ],
          );
        },
      );
      return;
    }

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
    if (_hasPendingUpgrade) {
      await _resumePendingUpgrade();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic>? plan;
    for (final sub in _proSubscriptions) {
      if (sub['name'] == _selectedSubscription) {
        plan = Map<String, dynamic>.from(sub);
        break;
      }
    }
    final Map<String, dynamic> selectedPlan = plan ?? <String, dynamic>{
      'name': _selectedSubscription ?? 'Pro Plan',
      'price': 2.00,
    };
    final amount = selectedPlan['price'] ?? 2.00;
    final clientCorrelator = const Uuid().v4();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyPendingUpgradeCorrelator, clientCorrelator);
    await prefs.setString(AppConstants.keyPendingUpgradePlan, jsonEncode(selectedPlan));
    await prefs.setBool(AppConstants.keyPendingUpgradePaid, false);

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

        final statusResponseMap = await _ecocashService.checkStatus(clientCorrelator);
        final statusResponse = statusResponseMap['status'];

        if (statusResponse == 'COMPLETED') {
          // PAYMENT SUCCESSFUL - RECORD THAT PAYMENT WAS COMPLETED
          await prefs.setBool(AppConstants.keyPendingUpgradePaid, true);
          if (mounted) {
            setState(() {
              _hasPendingUpgrade = true;
              _pendingUpgradeCorrelator = clientCorrelator;
              _pendingUpgradePlan = selectedPlan;
            });
          }

          // NOW ATTEMPT TO SAVE USER AND COMPANY
          final success = await _saveUserAndCompanyAfterPayment(selectedPlan);
          if (success) {
            await prefs.remove(AppConstants.keyPendingUpgradeCorrelator);
            await prefs.remove(AppConstants.keyPendingUpgradePlan);
            await prefs.remove(AppConstants.keyPendingUpgradePaid);
            if (mounted) {
              setState(() {
                _hasPendingUpgrade = false;
                _pendingUpgradeCorrelator = null;
                _pendingUpgradePlan = null;
              });
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Upgrade setup failed. Your payment is preserved, tap "Complete Upgrade Now" to retry without repaying.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
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

  Future<bool> _saveUserAndCompanyAfterPayment(Map<String, dynamic> selectedPlan) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final User? savedUser = _loggedInUser;
      final String? password = _loggedInUser?.password;

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
      if (branch == null) {
        branch = Branch(
          name: 'Main Branch',
        );
        branch.company.value = company;
      }

      // Prepare subscription
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
      final DateTime subscriptionEndDate = _calculateIncreasedRenewalDate(
        currentExpiry: _tryParseDate(_renewalDate ?? prefs.getString(AppConstants.keySubscriptionEndDate)),
        serverDate: _tryParseDate(selectedPlan['renewalDate']),
        interval: updatedSubscriptionItem?.renewalInterval ?? subscriptionItem?.renewalInterval,
      );
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final String formattedEndDate = formatter.format(subscriptionEndDate);
      final String planName = (selectedPlan['name']?.toString() ?? _selectedSubscription ?? 'Pro Plan').trim();
      Subscription currentSubscription = Subscription(
        name: planName,
        renewalDate: formattedEndDate,
        subscription: updatedSubscriptionItem,
        active: true,
        company: company,
      );

      Supplier companySupplier = Supplier(
        id: company.id != null ? 'supplier_${company.id}' : const Uuid().v4(),
        name: company.name ?? '',
        email: company.email,
        phoneNumber: company.mobilePhone,
        address: company.street,
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
          await prefs.setString(AppConstants.keyOfflineSubscriptions, jsonEncode([savedSubscription.toJson()]));
        } else {
          await prefs.setString(AppConstants.keySubscriptions, jsonEncode(currentSubscription.toJson()));
          await prefs.setString(AppConstants.keyOfflineSubscriptions, jsonEncode([currentSubscription.toJson()]));
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

        // Check for any incomplete/failed processes from the backend sync
        final List<dynamic>? failedProcesses = response['failedProcesses'] as List<dynamic>?;
        final List<dynamic>? completedProcesses = response['completedProcesses'] as List<dynamic>?;

        // Attempt login
        if (password != null && password.isNotEmpty) {
          try {
            await _attemptLogin(password);
          } catch (loginErr) {
            debugPrint('Login attempt failed after sync: $loginErr');
          }
        }

        // Update UI
        if (mounted) {
          setState(() {
            _currentSubscription = planName;
            _renewalDate = formattedEndDate;
          });
          final SharedPreferences prefsForSub = await SharedPreferences.getInstance();
          await prefsForSub.setString(AppConstants.keySelectedSubscription, planName);
          await prefsForSub.setString(AppConstants.keySubscriptionEndDate, formattedEndDate);
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);
          final daysRemaining = subscriptionEndDate.difference(startOfDay).inDays;
          await prefs.setInt(AppConstants.keySubscriptionDaysRemaining, daysRemaining);

          if (failedProcesses != null && failedProcesses.isNotEmpty) {
            // Show report dialog to inform user about incomplete processes
            _showSyncReportDialog(failedProcesses, completedProcesses);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upgrade successful! You are now on $_currentSubscription'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        return true;
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
      return false;
    }
  }

  void _showSyncReportDialog(List<dynamic> failedProcesses, List<dynamic>? completedProcesses) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Upgrade Sync Report',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your subscription upgrade to $_currentSubscription was activated, but the following item(s) could not complete syncing:',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Incomplete Processes:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                  ),
                  const SizedBox(height: 6),
                  ...failedProcesses.map((proc) {
                    final String name = (proc is Map && proc['process'] != null) ? proc['process'].toString() : proc.toString();
                    final String? err = (proc is Map && proc['error'] != null) ? proc['error'].toString() : null;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.cancel, color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                ),
                                if (err != null && err.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      err,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (completedProcesses != null && completedProcesses.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Successfully Completed:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                    ),
                    const SizedBox(height: 6),
                    ...completedProcesses.map((proc) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                proc.toString(),
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK, Got it'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isLoading = true; // Set loading to true
    });

    Map<String, dynamic>? plan;
    for (final sub in _availableSubscriptions) {
      if (sub['name'] == _selectedSubscription) {
        plan = Map<String, dynamic>.from(sub);
        break;
      }
    }
    final selectedPlan = plan ?? (_availableSubscriptions.isNotEmpty
        ? Map<String, dynamic>.from(_availableSubscriptions.first)
        : <String, dynamic>{'name': _selectedSubscription, 'price': 2.00});
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

            final InventoryItem? subscriptionItem = selectedPlan['item'] as InventoryItem?;
            final DateTime subscriptionEndDate = _calculateIncreasedRenewalDate(
              currentExpiry: _tryParseDate(_renewalDate ?? prefs.getString(AppConstants.keySubscriptionEndDate)),
              serverDate: _tryParseDate(selectedPlan['renewalDate']),
              interval: subscriptionItem?.renewalInterval,
            );

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

            final now = DateTime.now();
            final startOfDay = DateTime(now.year, now.month, now.day);
            final daysRemaining = subscriptionEndDate.difference(startOfDay).inDays;
            await prefs.setInt(AppConstants.keySubscriptionDaysRemaining, daysRemaining);
            await prefs.setString(AppConstants.keySubscriptions, jsonEncode(currentSubscription.toJson()));
            await prefs.setString(AppConstants.keyOfflineSubscriptions, jsonEncode([currentSubscription.toJson()]));

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
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined, color: AppTheme.vimbikaBlue),
            tooltip: 'Redeem Key',
            onPressed: _showRedeemKeyDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasPendingUpgrade)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade700, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'EcoCash Payment Confirmed!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your EcoCash payment for ${_pendingUpgradePlan?['name'] ?? 'Pro Plan'} was received successfully. The upgrade was interrupted before finishing account setup. You do not need to pay again.',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading || _isOffline ? null : _resumePendingUpgrade,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.arrow_forward),
                        label: Text(_isLoading ? 'Completing Upgrade...' : 'Complete Upgrade Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.vimbikaBlue.withAlpha(40)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.vimbikaBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.vpn_key_rounded, color: AppTheme.vimbikaBlue),
                ),
                title: const Text(
                  'Have a License Key?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: const Text(
                  'Redeem a voucher or license code',
                  style: TextStyle(fontSize: 12, color: AppTheme.grey),
                ),
                trailing: ElevatedButton(
                  onPressed: _isOffline ? null : _showRedeemKeyDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.vimbikaBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Redeem', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
              child: OutlinedButton.icon(
                onPressed: _isOffline ? null : _showRedeemKeyDialog,
                icon: const Icon(Icons.vpn_key_rounded, color: AppTheme.vimbikaBlue),
                label: const Text(
                  'Redeem License Key',
                  style: TextStyle(color: AppTheme.vimbikaBlue, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.vimbikaBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
