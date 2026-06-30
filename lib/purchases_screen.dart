import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/add_purchase_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'model/purchase.dart';
import 'model/supplier.dart';
import 'model/inventory_item.dart';
import 'model/payment_paid.dart';
import 'model/payment_type.dart';
import 'app_constants/app_constants.dart';
import 'package:intl/intl.dart';

// Import services for online mode
import 'package:vimbika_pro/services/purchase_service.dart';
import 'package:vimbika_pro/services/inventory_item_service.dart';
import 'package:vimbika_pro/services/payments_service.dart'; // Assuming this handles payment types
import 'package:vimbika_pro/services/supplier_service.dart'; // Import SupplierService

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  _PurchasesScreenState createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  List<Purchase> _purchases = [];
  List<Supplier> _suppliers = [];
  List<InventoryItem> _inventoryItems = [];
  List<PaymentType> _paymentTypes = [];
  bool _isLoading = true;
  bool _isOfflineMode = false; // Added for offline/online mode

  // Filter states
  Supplier? _selectedSupplier;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  InventoryItem? _selectedInventoryItem;
  bool _showFilters = false;

  final List<String> _statuses = ['Draft', 'Ordered', 'Complete'];

  // Service instances
  final PurchaseService _purchaseService = PurchaseService();
  final InventoryItemService _inventoryItemService = InventoryItemService();
  final PaymentsService _paymentsService = PaymentsService(); // Assuming this service provides payment types
  final SupplierService _supplierService = SupplierService(); // Initialize SupplierService

  @override
  void initState() {
    _loadData();
    super.initState();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;

    if (_isOfflineMode) {
      // Load from local storage (SharedPreferences)
      final List<String> purchaseJson = prefs.getStringList(AppConstants.keyPurchases) ?? [];
      final List<String> supplierJson = prefs.getStringList(AppConstants.keySuppliers) ?? [];
      final List<String> inventoryJson = prefs.getStringList(AppConstants.keyOfflineInventoryItems) ?? [];
      final List<String> paymentTypeJson = prefs.getStringList(AppConstants.keyOfflinePaymentTypes) ?? [];

      _purchases = purchaseJson
          .map((item) => Purchase.fromJson(jsonDecode(item)))
          .toList()
          .reversed.toList(); // Show latest first

      _suppliers = supplierJson
          .map((item) => Supplier.fromJson(jsonDecode(item)))
          .toList();

      _inventoryItems = inventoryJson
          .map((item) => InventoryItem.fromJson(jsonDecode(item)))
          .toList();

      _paymentTypes = paymentTypeJson
          .map((item) => PaymentType.fromJson(jsonDecode(item)))
          .toList();
    } else {
      // Load from online services
      try {
        _purchases = await _purchaseService.getAllPurchases();
        _suppliers = await _supplierService.getAllSuppliers();
        _inventoryItems = await _inventoryItemService.getAllInventoryItems();
        _paymentTypes = await _paymentsService.getPaymentTypes(); // Assuming this method exists
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data online: $e')),
        );
        // Fallback to offline data if online fails
        _isOfflineMode = true;
        await _loadData(); // Reload data in offline mode
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  void _loadPurchases() {
    _loadData();
  }

  List<Purchase> get _filteredPurchases {
    return _purchases.where((purchase) {
      // Filter by Supplier
      if (_selectedSupplier != null && purchase.supplier?.id != _selectedSupplier!.id) {
        return false;
      }

      // Filter by Status
      if (_selectedStatus != null && purchase.status != _selectedStatus) {
        return false;
      }

      // Filter by Date Range
      if (_startDate != null) {
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
        if (purchase.purchaseDate.isBefore(start)) return false;
      }
      if (_endDate != null) {
        final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (purchase.purchaseDate.isAfter(end)) return false;
      }

      // Filter by Inventory Item
      if (_selectedInventoryItem != null) {
        bool containsItem = purchase.items.any((item) => item.inventoryItem?.id == _selectedInventoryItem!.id);
        if (!containsItem) return false;
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _selectedSupplier = null;
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
      _selectedInventoryItem = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Purchases History', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters) _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPurchases.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.grey.withAlpha((255 * 0.5).round())),
                            const SizedBox(height: 16),
                            Text(_purchases.isEmpty ? 'No purchase records yet.' : 'No purchases match your filters.', style: TextStyle(color: AppTheme.grey, fontSize: 18)),
                            const SizedBox(height: 8),
                            if (_purchases.isNotEmpty)
                              TextButton(
                                onPressed: _resetFilters,
                                child: const Text('Reset Filters'),
                              )
                            else
                              Text('Tap + to record a new purchase', style: TextStyle(color: AppTheme.grey.withAlpha((255 * 0.7).round()))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredPurchases.length,
                        itemBuilder: (context, index) {
                          final purchase = _filteredPurchases[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.vimbikaBlue.withAlpha((255 * 0.1).round()),
                                  child: Icon(Icons.shopping_cart_outlined, color: AppTheme.vimbikaBlue),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        purchase.supplier?.name ?? 'Unknown Supplier', 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (purchase.status == 'Draft' || purchase.status == 'Ordered')
                                      IconButton(
                                        icon: Icon(Icons.edit_note, color: AppTheme.vimbikaBlue, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => AddPurchaseScreen(purchase: purchase, isOfflineMode: _isOfflineMode)),
                                          );
                                          if (result == true) _loadPurchases();
                                        },
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  '${DateFormat('MMM dd, yyyy').format(purchase.purchaseDate)} - ${purchase.items.length} items',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${purchase.currency?.symbol ?? '\$'}${((purchase.grandTotal) * (purchase.currency?.rate ?? 1.0)).toStringAsFixed(2)}', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.vimbikaBlue)
                                    ),
                                    Text(
                                      purchase.status == 'Draft' ? 'Edit Draft' : (purchase.status == 'Ordered' ? 'Receive Items' : (purchase.status ?? 'Complete')), 
                                      style: TextStyle(
                                        fontSize: 9, 
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(purchase.status ?? 'Complete')
                                      )
                                    ),
                                    if (purchase.status != 'Draft' && _calculateBalanceDue(purchase) > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2.0),
                                        child: InkWell(
                                          onTap: () => _showPayNowDialog(purchase),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withAlpha((255 * 0.1).round()),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.red, width: 0.5),
                                            ),
                                            child: const Text(
                                              'Pay Now',
                                              style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                children: [
                                  _buildPurchaseExpandedDetails(purchase),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPurchaseScreen(isOfflineMode: _isOfflineMode)),
          );
          if (result == true) _loadPurchases();
        },
        backgroundColor: AppTheme.vimbikaBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPurchaseExpandedDetails(Purchase purchase) {
    final currencySymbol = purchase.currency?.symbol ?? '\$';
    final rate = purchase.currency?.rate ?? 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.vimbikaBlue.withAlpha((255 * 0.05).round()),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Divider(),
          ...purchase.items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.inventoryItem?.name ?? 'Unknown Item', style: const TextStyle(fontSize: 13)),
                      Text('${item.quantity} x $currencySymbol${(item.price * rate).toStringAsFixed(2)}', 
                          style: TextStyle(fontSize: 11, color: AppTheme.grey)),
                    ],
                  ),
                ),
                Text('$currencySymbol${(item.total * rate).toStringAsFixed(2)}', 
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          )),
          const SizedBox(height: 16),
          if (purchase.payments != null && purchase.payments!.isNotEmpty) ...[
            const Text('Payments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(),
            ...purchase.payments!.map((payment) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.paymentType?.name ?? 'Payment', style: const TextStyle(fontSize: 13)),
                      Text(DateFormat('MMM dd, yyyy').format(payment.paymentDate ?? DateTime.now()), 
                          style: TextStyle(fontSize: 11, color: AppTheme.grey)),
                    ],
                  ),
                  Text('$currencySymbol${payment.amount.toStringAsFixed(2)}', 
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.green)),
                ],
              ),
            )),
          ] else if (purchase.status != 'Draft') ...[
            const Text('No payments recorded.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('$currencySymbol${(purchase.grandTotal * rate).toStringAsFixed(2)}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue)),
            ],
          ),
          if (purchase.status != 'Draft')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Balance Due', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$currencySymbol${_calculateBalanceDue(purchase).toStringAsFixed(2)}', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: _calculateBalanceDue(purchase) > 0 ? Colors.red : Colors.green)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Supplier>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Supplier', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                  initialValue: _selectedSupplier,
                  items: [
                    const DropdownMenuItem<Supplier>(value: null, child: Text('All Suppliers')),
                    ..._suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s.name, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (val) => setState(() => _selectedSupplier = val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Status', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
                  initialValue: _selectedStatus,
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('All Statuses')),
                    ..._statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (val) => setState(() => _selectedStatus = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<InventoryItem>(
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Inventory Item', contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
            initialValue: _selectedInventoryItem,
            items: [
              const DropdownMenuItem<InventoryItem>(value: null, child: Text('All Items')),
              ..._inventoryItems.map((item) => DropdownMenuItem(value: item, child: Text(item.name, overflow: TextOverflow.ellipsis))),
            ],
            onChanged: (val) => setState(() => _selectedInventoryItem = val),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => _startDate = date);
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(_startDate == null ? 'From' : DateFormat('dd/MM/yy').format(_startDate!), style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: _startDate ?? DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setState(() => _endDate = date);
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(_endDate == null ? 'To' : DateFormat('dd/MM/yy').format(_endDate!), style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh, color: AppTheme.vimbikaBlue),
                tooltip: 'Reset Filters',
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  double _calculateBalanceDue(Purchase purchase) {
    double grandTotalConverted = purchase.grandTotal * (purchase.currency?.rate ?? 1.0);
    double amountPaidConverted = (purchase.payments ?? []).fold(0.0, (sum, p) => sum + p.amount);
    return grandTotalConverted - amountPaidConverted;
  }

  void _showPayNowDialog(Purchase purchase) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    
    final filteredPaymentTypes = _paymentTypes.where((pt) => 
      pt.currency.value == null || pt.currency.value?.id == purchase.currency?.id
    ).toList();

    PaymentType? selectedPaymentType; // Initialize to null
    DateTime paymentDate = DateTime.now();
    double balanceDue = _calculateBalanceDue(purchase);
    amountController.text = balanceDue.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pay for ${purchase.supplier?.name ?? 'Purchase'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Balance Due: ${purchase.currency?.symbol ?? '\$'}${balanceDue.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentType>(
                  decoration: const InputDecoration(labelText: 'Payment Method'),
                  initialValue: selectedPaymentType, // Changed from value to initialValue
                  items: [
                    const DropdownMenuItem<PaymentType>(value: null, child: Text('Select Payment Method')), // Always include null option
                    ...filteredPaymentTypes.map((type) => DropdownMenuItem(value: type, child: Text(type.name))),
                  ],
                  onChanged: (val) => setDialogState(() => selectedPaymentType = val),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: paymentDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setDialogState(() => paymentDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Payment Date'),
                    child: Text(DateFormat('yyyy-MM-dd').format(paymentDate)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount <= 0) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
                  return;
                }
                
                final newPayment = PaymentPaid(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  amount: amount,
                  paymentType: selectedPaymentType,
                  paymentDate: paymentDate,
                  notes: notesController.text,
                  currency: purchase.currency,
                );

                List<PaymentPaid> updatedPayments = List.from(purchase.payments ?? []);
                updatedPayments.add(newPayment);

                final updatedPurchase = Purchase(
                  id: purchase.id,
                  dateCreated: purchase.dateCreated,
                  dateModified: DateTime.now().toIso8601String(),
                  supplier: purchase.supplier,
                  branch: purchase.branch,
                  currency: purchase.currency,
                  items: purchase.items,
                  payments: updatedPayments,
                  subTotal: purchase.subTotal,
                  taxTotal: purchase.taxTotal,
                  grandTotal: purchase.grandTotal,
                  purchaseDate: purchase.purchaseDate,
                  notes: purchase.notes,
                  status: purchase.status,
                );

                if (_isOfflineMode) {
                  final SharedPreferences prefs = await SharedPreferences.getInstance();
                  final List<String> purchasesJson = prefs.getStringList(AppConstants.keyPurchases) ?? [];
                  
                  final index = purchasesJson.indexWhere((element) {
                    final p = Purchase.fromJson(jsonDecode(element));
                    return p.id == purchase.id;
                  });

                  if (index != -1) {
                    purchasesJson[index] = jsonEncode(updatedPurchase.toJson());
                    await prefs.setStringList(AppConstants.keyPurchases, purchasesJson);
                    _loadPurchases();
                    if (!mounted) return;
                    Navigator.pop(context);
                  }
                } else {
                  try {
                    await _purchaseService.updatePurchase(updatedPurchase);
                    _loadPurchases();
                    if (!mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to record payment online: $e')),
                    );
                  }
                }
              },
              child: const Text('Save Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Draft':
        return Colors.grey;
      case 'Ordered':
        return Colors.orange;
      case 'Complete':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}