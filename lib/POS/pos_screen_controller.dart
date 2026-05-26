import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/model/sale_item.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/payment_type.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/category.dart' as model;
import 'package:vimbika_pro/model/customer_currency_amount.dart';
import 'package:vimbika_pro/model/mobile_pos_shift.dart';
import 'package:vimbika_pro/model/mobile_shift_currency_amount.dart';
import 'package:vimbika_pro/services/branch_stock_service.dart';
import 'package:vimbika_pro/screens/offline/settings/shift_management_screen.dart';
import 'package:vimbika_pro/services/mobile_shift_service.dart';
import 'package:vimbika_pro/services/sale_service.dart';
import 'package:vimbika_pro/services/printer_service.dart';

import 'package:vimbika_pro/sale_receipt_screen.dart';

/// Represents a pending update to a customer's balance, to be applied at sale completion.
class PendingCustomerBalanceUpdate {
  final String customerId;
  final Currency currency;
  final double amountChange; // Positive for credit, negative for debit

  PendingCustomerBalanceUpdate({
    required this.customerId,
    required this.currency,
    required this.amountChange,
  });
}

class POSScreenController extends ChangeNotifier {
  final BuildContext context; // Keep context for SnackBar, etc.
  final MobilePosShiftService _shiftService = MobilePosShiftService();
  final SaleService _saleService = SaleService();
  final PrinterService _printerService = PrinterService(); // Instantiate PrinterService

  POSScreenController(this.context) {
    _checkOpenShift();
    _loadData();
    _loadHeldSalesCount();
    _loadPrinterSettings(); // Load printer settings on init
  }

  List<BranchStock> _allBranchStocks = [];
  List<BranchStock> _filteredBranchStocks = [];
  final List<SaleItem> _cart = [];
  List<Currency> _currencies = [];
  List<PaymentType> _paymentTypes = [];
  List<Customer> _customers = [];
  List<model.Category> _categories = [];
  
  Currency? _selectedCurrency;
  Customer? _selectedCustomer;
  Branch? _selectedBranch;
  model.Category? _selectedCategory;
  final List<PaymentReceived> _payments = [];
  final List<MobileShiftCurrencyAmount> _pendingAccountCredits = []; // Added to track account credits
  final List<PendingCustomerBalanceUpdate> _pendingCustomerBalanceUpdates = []; // New list for deferred customer balance updates
  
  bool _isLoading = true;
  String _searchQuery = '';
  bool _allowOutOfStockSales = false;
  bool _isPriceInclusiveTax = true;
  bool _isBarcodeSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerSearchController = TextEditingController();
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _discountControllers = {};
  
  bool _isDownloadingStock = false;
  bool _isProcessingSale = false;
  bool _isOnline = false; // Added for offline/online mode
  
  int _heldSalesCount = 0;
  String? _ticketName; // New property for held sale ticket name
  bool _printReceiptForThisSale = false; // New setting for individual sale printing
  bool _customerSelectFocus = true;

  // Getters for accessing state
  List<BranchStock> get allBranchStocks => _allBranchStocks;
  List<BranchStock> get filteredBranchStocks => _filteredBranchStocks;
  List<SaleItem> get cart => _cart;
  List<Currency> get currencies => _currencies;
  List<PaymentType> get paymentTypes => _paymentTypes;
  List<Customer> get customers => _customers;
  List<model.Category> get categories => _categories;
  
  Currency? get selectedCurrency => _selectedCurrency;
  Customer? get selectedCustomer => _selectedCustomer;
  Branch? get selectedBranch => _selectedBranch;
  model.Category? get selectedCategory => _selectedCategory;
  List<PaymentReceived> get payments => _payments;
  
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get allowOutOfStockSales => _allowOutOfStockSales;
  bool get isPriceInclusiveTax => _isPriceInclusiveTax;
  bool get isBarcodeSearchMode => _isBarcodeSearchMode;
  TextEditingController get searchController => _searchController;
  TextEditingController get customerSearchController => _customerSearchController;
  Map<String, TextEditingController> get quantityControllers => _quantityControllers;
  Map<String, TextEditingController> get priceControllers => _priceControllers;
  Map<String, TextEditingController> get discountControllers => _discountControllers;
  bool get isDownloadingStock => _isDownloadingStock;
  bool get isProcessingSale => _isProcessingSale;
  int get heldSalesCount => _heldSalesCount;
  String? get ticketName => _ticketName; // Getter for ticket name
  bool get printReceiptForThisSale => _printReceiptForThisSale; // Getter for new setting
  bool get customerSelectFocus => _customerSelectFocus; // Getter for new setting

  // Setter for new setting
  set printReceiptForThisSale(bool value) {
    _printReceiptForThisSale = value;
    notifyListeners();
  }

