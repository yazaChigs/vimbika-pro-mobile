import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/ecocash_charge_request.dart';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:vimbika_pro/services/ecocash_service.dart';
import 'package:vimbika_pro/services/subscription_service.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../model/customer.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _currentSubscription = 'Free Tier';
  String? _selectedSubscription;
  final EcocashService _ecocashService = EcocashService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false; // Added loading state
  bool _isFetchingSubscriptions = false;
  User? _loggedInUser;

  List<Map<String, dynamic>> _availableSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchSubscriptions();
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

  Future<void> _fetchSubscriptions() async {
    setState(() {
      _isFetchingSubscriptions = true;
    });
    try {
      final subscriptions = await _subscriptionService.getAvailableSubscriptions('OFFLINE');
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
    } catch (e) {
      debugPrint('Error fetching subscriptions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load subscriptions: $e')),
      );
    } finally {
      setState(() {
        _isFetchingSubscriptions = false;
      });
    }
  }

  void _handlePayment() {
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
          amount: amount,
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
      customer: Customer(
        name: '${_loggedInUser?.firstName ?? ''} ${_loggedInUser?.lastName ?? ''}'.trim().isNotEmpty 
            ? '${_loggedInUser?.firstName ?? ''} ${_loggedInUser?.lastName ?? ''}'.trim() 
            : 'Subscriber', 
        phoneNumber: _phoneController.text,
        company: _loggedInUser?.branch?.company,
        branch: _loggedInUser?.branch,
      ),
      subscriptionItem: selectedPlan['item'] as InventoryItem?,
    );

    try {
      final response = await _ecocashService.chargeDirect(request);
      print('Response: ${response.responseCode}');

      if (response.transactionOperationStatus == 'PENDING SUBSCRIBER VALIDATION') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please approve the transaction on your phone.'),
            backgroundColor: Colors.orange,
          ),
        );
        _ecocashService.charge(request);

        bool paymentCompleted = false;
        int attempts = 0;
        const maxAttempts = 30; // 5 minutes (30 * 10 seconds)

        while (!paymentCompleted && attempts < maxAttempts) {
          await Future.delayed(const Duration(seconds: 5));
          attempts++;
          try {
            final statusResponse = await _ecocashService.checkStatus(clientCorrelator);
            if (statusResponse == 'COMPLETED') {
              paymentCompleted = true;
              if (mounted) {
                setState(() {
                  _currentSubscription = _selectedSubscription!;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully subscribed to $_currentSubscription'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } else if (statusResponse == 'FAILED' ||
                statusResponse == 'CANCELLED') {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment $statusResponse'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              break;
            }
          } catch (e) {
            debugPrint('Error checking status: $e');
          }
        }

        if (!paymentCompleted && attempts >= maxAttempts) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment timed out. Please check your EcoCash app.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${response.remarks}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading to false
      });
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
                onPressed: (_selectedSubscription != null && _selectedSubscription != _currentSubscription && !_isLoading)
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
