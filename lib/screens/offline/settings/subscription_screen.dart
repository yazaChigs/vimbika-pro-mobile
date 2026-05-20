import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:flutter/material.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _currentSubscription = 'Free Tier';
  String? _selectedSubscription;

  final List<Map<String, dynamic>> _availableSubscriptions = [
    {
      'name': 'Free Tier',
      'price': '\$0 / month',
      'features': ['Basic POS', '1 User', 'Limited Reporting', 'Offline Mode'],
    },
    {
      'name': 'Standard Plan',
      'price': '\$15 / month',
      'features': ['Full POS', 'Up to 3 Users', 'Advanced Reporting', 'Offline/Online Sync'],
    },
    {
      'name': 'Premium Plan',
      'price': '\$30 / month',
      'features': ['Unlimited Users', 'Multi-Branch Support', 'Custom Integrations', 'Priority Support'],
    },
  ];

  void _handlePayment() {
    if (_selectedSubscription == null || _selectedSubscription == _currentSubscription) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text('Are you sure you want to subscribe to $_selectedSubscription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentSubscription = _selectedSubscription!;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Successfully subscribed to $_currentSubscription'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
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
            ..._availableSubscriptions.map((sub) => _buildSubscriptionCard(sub)).toList(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_selectedSubscription != null && _selectedSubscription != _currentSubscription)
                    ? _handlePayment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.vimbikaBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
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
      onTap: isCurrent
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
                sub['price'],
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
