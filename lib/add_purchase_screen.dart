import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:vimbika_pro/model/purchase.dart';
import 'package:vimbika_pro/model/purchase_item.dart';
import 'package:vimbika_pro/model/supplier.dart';
import 'package:vimbika_pro/model/payment_paid.dart';
import 'package:vimbika_pro/model/payment_type.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/inventory/add_inventory_item_screen.dart';
import 'package:vimbika_pro/supplier/add_supplier_screen.dart'; // Import AddSupplierScreen
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class AddPurchaseScreen extends StatefulWidget {
  final Purchase? purchase;
  final bool isOfflineMode; // Added isOfflineMode parameter
  const AddPurchaseScreen({super.key, this.purchase, this.isOfflineMode = false}); // Default to false

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  Supplier? _selectedSupplier;
  Branch? _selectedBranch;
  DateTime _purchaseDate = DateTime.now();
  final TextEditingController _notesController = TextEditingController();
  String _selectedStatus = 'Complete';
  
  final List<String> _statuses = ['Draft', 'Ordered', 'Complete'];
  
  List<Supplier> _suppliers = [];
  List<InventoryItem> _inventoryItems = [];
  List<PaymentType> _paymentTypes = [];
  List<Currency> _currencies = [];
  Currency? _selectedCurrency;
  
  final List<PurchaseItem> _cartItems = [];
  final List<PaymentPaid> _payments = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.purchase != null) {
      _selectedSupplier = widget.purchase!.supplier;
      _purchaseDate = widget.purchase!.purchaseDate;
      _notesController.text = widget.purchase!.notes ?? '';
      _selectedStatus = widget.purchase!.status ?? 'Complete';
      _cartItems.addAll(widget.purchase!.items);
      _payments.addAll(widget.purchase!.payments ?? []);
      _selectedCurrency = widget.purchase!.currency;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final bool isOffline = prefs.getBool(AppConstants.keyIsOfflineMode) ?? widget.isOfflineMode;

    final List<String> supplierJson = prefs.getStringList(AppConstants.keySuppliers) ?? [];
    
    final String branchStockKey = isOffline ? AppConstants.keyOfflineBranchStock : AppConstants.keyBranchStock;
    final List<String> branchStockJson = prefs.getStringList(branchStockKey) ?? [];
    
    final String paymentTypeKey = isOffline ? AppConstants.keyOfflinePaymentTypes : AppConstants.keyPaymentTypes;
    final List<String> paymentTypeJson = prefs.getStringList(paymentTypeKey) ?? [];
    
    final String currencyKey = isOffline ? AppConstants.keyOfflineCurrencies : AppConstants.keyCurrencies;
    final List<String> currencyJson = prefs.getStringList(currencyKey) ?? [];
    
    setState(() {
      _suppliers = supplierJson.map((e) => Supplier.fromJson(jsonDecode(e))).toList();
      
      final List<BranchStock> branchStocks = branchStockJson.map((e) => BranchStock.fromJson(jsonDecode(e))).toList();
      _inventoryItems = branchStocks.where((bs) => bs.item != null).map((bs) => bs.item!.copyWith(quantity: bs.quantity)).toList();

      _paymentTypes = paymentTypeJson
          .map((e) => PaymentType.fromJson(jsonDecode(e)))
          .where((pt) => pt.active)
          .toList();
      _currencies = currencyJson.map((e) => Currency.fromJson(jsonDecode(e))).toList();

      if (_selectedBranch == null) {
        final String branchKey = isOffline ? AppConstants.keyOfflineBranch : AppConstants.keyDefaultBranch;
        final String? defaultBranchJson = prefs.getString(branchKey);
        if (defaultBranchJson != null) {
          try {
            final branchData = jsonDecode(defaultBranchJson);
            _selectedBranch = Branch.fromJson(branchData);
          } catch (e) {
            // Error decoding branch
          }
        }
      }

      if (_currencies.isNotEmpty && _selectedCurrency == null) {
        _selectedCurrency = _currencies.firstWhere((c) => c.isBaseCurrency!, orElse: () => _currencies.first);
      }

      _isLoading = false;
    });
  }

  double get _subTotalBase => _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get _taxTotalBase => _cartItems.fold(0, (sum, item) => sum + item.taxAmount);
  double get _grandTotalBase => _subTotalBase + _taxTotalBase;
  
  double get _subTotalConverted => _subTotalBase * (_selectedCurrency?.rate ?? 1.0);
  double get _taxTotalConverted => _taxTotalBase * (_selectedCurrency?.rate ?? 1.0);
  double get _grandTotalConverted => _grandTotalBase * (_selectedCurrency?.rate ?? 1.0);
  double get _amountPaidConverted => _payments.fold(0, (sum, item) => sum + item.amount);
  double get _balanceDueConverted => _grandTotalConverted - _amountPaidConverted;

  void _addItemToCart(InventoryItem item) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((i) => i.inventoryItem?.id == item.id);
      final taxPercent = item.tax?.taxPercentage ?? 0.0;
      if (existingIndex != -1) {
        final existingItem = _cartItems[existingIndex];
        final newQuantity = existingItem.quantity + 1;
        final newTaxAmount = (item.purchasePrice * newQuantity) * (taxPercent / 100);
        _cartItems[existingIndex] = PurchaseItem(
          inventoryItem: item,
          quantity: newQuantity,
          price: item.purchasePrice,
          taxAmount: newTaxAmount,
          total: (item.purchasePrice * newQuantity) + newTaxAmount,
        );
      } else {
        final taxAmount = item.purchasePrice * (taxPercent / 100);
        _cartItems.add(PurchaseItem(
          inventoryItem: item,
          quantity: 1,
          price: item.purchasePrice,
          taxAmount: taxAmount,
          total: item.purchasePrice + taxAmount,
        ));
      }
    });
  }

  void _editCartItem(int index) {
    final item = _cartItems[index];
    final qtyController = TextEditingController(text: item.quantity.toString());
    final purchasePriceController = TextEditingController(text: (item.price * (_selectedCurrency?.rate ?? 1.0)).toStringAsFixed(2));
    final sellingPriceController = TextEditingController(text: ((item.inventoryItem?.sellingPrice ?? 0.0) * (_selectedCurrency?.rate ?? 1.0)).toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${item.inventoryItem?.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
              onTap: () => qtyController.selection = TextSelection(baseOffset: 0, extentOffset: qtyController.text.length),
            ),
            TextField(
              controller: purchasePriceController,
              decoration: InputDecoration(labelText: 'Purchase Price (${_selectedCurrency?.symbol ?? ''})'),
              keyboardType: TextInputType.number,
              onTap: () => purchasePriceController.selection = TextSelection(baseOffset: 0, extentOffset: purchasePriceController.text.length),
            ),
            TextField(
              controller: sellingPriceController,
              decoration: InputDecoration(labelText: 'Selling Price (${_selectedCurrency?.symbol ?? ''})'),
              keyboardType: TextInputType.number,
              onTap: () => sellingPriceController.selection = TextSelection(baseOffset: 0, extentOffset: sellingPriceController.text.length),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(qtyController.text) ?? 0.0;
              final pPriceConverted = double.tryParse(purchasePriceController.text) ?? 0.0;
              final sPriceConverted = double.tryParse(sellingPriceController.text) ?? 0.0;
              
              final baseRate = _selectedCurrency?.rate ?? 1.0;
              final pPriceBase = pPriceConverted / baseRate;
              final sPriceBase = sPriceConverted / baseRate;

              if (qty > 0) {
                setState(() {
                  final updatedInventoryItem = InventoryItem(
                    id: item.inventoryItem?.id,
                    name: item.inventoryItem?.name ?? '',
                    purchasePrice: pPriceBase,
                    sellingPrice: sPriceBase,
                    quantity: item.inventoryItem?.quantity ?? 0.0,
                    category: item.inventoryItem?.category,
                    unit: item.inventoryItem?.unit,
                    tax: item.inventoryItem?.tax,
                    itemCode: item.inventoryItem?.itemCode,
                    reorderLevel: item.inventoryItem?.reorderLevel ?? 0.0,
                    description: item.inventoryItem?.description,
                    isService: item.inventoryItem?.isService ?? false,
                  );

                  final taxPercent = updatedInventoryItem.tax?.taxPercentage ?? 0.0;
                  final taxAmount = (pPriceBase * qty) * (taxPercent / 100);

                  _cartItems[index] = PurchaseItem(
                    inventoryItem: updatedInventoryItem,
                    quantity: qty,
                    price: pPriceBase,
                    taxAmount: taxAmount,
                    total: (qty * pPriceBase) + taxAmount,
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addPayment() {
    if (_balanceDueConverted <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase is already fully paid.')));
      return;
    }

    final List<PaymentType> availablePaymentTypes = _paymentTypes.where((pt) => 
      (pt.currency == null || pt.currency?.id == _selectedCurrency?.id) &&
      !(pt.name ?? '').startsWith('ACC-') &&
      !_payments.any((p) => p.paymentType?.id == pt.id) // Filter out already selected payment types
    ).toList();

    PaymentType? selectedType;
    final amountController = TextEditingController(text: _balanceDueConverted.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...availablePaymentTypes.map((paymentType) {
                  return RadioListTile<PaymentType>(
                    title: Text(paymentType.name),
                    value: paymentType,
                    groupValue: selectedType,
                    onChanged: (PaymentType? newValue) {
                      setDialogState(() {
                        selectedType = newValue;
                      });
                    },
                  );
                }).toList(),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  onTap: () => amountController.selection = TextSelection(baseOffset: 0, extentOffset: amountController.text.length),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (selectedType == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please select a payment method.'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount <= 0) return;

                setState(() {
                  _payments.add(PaymentPaid(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    paymentType: selectedType,
                    amount: amount,
                    currency: _selectedCurrency,
                    paymentDate: DateTime.now(),
                  ));
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePurchase() async {
    if (_selectedSupplier == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
      return;
    }
    if (_selectedBranch == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set a default branch in settings')));
      return;
    }
    if (_cartItems.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add items to the purchase')));
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOffline = prefs.getBool(AppConstants.keyIsOfflineMode) ?? widget.isOfflineMode;

    final List<String> purchasesJson = prefs.getStringList(AppConstants.keyPurchases) ?? [];
    
    final purchaseToSave = Purchase(
      id: widget.purchase?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      dateCreated: DateTime.now().toIso8601String(),
      supplier: _selectedSupplier,
      branch: _selectedBranch,
      currency: _selectedCurrency,
      items: _cartItems,
      payments: _selectedStatus == 'Draft' ? [] : _payments,
      subTotal: _subTotalBase,
      taxTotal: _taxTotalBase,
      grandTotal: _grandTotalBase,
      purchaseDate: _purchaseDate,
      notes: _notesController.text,
      status: _selectedStatus,
    );

    if (widget.purchase != null) {
      final index = purchasesJson.indexWhere((element) {
        final p = Purchase.fromJson(jsonDecode(element));
        return p.id == widget.purchase!.id;
      });
      if (index != -1) {
        purchasesJson[index] = jsonEncode(purchaseToSave.toJson());
      } else {
        purchasesJson.add(jsonEncode(purchaseToSave.toJson()));
      }
    } else {
      purchasesJson.add(jsonEncode(purchaseToSave.toJson()));
    }
    
    await prefs.setStringList(AppConstants.keyPurchases, purchasesJson);

    // If it was a draft and we are now completing/ordering it, we can continue to update stock.
    // Note: If it was already Complete/Ordered, re-saving it will increment stock AGAIN.
    // Usually, we only allow editing Drafts.
    
    // Update inventory stock levels ONLY if status is 'Complete'
    // AND if the previous status was 'Draft' or 'Ordered' (to avoid double counting stock)
    if (_selectedStatus == 'Complete' && (widget.purchase == null || widget.purchase!.status == 'Draft' || widget.purchase!.status == 'Ordered')) {
      final String inventoryKey = isOffline ? AppConstants.keyOfflineInventoryItems : AppConstants.keyInventoryItems;
      final List<String> inventoryJson = prefs.getStringList(inventoryKey) ?? [];
      final List<InventoryItem> items = inventoryJson.map((e) => InventoryItem.fromJson(jsonDecode(e))).toList();
      
      final String branchStockKey = isOffline ? AppConstants.keyOfflineBranchStock : AppConstants.keyBranchStock;
      final List<String> branchStockJson = prefs.getStringList(branchStockKey) ?? [];
      final List<BranchStock> branchStocks = branchStockJson.map((e) => BranchStock.fromJson(jsonDecode(e))).toList();

      for (var cartItem in _cartItems) {
        // Update general inventory quantity
        final index = items.indexWhere((i) => i.id == cartItem.inventoryItem?.id);
        if (index != -1) {
          final item = items[index];
          items[index] = InventoryItem(
            id: item.id,
            name: item.name,
            purchasePrice: cartItem.price,
            sellingPrice: cartItem.inventoryItem?.sellingPrice ?? item.sellingPrice,
            quantity: item.quantity + cartItem.quantity,
            category: item.category,
            unit: item.unit,
            tax: item.tax,
            itemCode: item.itemCode,
            reorderLevel: item.reorderLevel,
            description: item.description,
            isService: item.isService,
          );
        }

        // Update branch specific quantity if a branch is selected
        if (_selectedBranch != null && cartItem.inventoryItem != null) {
          final bsIndex = branchStocks.indexWhere((bs) => 
            bs.branch?.id == _selectedBranch!.id && 
            bs.item?.id == cartItem.inventoryItem!.id
          );

          if (bsIndex != -1) {
            final existingBS = branchStocks[bsIndex];
            branchStocks[bsIndex] = BranchStock(
              id: existingBS.id,
              branch: existingBS.branch,
              item: cartItem.inventoryItem, // Use updated item with new prices
              quantity: existingBS.quantity + cartItem.quantity,
              dateCreated: existingBS.dateCreated,
              dateModified: DateTime.now().toIso8601String(),
            );
          } else {
            branchStocks.add(BranchStock(
              id: DateTime.now().millisecondsSinceEpoch.toString() + (cartItem.inventoryItem?.id ?? ''),
              branch: _selectedBranch,
              item: cartItem.inventoryItem,
              quantity: cartItem.quantity,
              dateCreated: DateTime.now().toIso8601String(),
              dateModified: DateTime.now().toIso8601String(),
            ));
          }
        }
      }

      final List<String> updatedInventoryJson = items.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(inventoryKey, updatedInventoryJson);

      final List<String> updatedBranchStockJson = branchStocks.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(branchStockKey, updatedBranchStockJson);
    }

    if (context.mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Add Purchase', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
        actions: [
          if (_currencies.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: AppTheme.vimbikaBlue.withAlpha(20), borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Currency>(
                  value: _selectedCurrency,
                  onChanged: (val) {
                    setState(() {
                      _selectedCurrency = val;
                    });
                  },
                  items: _currencies.map((c) => DropdownMenuItem<Currency>(value: c, child: Text(c.name!, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue)))).toList(),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildSupplierSelector()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildDatePicker()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildStatusSelector()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            TextButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AddInventoryItemScreen()),
                                );
                                if (result == true) {
                                  _loadData();
                                }
                              },
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('New Item'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildItemList(),
                        const SizedBox(height: 16),
                        _buildAddItemButton(),
                        if (_selectedStatus != 'Draft') ...[
                          const SizedBox(height: 24),
                          const Text('Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          _buildPaymentList(),
                          const SizedBox(height: 16),
                          _buildAddPaymentButton(),
                        ],
                      ],
                    ),
                  ),
                ),
                _buildSummary(),
              ],
            ),
    );
  }

  Widget _buildSupplierSelector() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<Supplier>(
            initialValue: _selectedSupplier,
            decoration: InputDecoration(
              labelText: 'Supplier *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: AppTheme.white,
            ),
            items: _suppliers.map((s) => DropdownMenuItem<Supplier>(value: s, child: Text(s.name))).toList(),
            onChanged: (val) => setState(() => _selectedSupplier = val),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.vimbikaBlue),
          onPressed: () async {
            final newSupplier = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddSupplierScreen()),
            );
            if (newSupplier != null && newSupplier is Supplier) {
              await _loadData(); // Reload data to get the new supplier
              setState(() {
                _selectedSupplier = newSupplier; // Pre-select the new supplier
              });
            }
          },
        ),
      ],
    );
  }


  Widget _buildStatusSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppTheme.white,
      ),
      items: _statuses.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
      onChanged: (val) => setState(() => _selectedStatus = val!),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _purchaseDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) setState(() => _purchaseDate = date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Purchase Date',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppTheme.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('yyyy-MM-dd').format(_purchaseDate)),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildItemList() {
    if (_cartItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.grey.withAlpha((255 * 0.05).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No items added to purchase')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cartItems.length,
      itemBuilder: (context, index) {
        final item = _cartItems[index];
        final priceConverted = item.price * (_selectedCurrency?.rate ?? 1.0);
        final taxAmountConverted = item.taxAmount * (_selectedCurrency?.rate ?? 1.0);
        final totalConverted = item.total * (_selectedCurrency?.rate ?? 1.0);
        final sellingPriceConverted = (item.inventoryItem?.sellingPrice ?? 0.0) * (_selectedCurrency?.rate ?? 1.0);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(item.inventoryItem?.name ?? 'Unknown'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qty: ${item.quantity.toStringAsFixed(0)} | Cost: ${_selectedCurrency?.symbol ?? ""}${priceConverted.toStringAsFixed(2)}'),
                if (item.taxAmount > 0)
                  Text('Tax: ${_selectedCurrency?.symbol ?? ""}${taxAmountConverted.toStringAsFixed(2)} (${item.inventoryItem?.tax?.taxPercentage ?? 0}%)', style: const TextStyle(fontSize: 12, color: AppTheme.grey)),
                Text('Sell Price: ${_selectedCurrency?.symbol ?? ""}${sellingPriceConverted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: AppTheme.grey)),
              ],
            ),
            trailing: Text('${_selectedCurrency?.symbol ?? ""}${totalConverted.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => _editCartItem(index),
            onLongPress: () => setState(() => _cartItems.removeAt(index)),
          ),
        );
      },
    );
  }

  Widget _buildPaymentList() {
    if (_payments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.grey.withAlpha((255 * 0.05).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: Text('No payments added')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(payment.paymentType?.name ?? 'Unknown Method'),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(payment.paymentDate ?? DateTime.now())),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_selectedCurrency?.symbol ?? ""}${payment.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    final editController = TextEditingController(text: payment.amount.toStringAsFixed(2));
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Edit Payment Amount'),
                        content: TextField(
                          controller: editController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          autofocus: true,
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          onTap: () => editController.selection = TextSelection(baseOffset: 0, extentOffset: editController.text.length),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              final newAmt = double.tryParse(editController.text);
                              if (newAmt != null && newAmt > 0) {
                                setState(() {
                                  _payments[index] = payment.copyWith(amount: newAmt);
                                });
                              } else if (newAmt == 0) {
                                setState(() {
                                  _payments.removeAt(index);
                                });
                              }
                              Navigator.pop(context);
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(Icons.edit, size: 24, color: AppTheme.vimbikaBlue), // Increased size to 24
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _payments.removeAt(index)),
                  child: const Icon(Icons.close, size: 24, color: Colors.red), // Increased size to 24
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddItemButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showInventoryPicker(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildAddPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addPayment,
        icon: const Icon(Icons.payment),
        label: const Text('Add Payment'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showInventoryPicker() {
    String searchQuery = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredItems = _inventoryItems
              .where((item) => item.name.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  const Text('Select Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setModalState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? const Center(child: Text('No items found'))
                        : ListView.builder(
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return ListTile(
                                title: Text(item.name),
                                subtitle: Text('Current Stock: ${item.quantity}'),
                                trailing: const Icon(Icons.add_circle_outline),
                                onTap: () {
                                  _addItemToCart(item);
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha((255 * 0.05).round()), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sub Total:', style: TextStyle(fontSize: 16)),
              Text('${_selectedCurrency?.symbol ?? ""}${_subTotalConverted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax:', style: TextStyle(fontSize: 16)),
              Text('${_selectedCurrency?.symbol ?? ""}${_taxTotalConverted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grand Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${_selectedCurrency?.symbol ?? ""}${_grandTotalConverted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          if (_selectedStatus != 'Draft') ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Amount Paid:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                Text('${_selectedCurrency?.symbol ?? ""}${_amountPaidConverted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Balance Due:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                Text('${_selectedCurrency?.symbol ?? ""}${_balanceDueConverted.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _savePurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.vimbikaBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_selectedStatus == 'Complete' ? 'Complete Purchase' : 'Save Purchase', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}