  // Setter for new setting
  set customerSelectFocus(bool value) {
    _customerSelectFocus = value;
    notifyListeners();
  }


  Future<void> _loadPrinterSettings() async {
    await _printerService.init(); // Ensure printer service is initialized
    _printReceiptForThisSale = _printerService.getAlwaysPrintReceipt(); // Initialize with global setting
    notifyListeners();
  }

  // Setters for updating state and notifying listeners
  set selectedCurrency(Currency? currency) {
    _selectedCurrency = currency;
    // Clear payments when currency changes as payments are in the selected currency
    _payments.clear();
    _pendingCustomerBalanceUpdates.clear(); // Clear pending balance updates
    notifyListeners();
  }

  set selectedCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  set selectedCategory(model.Category? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void toggleBarcodeSearchMode() {
    _isBarcodeSearchMode = !_isBarcodeSearchMode;
    _searchController.clear();
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _disposeQuantityControllers();
    super.dispose();
  }

  void _disposeQuantityControllers() {
    _quantityControllers.forEach((key, controller) => controller.dispose());
    _quantityControllers.clear();
    _priceControllers.forEach((key, controller) => controller.dispose());
    _priceControllers.clear();
    _discountControllers.forEach((key, controller) => controller.dispose());
    _discountControllers.clear();
  }

  Future<void> _checkOpenShift() async {
    final shift = await _getCurrentShift();
    
    bool isPreviousDay = false;
    if (shift != null && shift.dateCreated != null) {
      try {
        final shiftDate = DateTime.parse(shift.dateCreated!);
        final now = DateTime.now();
        if (shiftDate.year != now.year || shiftDate.month != now.month || shiftDate.day != now.day) {
          isPreviousDay = true;
        }
      } catch (e) {
        debugPrint('Error parsing shift date: $e');
      }
    }

    if (shift == null || (shift.isShiftClosed ?? true) || isPreviousDay) {
      if (context.mounted) {
        String titleText = 'Open Shift Required';
        String contentText = 'You need an open shift to use the POS. Would you like to open one now?';
        
        if (isPreviousDay) {
          titleText = 'Shift from Previous Day';
          contentText = 'Your current open shift is from a previous day. Please manage your shifts to continue.';
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Text(titleText),
            content: Text(contentText),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Close dialog
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Go back to previous screen
                  }
                },
                child: const Text('Go Back'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Close dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ShiftManagementScreen()),
                  ).then((_) {
                    _checkOpenShift();
                  });
                },
                child: const Text('Manage Shift'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Determine online/offline mode
    _isOnline = !(prefs.getBool(AppConstants.keyIsOfflineMode) ?? false);

    final List<String> stockJson = _isOnline
        ? (prefs.getStringList(AppConstants.keyBranchStock) ?? [])
        : (prefs.getStringList(AppConstants.keyOfflineBranchStock) ?? []);

    final List<String> currencyJson = _isOnline
        ? (prefs.getStringList(AppConstants.keyCurrencies) ?? [])
        : (prefs.getStringList(AppConstants.keyOfflineCurrencies) ?? []);
    final List<String> paymentTypeJson = _isOnline
        ? (prefs.getStringList(AppConstants.keyPaymentTypes) ?? [])
        : (prefs.getStringList(AppConstants.keyOfflinePaymentTypes) ?? []);
    
    final List<String> customerJson = _isOnline
        ? (prefs.getStringList(AppConstants.keyCustomers) ?? [])
        : (prefs.getStringList(AppConstants.keyOfflineCustomers) ?? []);

    final List<String> catJson = _isOnline
        ? (prefs.getStringList(AppConstants.keyCategories) ?? [])
        : (prefs.getStringList(AppConstants.keyOfflineCategories) ?? []);

    Branch? defaultBranch;
    final String? dBranchJson = _isOnline
    ?prefs.getString(AppConstants.keyDefaultBranch):
    prefs.getString(AppConstants.keyOfflineBranch);
    if (dBranchJson != null) {
      defaultBranch = Branch.fromJson(jsonDecode(dBranchJson));
    }

    _allBranchStocks = stockJson.map((item) => BranchStock.fromJson(jsonDecode(item))).toList();
    _currencies = currencyJson.map((e) => Currency.fromJson(jsonDecode(e))).toList();
    
    // Only load active payment types and exclude those containing "Credit" in their name
    _paymentTypes = paymentTypeJson
        .map((e) => PaymentType.fromJson(jsonDecode(e)))
        .where((pt) => pt.active && !pt.name.toLowerCase().contains('credit'))
        .toList();
        
    _customers = customerJson.map((e) => Customer.fromJson(jsonDecode(e))).toList();
    _categories = catJson.map((e) => model.Category.fromJson(jsonDecode(e))).toList();

    _selectedBranch = defaultBranch;

    _allowOutOfStockSales = prefs.getBool(AppConstants.keyAllowOutOfStockSales) ?? false;
    _isPriceInclusiveTax = prefs.getBool(AppConstants.keyIsPriceInclusiveTax) ?? true;

    if (_currencies.isNotEmpty) {
      _selectedCurrency = _currencies.firstWhere(
              (c) => c.isBaseCurrency == true,
          orElse: () => _currencies.first
      );
    }

    _applyFilters();
    _isLoading = false;
    notifyListeners();

    // Only attempt to download stock if online and local stock is empty
    if (_isOnline && _allBranchStocks.isEmpty && _selectedBranch != null) {
      _downloadStockForDefaultBranch();
    }
  }

  Future<void> _downloadStockForDefaultBranch() async {
    if (_selectedBranch?.id == null) return;

    _isDownloadingStock = true;
    notifyListeners();

    try {
      final stockService = BranchStockService();
      final newStocks = await stockService.fetchStockByBranch(_selectedBranch!);

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      List<String> stockJsonList = newStocks.map((s) => jsonEncode(s.toJson())).toList();
      // Save to keyBranchStock if online, or keyOfflineBranchStock if offline (though this method should only be called if online)
      await prefs.setStringList(AppConstants.keyBranchStock, stockJsonList);

      _allBranchStocks = newStocks;
      _applyFilters();
    } catch (e) {
      debugPrint("Failed to download branch stock: $e");
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download stock: $e')));
      }
    } finally {
      _isDownloadingStock = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredBranchStocks = _allBranchStocks.where((s) {
      final matchesBranch = _selectedBranch == null || s.branch?.id == _selectedBranch?.id;
      final matchesCategory = _selectedCategory == null || s.item?.category?.id == _selectedCategory!.id;

      bool matchesSearch;
      if (_isBarcodeSearchMode) {
        matchesSearch = s.item?.itemCode == _searchQuery;
      } else {
        matchesSearch = s.item?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false ||
                        (s.item?.itemCode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }

      return matchesBranch && matchesCategory && matchesSearch;
    }).toList();
    notifyListeners();
  }

  double get subTotalBase => _cart.fold(0, (sum, item) => sum + item.total);

  double get taxTotalBase => _cart.fold(0, (sum, item) => sum + item.taxAmount);

  double get grandTotalBase => subTotalBase + taxTotalBase;

  double get grandTotalConverted => grandTotalBase * (_selectedCurrency?.rate ?? 1.0);
  double get amountPaidConverted => _payments.fold(0, (sum, item) => sum + item.amount);
  double get balanceDueConverted => grandTotalConverted - amountPaidConverted;

  void addToCart(BranchStock stock) {
    final product = stock.item!;

    if (!_allowOutOfStockSales && !product.isService) {
      final cartItemIndex = _cart.indexWhere((item) => item.inventoryItem?.id == product.id);
      double currentCartQty = 0;
      if (cartItemIndex != -1) {
        currentCartQty = _cart[cartItemIndex].quantity;
      }

      if (stock.quantity <= currentCartQty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough stock available'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    final index = _cart.indexWhere((item) => item.inventoryItem?.id == product.id);
    if (index != -1) {
      final existingItem = _cart[index];

      final double newQty = existingItem.quantity + 1;
      final double taxRate = product.tax?.taxPercentage ?? 0.0;
      double itemTaxAmount;
      double itemSubtotal;

      if (_isPriceInclusiveTax) {
        double totalInclusive = newQty * product.sellingPrice;
        itemTaxAmount = totalInclusive - (totalInclusive / (1 + taxRate / 100));
        itemSubtotal = totalInclusive - itemTaxAmount;
      } else {
        itemSubtotal = newQty * product.sellingPrice;
        itemTaxAmount = itemSubtotal * (taxRate / 100);
      }

      _cart[index] = SaleItem(
        inventoryItem: product,
        quantity: newQty,
        sellingPrice: product.sellingPrice,
        total: itemSubtotal,
        taxAmount: itemTaxAmount,
        isMobile: true,
        id:index.toString(),
      );
    } else {
      final double taxRate = product.tax?.taxPercentage ?? 0.0;
      double itemTaxAmount;
      double itemSubtotal;

      if (_isPriceInclusiveTax) {
        double totalInclusive = 1 * product.sellingPrice;
        itemTaxAmount = totalInclusive - (totalInclusive / (1 + taxRate / 100));
        itemSubtotal = totalInclusive - itemTaxAmount;
      } else {
        itemSubtotal = 1 * product.sellingPrice;
        itemTaxAmount = itemSubtotal * (taxRate / 100);
      }

      _cart.add(SaleItem(
        id: _cart.length.toString(),
        inventoryItem: product,
        quantity: 1.0,
        sellingPrice: product.sellingPrice,
        total: itemSubtotal,
        taxAmount: itemTaxAmount,
        isMobile: true,
      ));
    }
    notifyListeners();
  }

  void removeFromCart(int index) {
    final SaleItem removedItem = _cart[index];
    _cart.removeAt(index);
    final String itemId = removedItem.inventoryItem!.id!;
    _quantityControllers[itemId]?.dispose();
    _quantityControllers.remove(itemId);
    _priceControllers[itemId]?.dispose();
    _priceControllers.remove(itemId);
    _discountControllers[itemId]?.dispose();
    _discountControllers.remove(itemId);
    notifyListeners();
  }

  void updateCartItemDetails(int index, {double? quantity, double? sellingPrice, double? discountAmount}) {
    final SaleItem existingItem = _cart[index];
    final product = existingItem.inventoryItem!;

    final double newQuantity = quantity ?? existingItem.quantity;
    final double newSellingPrice = sellingPrice ?? existingItem.sellingPrice;
    final double newDiscountAmount = discountAmount ?? existingItem.discountAmount;

    if (newQuantity <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quantity must be a positive number.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final BranchStock stock = _allBranchStocks.firstWhere(
      (s) => s.item?.id == product.id && s.branch?.id == _selectedBranch?.id,
      orElse: () => BranchStock(id: '', item: null, branch: null, quantity: 0),
    );

    if (!_allowOutOfStockSales && !product.isService && stock.item != null) {
      if (newQuantity > stock.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not enough stock available for ${product.name}. Max: ${stock.quantity.toStringAsFixed(0)}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // The previous logic for newQuantity == 0 is now handled by the newQuantity <= 0 check above.
    // If newQuantity is 0, it will show an error and return, not remove the item.

    final double taxRate = product.tax?.taxPercentage ?? 0.0;
    double itemTaxAmount;
    double itemSubtotal;
    double subtotalAfterDiscount = (newQuantity * newSellingPrice) - newDiscountAmount;
    if (subtotalAfterDiscount < 0) subtotalAfterDiscount = 0;

    if (_isPriceInclusiveTax) {
      itemTaxAmount = subtotalAfterDiscount - (subtotalAfterDiscount / (1 + taxRate / 100));
      itemSubtotal = subtotalAfterDiscount - itemTaxAmount;
    } else {
      itemTaxAmount = subtotalAfterDiscount * (taxRate / 100);
      itemSubtotal = subtotalAfterDiscount;
    }

    _cart[index] = SaleItem(
      id: index.toString(),
      inventoryItem: product,
      quantity: newQuantity,
      sellingPrice: newSellingPrice,
      discountAmount: newDiscountAmount,
      total: itemSubtotal,
      taxAmount: itemTaxAmount,
      isMobile: true,
    );
    
    notifyListeners();
  }

  void updateCartItemQuantity(int index, double newQuantity) {
    final existingItem = _cart[index];
    updateCartItemDetails(index, quantity: newQuantity, sellingPrice: existingItem.sellingPrice, discountAmount: existingItem.discountAmount);
  }

  Future<MobilePosShift?> _getCurrentShift() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? currentShiftJson = prefs.getString(AppConstants.keyCurrentOpenShift);
    if (currentShiftJson != null && currentShiftJson.isNotEmpty && currentShiftJson != 'null') {
      try {
        return MobilePosShift.fromRawJson(currentShiftJson);
      } on FormatException catch (e) {
        debugPrint('Error decoding MobilePosShift from SharedPreferences: $e');
        await prefs.remove(AppConstants.keyCurrentOpenShift);
        return null;
      }
    }
    return null;
  }

  Future<void> _saveShift(MobilePosShift shift) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyCurrentOpenShift, shift.toJson());

    if (!_isOnline) {
       _shiftService.createShiftOfflineFirst(shift);
      return;
    }

    // We intentionally don't await this so it runs in the background.
    _shiftService.createShift(shift).catchError((e) {
      debugPrint('Failed to sync shift with API: $e');
      return shift;
    });
  }

  Future<void> payFromAccount(BuildContext context) async {
      if (grandTotalConverted <= 0) return;
      if (_selectedCustomer == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a customer to pay from account.'), backgroundColor: Colors.red),
          );
          return;
      }

      final accountPaymentType = _paymentTypes.firstWhere(
        (pt) => pt.name == 'ACC-${_selectedCurrency?.name}' && (pt.currency == null || pt.currency?.id == _selectedCurrency?.id),
        orElse: () => PaymentType(id: 'acc_default', name: 'ACC-${_selectedCurrency?.name}', isCredit: true, currency: _selectedCurrency),
      );

      // Defer customer balance update
      _pendingCustomerBalanceUpdates.add(PendingCustomerBalanceUpdate(
        customerId: _selectedCustomer!.id!,
        currency: _selectedCurrency!,
        amountChange: -balanceDueConverted, // Debit from customer account
      ));

      _payments.add(PaymentReceived(
          amount: balanceDueConverted,
          paymentType: accountPaymentType,
          currency: _selectedCurrency,
          branch: _selectedBranch,
          paymentDescription: 'SALE',
          paymentDate:DateFormat('yyyy-MM-dd').format(DateTime.now()),
          dateTime: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
          isMobile: true,
      ));
      
      notifyListeners();
  }


  Future<void> addPayment(BuildContext context) async {
    if (grandTotalConverted <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add items to the cart before adding payment.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    PaymentType? selectedPaymentType; // Use a local variable for the selected type
    final amountController = TextEditingController(text: balanceDueConverted.toStringAsFixed(2));
    bool addToAccount = false; // State for the checkbox

    final List<PaymentType> filteredPaymentTypes = _paymentTypes.where((pt) {
      final bool matchesCurrency = pt.currency == null || pt.currency?.id == _selectedCurrency?.id;
      final bool allowsCreditWithoutCustomer = !pt.isCredit || _selectedCustomer != null;
      final bool isAlreadySelected = _payments.any((p) => p.paymentType?.id == pt.id); // Check if already selected
      return matchesCurrency && allowsCreditWithoutCustomer && !isAlreadySelected;
    }).toList();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 300.0,
                  width: double.maxFinite,
                  child: ListView(
                    shrinkWrap: true,
                    children: filteredPaymentTypes.map((paymentType) {
                      return RadioListTile<PaymentType>(
                        title: Text(paymentType.name),
                        value: paymentType,
                        groupValue: selectedPaymentType,
                        onChanged: (PaymentType? newValue) {
                          setDialogState(() {
                            selectedPaymentType = newValue;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    setDialogState(() {
                      // Just trigger a rebuild to re-evaluate the checkbox enablement
                    });
                  },
                  onTap: () {
                    amountController.selection = TextSelection(baseOffset: 0, extentOffset: amountController.text.length);
                  },
                ),
                if (_selectedCustomer != null) // Only show if a customer is selected
                  CheckboxListTile(
                    title: const Text('Add remaining to customer account'),
                    value: addToAccount,
                    onChanged: (double.tryParse(amountController.text) ?? 0.0) > balanceDueConverted
                        ? (bool? newValue) {
                            setDialogState(() {
                              addToAccount = newValue ?? false;
                            });
                          }
                        : null, // Disable if amount is not greater than balance due
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => {Navigator.pop(dialogContext), customerSelectFocus = false}, child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedPaymentType == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a payment method.'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (amt <= 0) return;

                // Handle credit payment type (customer paying *from* credit)
                // Skip if it's the specific ACC type which is handled separately
                if (selectedPaymentType?.isCredit == true && !selectedPaymentType!.name.startsWith('ACC-')) {
                  if (_selectedCustomer == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a customer for credit payments.'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  // Defer customer balance update (debit from customer account)
                  _pendingCustomerBalanceUpdates.add(PendingCustomerBalanceUpdate(
                    customerId: _selectedCustomer!.id!,
                    currency: _selectedCurrency!,
                    amountChange: -amt, // Debit from customer account
                  ));
                }

                // Handle payment for the sale and potential overpayment to account
                double paymentForSale = amt;
                double amountToCreditCustomer = 0.0;

                if (amt > grandTotalConverted) {
                  if (_selectedCustomer != null && addToAccount) {
                    amountToCreditCustomer = amt - grandTotalConverted;
                    paymentForSale = grandTotalConverted; // Cap payment for sale at grand total

                    // Defer customer balance update (credit to customer account)
                    _pendingCustomerBalanceUpdates.add(PendingCustomerBalanceUpdate(
                      customerId: _selectedCustomer!.id!,
                      currency: _selectedCurrency!,
                      amountChange: amountToCreditCustomer, // Credit to customer account
                    ));
                  } else {
                    // If not adding to account, or no customer selected,
                    // treat excess as change, payment for sale is still grandTotalConverted
                    paymentForSale = grandTotalConverted;
                  }
                }

                // Add payment for the sale
                _payments.add(PaymentReceived(
                  id: _payments.length.toString(),
                  amount: paymentForSale, // Use paymentForSale here
                  paymentType: selectedPaymentType,
                  currency: _selectedCurrency,
                  branch: _selectedBranch,
                  paymentDescription: 'SALE',
                  paymentDate:DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  dateTime: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
                  isMobile: true,
                ));

                // We DO NOT save payments to the shift here to avoid duplicates.
                // We track account credits separately to be processed in completeSale.
                if (amountToCreditCustomer > 0) {
                  final MobileShiftCurrencyAmount accountCreditShiftAmount = MobileShiftCurrencyAmount(
                    id: 'account_credit_${DateTime.now().millisecondsSinceEpoch}',
                    timeCreated: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
                    active: true,
                    currency: _selectedCurrency!,
                    amount: amountToCreditCustomer,
                    notes: 'Change added to customer account',
                    amountType: 'CASH_IN', // Recorded as Cash In
                    ref: 'customer_credit_${_selectedCustomer!.id}',
                    posReference: null, // Will be set in completeSale
                    shiftReference: null, // Will be set in completeSale
                    isCash: selectedPaymentType?.isCash == true || (selectedPaymentType?.name.toLowerCase().startsWith('cash') ?? false),
                    paymentType: selectedPaymentType!.name,
                  );
                  _pendingAccountCredits.add(accountCreditShiftAmount);
                }

                // Removed notifyListeners() from here
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    // Explicitly unfocus any active field after the dialog closes
    FocusScope.of(context).unfocus();
    notifyListeners(); // This notifyListeners() is sufficient after the dialog closes
    customerSelectFocus = false;
  }

  void updatePaymentAmount(int index, double newAmount) {
    if (index >= 0 && index < _payments.length) {
      final oldPayment = _payments[index];
      _payments[index] = oldPayment.copyWith(amount: newAmount);
      notifyListeners();
    }
  }

  void removePayment(int index) {
    if (index >= 0 && index < _payments.length) {
      _payments.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> completeSale() async {
    if (_isProcessingSale) return;
    _isProcessingSale = true;
    notifyListeners();

    try {
      if (_cart.isEmpty) return;

      if (balanceDueConverted > 0.01) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incomplete payment. Please pay the full balance before completing the sale.'),
            backgroundColor: Colors.red,
          )
        );
        return;
      }
      
      final MobilePosShift? currentShift = await _getCurrentShift();
      if (currentShift == null || (currentShift.isShiftClosed ?? true)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No open shift found. Please open a shift first.')));
        return;
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // --- Apply pending customer balance updates BEFORE saving the sale ---
      if (_pendingCustomerBalanceUpdates.isNotEmpty) {
        List<Customer> currentCustomers = (_isOnline
                ? (prefs.getStringList(AppConstants.keyCustomers) ?? [])
                : (prefs.getStringList(AppConstants.keyOfflineCustomers) ?? []))
            .map((e) => Customer.fromJson(jsonDecode(e)))
            .toList();

        for (var update in _pendingCustomerBalanceUpdates) {
          final int customerIndex = currentCustomers.indexWhere((c) => c.id == update.customerId);

          if (customerIndex != -1) {
            Customer customerToUpdate = currentCustomers[customerIndex];
            List<CustomerCurrencyAmount> updatedAmounts = List.from(customerToUpdate.currencyBalance ?? []);

            final int ccaIndex = updatedAmounts.indexWhere((cca) => cca.currency?.id == update.currency.id);

            if (ccaIndex != -1) {
              updatedAmounts[ccaIndex] = CustomerCurrencyAmount(
                currency: updatedAmounts[ccaIndex].currency,
                balance: (updatedAmounts[ccaIndex].balance ?? 0.0) + update.amountChange,
              );
            } else {
              // If currency balance doesn't exist, add it
              updatedAmounts.add(CustomerCurrencyAmount(
                currency: update.currency,
                balance: update.amountChange,
              ));
            }
            customerToUpdate = customerToUpdate.copyWith(currencyBalance: updatedAmounts);
            currentCustomers[customerIndex] = customerToUpdate;
          } else {
            debugPrint('Error: Customer with ID ${update.customerId} not found for balance update.');
          }
        }
        await prefs.setStringList(_isOnline ? AppConstants.keyCustomers : AppConstants.keyOfflineCustomers, currentCustomers.map((c) => jsonEncode(c.toJson())).toList());
        // Update the _selectedCustomer in the controller if it was part of the updates
        if (_selectedCustomer != null) {
          final updatedSelectedCustomer = currentCustomers.firstWhere((c) => c.id == _selectedCustomer!.id, orElse: () => _selectedCustomer!);
          _selectedCustomer = updatedSelectedCustomer;
        }
        _pendingCustomerBalanceUpdates.clear(); // Clear after applying
      }
      // --- End of pending customer balance updates ---


      final String generatedReference = 'POS-${DateTime.now().millisecondsSinceEpoch}';

      final newSale = Sale(
        id: null,
        createdByName: currentShift.createdByName,
        cashierFullName: currentShift.userFullName,
        customer: _selectedCustomer,
        company: _selectedBranch!.company,
        branch: _selectedBranch,
        items: _cart,
        payments: _payments,
        timeIniated: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
        status: 'Fully Paid',
        currency: _selectedCurrency,
        baseCurrency: _selectedCurrency,
        amountAfterDiscount: grandTotalBase,
        baseSaleAmount: grandTotalBase,
        totalTaxAmount: taxTotalBase,
        isSynced: false,
        fiscalized: false,
        saleStatus: 'COMPLETE',
        taxInvoice: false,
        posReference: generatedReference,
        referenceNumber: generatedReference,
        shiftReference: currentShift.shiftReference,
        ticketName: _ticketName, // Include ticket name in the completed sale
      );
      
      await _saleService.saveSale(newSale);

      // Print receipt based on selected printer and new setting
      try {
        // Only print if the individual sale setting is true, OR if the global "always print" setting is true.
        if (_printerService.isConnected && (_printReceiptForThisSale || _printerService.getAlwaysPrintReceipt())) {
          await _printerService.printSale(newSale);
        }
      } catch (e) {
        print('Error auto-printing receipt: $e');
        // Don't fail the sale if printing fails
      }

      final String stockKey = _isOnline ? AppConstants.keyBranchStock : AppConstants.keyOfflineBranchStock;
      final List<String> stockStrings = prefs.getStringList(stockKey) ?? [];
      final List<BranchStock> allStocks = stockStrings.map((e) => BranchStock.fromJson(jsonDecode(e))).toList();

      for (var cartItem in _cart) {
        if (cartItem.inventoryItem?.isService == true) continue;
        
        final stockIndex = allStocks.indexWhere((s) => 
          s.item?.id == cartItem.inventoryItem?.id &&
          s.branch?.id == _selectedBranch?.id
        );

        if (stockIndex != -1) {
          final stock = allStocks[stockIndex];
          allStocks[stockIndex] = BranchStock(
            id: stock.id,
            branch: stock.branch,
            item: stock.item,
            quantity: stock.quantity - cartItem.quantity,
          );
        }
      }

      await prefs.setStringList(stockKey, allStocks.map((e) => jsonEncode(e.toJson())).toList());

      currentShift.shiftCurrencyAmounts ??= [];
      for (var payment in _payments) {
        final MobileShiftCurrencyAmount paymentShiftAmount = MobileShiftCurrencyAmount(
          id:null,
          dateCreated:null,
          timeCreated: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
          active: true,
          currency: payment.currency!,
          amount: payment.amount,
          notes: 'Payment for sale ${newSale.posReference} via ${payment.paymentType!.name}',
          amountType: 'SALE',
          ref: newSale.posReference, // Changed to use posReference as ID is null initially
          posReference: newSale.posReference,
          shiftReference: currentShift.shiftReference,
          isCash: payment.paymentType!.isCash == true || (payment.paymentType!.name.toLowerCase().startsWith('cash')),
          paymentType: payment.paymentType!.name,
        );
        currentShift.shiftCurrencyAmounts!.add(paymentShiftAmount);
      }
      
      for (var accountCredit in _pendingAccountCredits) {
        accountCredit.posReference = newSale.posReference;
        accountCredit.shiftReference = currentShift.shiftReference;
        currentShift.shiftCurrencyAmounts!.add(accountCredit);
      }
      _pendingAccountCredits.clear();

      _saveShift(currentShift); // Run in background

      if (!context.mounted) return;


      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale completed successfully'), backgroundColor: Colors.green));

      // Show receipt screen or option to view it
      /*await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sale Complete'),
          content: const Text('Would you like to view or reprint the receipt?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SaleReceiptScreen(sale: newSale)),
                );
              },
              child: const Text('View Receipt'),
            ),
          ],
        ),
      );*/

      await clearPOSScreen(); // Await clearPOSScreen
    } finally {
      _isProcessingSale = false;
      notifyListeners();
    }
  }

  Future<void> clearPOSScreen({Customer? newCustomer}) async {
    if (newCustomer == null) {
      _cart.clear();
      _payments.clear();
      _pendingAccountCredits.clear();
      _pendingCustomerBalanceUpdates.clear(); // Clear pending balance updates
      _selectedCustomer = null;
      _ticketName = null; // Clear ticket name
      _disposeQuantityControllers();
    } else {
      _selectedCustomer = newCustomer;
    }
    _searchController.clear();
    _customerSearchController.clear();
    _searchQuery = '';
    _applyFilters();
    await _loadData(); // Await the asynchronous data loading
    _printReceiptForThisSale = _printerService.getAlwaysPrintReceipt(); // Reset to global setting
    notifyListeners();
  }

  Future<void> _loadHeldSalesCount() async {
    final heldSales = await retrieveHeldSales();
    _heldSalesCount = heldSales.length;
    notifyListeners();
  }

  Future<void> holdSale() async {
    if (_cart.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot hold an empty sale.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Sale> heldSales = await retrieveHeldSales();
    final int nextTicketNumber = heldSales.length + 1;
    final String suggestedTicketName = 'Ticket $nextTicketNumber';

    final TextEditingController ticketNameController = TextEditingController(text: suggestedTicketName);

    String? ticketName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hold Sale as Ticket'),
        content: TextField(
          controller: ticketNameController,
          decoration: const InputDecoration(
            labelText: 'Ticket Name',
            hintText: 'e.g., Customer A, Order #123',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null), // Return null if cancelled
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, ticketNameController.text),
            child: const Text('Hold'),
          ),
        ],
      ),
    );

    if (ticketName == null || ticketName.trim().isEmpty) {
      // User cancelled or entered empty name, do not hold sale
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale not held. Ticket name is required.'), backgroundColor: Colors.red),
      );
      return;
    }

    final MobilePosShift? currentShift = await _getCurrentShift();

    final heldSale = Sale(
      id: 'held_${DateTime.now().millisecondsSinceEpoch}',
      createdByName: currentShift?.createdByName,
      cashierFullName: currentShift?.userFullName,
      customer: _selectedCustomer,
      branch: _selectedBranch,
      items: List.from(_cart),
      payments: List.from(_payments),
      timeIniated: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
      status: 'On Hold',
      currency: _selectedCurrency,
      shiftReference: currentShift?.shiftReference,
      totalTaxAmount: taxTotalBase,
      amountAfterDiscount: grandTotalBase,
      ticketName: ticketName, // Assign the entered ticket name
    );

    heldSales.add(heldSale); // Add the new held sale to the list
    await prefs.setStringList(AppConstants.keyHeldSales, heldSales.map((s) => jsonEncode(s.toJson())).toList());

    _ticketName = ticketName; // Set the controller's ticket name
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sale placed on hold as "$ticketName".'), backgroundColor: Colors.blue),
    );
    clearPOSScreen();
    await _loadHeldSalesCount();
    notifyListeners();
  }

  Future<List<Sale>> retrieveHeldSales() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> heldSalesJson = prefs.getStringList(AppConstants.keyHeldSales) ?? [];
    return heldSalesJson.map((jsonString) => Sale.fromJson(jsonDecode(jsonString))).toList();
  }

  void loadHeldSale(Sale heldSale) {
    _cart.clear();
    _payments.clear();
    _pendingAccountCredits.clear(); // Reset pending credits
    _pendingCustomerBalanceUpdates.clear(); // Clear pending balance updates
    _disposeQuantityControllers();

    _cart.addAll(heldSale.items);
    _payments.addAll(heldSale.payments ?? []);
    _selectedCustomer = heldSale.customer;
    _selectedCurrency = heldSale.currency;
    _ticketName = heldSale.ticketName; // Load ticket name

    for (var item in _cart) {
      if (item.inventoryItem?.id != null) {
        _quantityControllers[item.inventoryItem!.id!] = TextEditingController(text: item.quantity.toStringAsFixed(2));
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Held sale for ${heldSale.ticketName ?? 'Guest'} loaded.'), backgroundColor: Colors.green),
    );
    _printReceiptForThisSale = _printerService.getAlwaysPrintReceipt(); // Reset to global setting
    notifyListeners();
  }

  Future<void> removeHeldSale(String saleId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> heldSalesJson = prefs.getStringList(AppConstants.keyHeldSales) ?? [];

    heldSalesJson.removeWhere((jsonString) {
      final sale = Sale.fromJson(jsonDecode(jsonString));
      return sale.id == saleId;
    });

    await prefs.setStringList(AppConstants.keyHeldSales, heldSalesJson);
    await _loadHeldSalesCount();
    notifyListeners();
  }

  Future<void> quickCashSale() async {
    if (_isProcessingSale) return;
    _isProcessingSale = true;
    notifyListeners();

    try {
      if (_cart.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty!')));
        return;
      }

      if (balanceDueConverted > 0.01) {
        final cashPaymentType = _paymentTypes.firstWhere(
          (pt) => (pt.isCash == true || pt.name.toLowerCase().startsWith('cash')) && (pt.currency == null || pt.currency?.id == _selectedCurrency?.id),
          orElse: () => PaymentType(id: 'cash_default', name: 'Cash', isCash: true),
        );

        _payments.add(PaymentReceived(
          amount: balanceDueConverted,
          paymentType: cashPaymentType,
          currency: _selectedCurrency,
          branch: _selectedBranch, // Add the selected branch here
          paymentDescription: 'SALE',
          paymentDate:DateFormat('yyyy-MM-dd').format(DateTime.now()),
          dateTime: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
          isMobile: true,
        ));

        // We no longer save payments to the shift here to avoid duplicates.
        // It will be done in completeSale.
      }

      // Need to unset _isProcessingSale before calling completeSale
      // because completeSale checks it too.
      _isProcessingSale = false;
      await completeSale();
    } finally {
      // Ensures it's reset even if an exception occurs
      _isProcessingSale = false;
      notifyListeners();
    }
  }

}
