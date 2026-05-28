import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vimbika_pro/services/customer_service.dart';
import '../model/customer.dart';

class CustomerSyncService {
  static final CustomerSyncService _instance = CustomerSyncService._internal();
  factory CustomerSyncService() => _instance;
  CustomerSyncService._internal();

  Timer? _timer;
  final CustomerService _customerService = CustomerService();

  void startSyncTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      syncUpdatedCustomers();
    });
    // Initial sync attempt
    syncUpdatedCustomers();
  }

  void stopSyncTimer() {
    _timer?.cancel();
  }

  Future<void> syncUpdatedCustomers() async {
    debugPrint('Syncing updated customers...');
    try {
      final List<Customer> allCustomers = await _customerService.getCustomersLocally();
      final List<Customer> unsyncedCustomers = allCustomers.where((c) => !c.isSynced && c.id != null).toList();

      if (unsyncedCustomers.isEmpty) {
        debugPrint('No updated customers to sync.');
        stopSyncTimer();
        return;
      }

      debugPrint('Attempting to sync ${unsyncedCustomers.length} updated customers...');
      
      for (var customer in unsyncedCustomers) {
        try {
          await _customerService.updateCustomer(customer);
        } catch (e) {
          debugPrint('Failed to sync updated customer ${customer.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error during customer sync: $e');
    }
  }
}
