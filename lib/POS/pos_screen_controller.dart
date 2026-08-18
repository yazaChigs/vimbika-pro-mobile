import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:vimbika_pro/model/sale_item.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/payment_type.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:vimbika_pro/model/sale_status.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/bank.dart';
import 'package:vimbika_pro/model/category.dart' as model;
import 'package:vimbika_pro/model/customer_currency_amount.dart';
import 'package:vimbika_pro/model/mobile_pos_shift.dart';
import 'package:vimbika_pro/model/mobile_shift_currency_amount.dart';
import 'package:vimbika_pro/services/branch_stock_service.dart';
import 'package:vimbika_pro/services/customer_service.dart';
import 'package:vimbika_pro/shift/shift_management_screen.dart';
import 'package:vimbika_pro/services/mobile_shift_service.dart';
import 'package:vimbika_pro/services/sale_service.dart';
import 'package:vimbika_pro/services/printer_service.dart';
import 'package:vimbika_pro/services/currency_service.dart';
import 'package:vimbika_pro/services/payments_service.dart';
import 'package:vimbika_pro/services/bank_service.dart';
import 'package:vimbika_pro/services/category_service.dart';
import 'package:vimbika_pro/services/excel_export_service.dart';
import 'package:vimbika_pro/services/isar_service.dart';

/// Represents a pending update to a customer's balance, to be applied at sale completion.
class PendingCustomerBalanceUpdate {
  final String customerId;
  final String customerName;
  final Currency currency;
  final double amountChange; // Positive for credit, negative for debit

  PendingCustomerBalanceUpdate({
    required this.customerId,
    required this.customerName,
    required this.currency,
    required this.amountChange,
  });
}

class POSScreenController extends ChangeNotifier {
  final BuildContext context; // Keep context for SnackBar, etc.
  final MobilePosShiftService _shiftService = MobilePosShiftService();
  final SaleService _saleService = SaleService();
  final PrinterService _printerService = PrinterService(); // Instantiate PrinterService
  final CustomerService _customerService = CustomerService();
  final BranchStockService _branchStockService = BranchStockService();
  final PaymentsService _paymentsService = PaymentsService();
  final ExcelExportService _excelExportService = ExcelExportService(); // Instantiate ExcelExportService
  final IsarService _isarService = IsarService();

  POSScreenController(this.context) {
    _checkOpenShift();
    _loadData();
    _loadHeldSalesCount();
    _loadPrinterSettings(); // Load printer settings on init
    _customerSearchController.addListener(_onCustomerSearchChanged);
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
  bool _useKOT = false;
  bool _isBarcodeSearchMode = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _scanController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // Declare FocusNode
  final FocusNode _scanFocusNode = FocusNode();
  final TextEditingController _customerSearchController = TextEditingController();
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _discountControllers = {};
  final Map<String, TextEditingController> _noteControllers = {};

  bool _isDownloadingStock = false;
  bool _isProcessingSale = false;
  bool _isOnline = false; // Added for offline/online mode

  int _heldSalesCount = 0;
  String? _heldSaleId;
  String? _ticketName; // New property for held sale ticket name
  bool _printReceiptForThisSale = false; // New setting for individual sale printing
  bool _fiscalizeThisSale = false; // New setting for individual sale fiscalisation
  bool _customerSelectFocus = true;
  int? _currentOrderKOTNumber;
  int? _heldOrderKOTNumber;

  final TextEditingController _amountTenderedController = TextEditingController(); // Controller for tendered amount

  Future<int?> _getOrGenerateKOTNumber() async {
    if (_currentOrderKOTNumber != null) return _currentOrderKOTNumber;

    if (!_useKOT) return null;

    final MobilePosShift? currentShift = await _getCurrentShift();
    if (currentShift != null && !(currentShift.isShiftClosed ?? true)) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get the current kotNumber from shift and from separate local storage for tracking
      int shiftKOT = currentShift.kotNumber ?? 0;
      int lastSavedKOT = prefs.getInt(AppConstants.keyLastKOTNumber) ?? 0;
      
      // Ensure we use the highest tracked number to avoid duplicates after sync resets
      int nextNumber = (shiftKOT > lastSavedKOT ? shiftKOT : lastSavedKOT) + 1;
      
      currentShift.kotNumber = nextNumber;
      await _saveShift(currentShift);
      
      // Also update the separate local storage as a backup
      await prefs.setInt(AppConstants.keyLastKOTNumber, nextNumber);
      
      _currentOrderKOTNumber = nextNumber;
      return _currentOrderKOTNumber;
    }
    return null;
  }

  double get totalAmtToAcc => amountToAccountConverted;

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
  bool get useKOT => _useKOT;
  bool get isBarcodeSearchMode => _isBarcodeSearchMode;
  TextEditingController get searchController => _searchController;
  TextEditingController get scanController => _scanController;
  FocusNode get searchFocusNode => _searchFocusNode; // Getter for FocusNode
  FocusNode get scanFocusNode => _scanFocusNode;
  TextEditingController get customerSearchController => _customerSearchController;
  Map<String, TextEditingController> get quantityControllers => _quantityControllers;
  Map<String, TextEditingController> get priceControllers => _priceControllers;
  Map<String, TextEditingController> get discountControllers => _discountControllers;
  Map<String, TextEditingController> get noteControllers => _noteControllers;
  bool get isDownloadingStock => _isDownloadingStock;
  bool get isProcessingSale => _isProcessingSale;
  int get heldSalesCount => _heldSalesCount;
  String? get ticketName => _ticketName; // Getter for ticket name
  bool get printReceiptForThisSale => _printReceiptForThisSale; // Getter for new setting
  bool get fiscalizeThisSale => _fiscalizeThisSale; // Getter for new setting
  bool get isFiscalisationEnabled => _printerService.getFiscalisationEnabled();
  bool get isPrinterConfigured => _printerService.isPrinterConfigured;
  bool get customerSelectFocus => _customerSelectFocus; // Getter for new setting
  TextEditingController get amountTenderedController => _amountTenderedController; // Getter for amount tendered controller

  // Setter for new setting
  set printReceiptForThisSale(bool value) {
    if (!isPrinterConfigured) return;
    _printReceiptForThisSale = value;
    notifyListeners();
  }

  // Setter for new setting
  set fiscalizeThisSale(bool value) {
    _fiscalizeThisSale = value;
    notifyListeners();
  }

  // Setter for new setting
  set customerSelectFocus(bool value) {
    _customerSelectFocus = value;
    notifyListeners();
  }

  Future<void> _loadPrinterSettings() async {
    await _printerService.init(); // Ensure printer service is initialized
    _printReceiptForThisSale = _printerService.getAlwaysPrintReceipt() && _printerService.isPrinterConfigured; // Initialize with global setting
    _fiscalizeThisSale = _printerService.getFiscalisationEnabled() && _printerService.getAlwaysFiscalize(); // Initialize with global setting
    notifyListeners();
  }

  // Setters for updating state and notifying listeners
  set selectedCurrency(Currency? currency) {
    _selectedCurrency = currency;
    // Clear payments when currency changes as payments are in the selected currency
    _payments.clear();
    _pendingCustomerBalanceUpdates.clear(); // Clear pending balance updates
    _amountTenderedController.clear(); // Clear tendered amount controller
    notifyListeners();
  }

  set selectedCustomer(Customer? customer) {
    _selectedCustomer = customer;
    if (customer != null) {
      customer.loadAll();
    }
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
    if (_isBarcodeSearchMode) {
      _searchController.clear();
      _searchQuery = '';
      _applyFilters();
      _scanFocusNode.requestFocus();
    } else {
      _scanController.clear();
      _searchQuery = '';
      _applyFilters();
      _searchFocusNode.requestFocus();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scanController.dispose();
    _searchFocusNode.dispose(); // Dispose FocusNode
    _scanFocusNode.dispose();
    _customerSearchController.removeListener(_onCustomerSearchChanged);
    _customerSearchController.dispose();
    _amountTenderedController.dispose(); // Dispose tendered amount controller
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
    _noteControllers.forEach((key, controller) => controller.dispose());
    _noteControllers.clear();
  }

  void _onCustomerSearchChanged() {
    final query = _customerSearchController.text;
    if (query.isNotEmpty) {
      try {
        final customer = _customers.firstWhere(
          (c) => c.accountNumber == query,
        );
        selectedCustomer = customer;
      } catch (e) {
        // Customer not found, do nothing
      }
    }
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

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // Determine online/offline mode
      _isOnline = !(prefs.getBool(AppConstants.keyIsOfflineMode) ?? false);

      final List<String> currencyJson = _isOnline
          ? (prefs.getStringList(AppConstants.keyCurrencies) ?? [])
          : (prefs.getStringList(AppConstants.keyOfflineCurrencies) ?? []);
      final List<String> paymentTypeJson = _isOnline
          ? (prefs.getStringList(AppConstants.keyPaymentTypes) ?? [])
          : (prefs.getStringList(AppConstants.keyOfflinePaymentTypes) ?? []);

      final List<String> catJson = _isOnline
          ? (prefs.getStringList(AppConstants.keyCategories) ?? [])
          : (prefs.getStringList(AppConstants.keyOfflineCategories) ?? []);

      Branch? defaultBranch;
      final String? dBranchJson = _isOnline
          ? prefs.getString(AppConstants.keyDefaultBranch)
          : prefs.getString(AppConstants.keyOfflineBranch);
      if (dBranchJson != null) {
        try {
          defaultBranch = Branch.fromJson(jsonDecode(dBranchJson));
        } catch (e) {
          debugPrint("Error parsing default branch: $e");
        }
      }

      _allBranchStocks = await _branchStockService.getBranchStocksLocally();

      _currencies = currencyJson.map((e) {
        try {
          return Currency.fromJson(jsonDecode(e));
        } catch (err) {
          debugPrint("Error parsing currency: $err");
          return null;
        }
      }).whereNotNull().toList();

      // Only load active payment types and exclude those containing "Credit" in their name
      _paymentTypes = paymentTypeJson
          .map((e) {
            try {
              return PaymentType.fromJson(jsonDecode(e));
            } catch (err) {
              debugPrint("Error parsing payment type: $err");
              return null;
            }
          })
          .whereNotNull()
          .where((pt) => pt.active && !pt.name.toLowerCase().contains('credit'))
          .toList();

      _customers = await _customerService.getCustomersLocally();
      _categories = catJson.map((e) {
        try {
          return model.Category.fromJson(jsonDecode(e));
        } catch (err) {
          debugPrint("Error parsing category: $err");
          return null;
        }
      }).whereNotNull().toList();

      _selectedBranch = defaultBranch;

      _allowOutOfStockSales = prefs.getBool(AppConstants.keyAllowOutOfStockSales) ?? false;
      _useKOT = prefs.getBool(AppConstants.keyUseKOT) ?? false;

      if (_currencies.isNotEmpty) {
        _selectedCurrency = _currencies.firstWhere(
                (c) => c.isBaseCurrency == true,
            orElse: () => _currencies.first
        );
      }

      _applyFilters();
    } catch (e) {
      debugPrint("Error in _loadData: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Only attempt to download stock if online and local stock is empty
    if (_isOnline && _allBranchStocks.isEmpty && _selectedBranch != null) {
      downloadStockForDefaultBranch();
    }
  }

  Future<void> downloadStockForDefaultBranch() async {
    if (_selectedBranch?.id == null) return;

    _isDownloadingStock = true;
    notifyListeners();

    try {
      final newStocks = await _branchStockService.fetchStockByBranch(_selectedBranch!);

      // Save to SharedPreferences via BranchStockService
      await _branchStockService.saveBranchStocksLocally(newStocks);

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

  Future<void> downloadOtherData() async {
    if (!_isOnline) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This feature is only available online.')));
      }
      return;
    }

    _isDownloadingStock = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyService = CurrencyService();
      final paymentTypeService = PaymentsService();
      final bankService = BankService();
      // final taxService = TaxService();
      final categoryService = CategoryService();

      final List<Currency> currencies = await currencyService.fetchCurrencies();
      final List<PaymentType> paymentTypes = await paymentTypeService.fetchPaymentTypes();
      final List<Bank> banks = await bankService.fetchBanks();
      // final List<Tax> taxes = await taxService.fetchTaxes();
      final String? branchId = _selectedBranch?.id;
      final List<model.Category> categories = branchId != null ? await categoryService.fetchCategoriesByBranch(branchId) : [];
      final List<Customer> customers = await _customerService.fetchCustomers();

      await prefs.setStringList(AppConstants.keyCurrencies, currencies.map((c) => jsonEncode(c.toJson())).toList());
      await prefs.setStringList(AppConstants.keyPaymentTypes, paymentTypes.map((p) => jsonEncode(p.toJson())).toList());
      await prefs.setStringList(AppConstants.keyBanks, banks.map((b) => jsonEncode(b.toJson())).toList());
      // await prefs.setStringList(AppConstants.keyTaxes, taxes.map((t) => jsonEncode(t.toJson())).toList());
      await prefs.setStringList(AppConstants.keyCategories, categories.map((c) => jsonEncode(c.toJson())).toList());
      await prefs.setStringList(AppConstants.keyCustomers, customers.map((c) => jsonEncode(c.toJson())).toList());

      await _loadData();
      
      // Refresh selected customer from the reloaded list to ensure we have the latest object
      if (_selectedCustomer != null) {
        _selectedCustomer = _customers.firstWhereOrNull((c) => 
          (_selectedCustomer!.id != null && c.id == _selectedCustomer!.id) ||
          (c.name.toLowerCase() == _selectedCustomer!.name.toLowerCase())
        ) ?? _selectedCustomer;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data downloaded successfully.')));
      }
    } catch (e) {
      debugPrint("Failed to download other data: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download data: $e')));
      }
    } finally {
      _isDownloadingStock = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    _filteredBranchStocks = _allBranchStocks.where((s) {
      final matchesBranch = _selectedBranch == null || s.branch.value?.id == _selectedBranch?.id;
      final matchesCategory = _selectedCategory == null || s.item.value?.category.value?.id == _selectedCategory!.id;

      bool matchesSearch;
      if (_isBarcodeSearchMode) {
        if (_searchQuery.isEmpty) { // Added condition
          matchesSearch = true; // Show all items if barcode search is active but query is empty
        } else {
          matchesSearch = s.item.value?.itemCode == _searchQuery;
        }
      } else {
        matchesSearch = (s.item.value?.name.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (s.item.value?.itemCode?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }

      return matchesBranch && matchesCategory && matchesSearch;
    }).toList();
    notifyListeners();
  }

  double get subTotalBase => _cart.fold(0, (sum, item) => sum + item.total);

  double get taxTotalBase => _cart.fold(0, (sum, item) => sum + item.taxAmount);

  double get grandTotalBase => subTotalBase;

  double get grandTotalConverted => grandTotalBase * (_selectedCurrency?.rate ?? 1.0);
  double get amountPaidConverted => _payments.fold(0, (sum, item) => sum + item.amount);
  double get totalAmountTendered => _payments.fold(0, (sum, item) => sum + (item.amountTendered ?? item.amount));

  double get changeConverted {
    final overpayment = totalAmountTendered - amountPaidConverted;
    if (overpayment <= 0) return 0.0;
    final change = overpayment - amountToAccountConverted;
    return change > 0 ? change : 0.0;
  }

  double get amountToAccountConverted {
    return _payments.fold(0.0, (sum, p) => sum + p.amountAddedToAccount);
  }

  double get totalReceivedConverted => totalAmountTendered + amountToAccountConverted;
  
  // Reworked to be simpler and more reliable
  double get balanceDueConverted {
    return grandTotalConverted - amountPaidConverted;
  }

  Bank? _getCorrectBank(PaymentType? paymentType, Currency? currency) {
    if (currency != null && paymentType != null) {
      final banks = paymentType.allBanks;
      if (banks.isNotEmpty) {
        if(paymentType.name.toLowerCase().startsWith('cash')){
          Bank? bank = banks.firstWhereOrNull((test)=>test.bankName!.toLowerCase().startsWith('cash'));
          if(bank != null){
            return bank;
          }
        }
        for (Bank bank in banks) {
          print('bank: ${bank.bankName}');
          if (bank.currency.value?.id == currency.id) {
            return bank;
          }
        }
      } else {
        debugPrint('No banks associated with the selected payment type.');
      }
    } else {
      debugPrint('Either currency or paymentType is null.');
    }
    return null;
  }

  void _recalculateAppliedAmounts() {
    double balanceToCover = grandTotalConverted;
    final List<PaymentReceived> originalPayments = List.from(_payments);
    _payments.clear();

    _pendingCustomerBalanceUpdates.clear();
    _pendingAccountCredits.clear();

    for (final payment in originalPayments) {
      // Use the tendered amount if available, otherwise the amount itself.
      double tendered = payment.amountTendered ?? payment.amount;
      double amountToApply = 0;

      if (balanceToCover > 0) {
        amountToApply = (tendered < balanceToCover) ? tendered : balanceToCover;
        balanceToCover -= amountToApply;
      }

      double overpayment = tendered - amountToApply;
      double actualAddedToAccount = payment.amountAddedToAccount;
      if (actualAddedToAccount > overpayment) {
        actualAddedToAccount = overpayment;
      }
      if (actualAddedToAccount < 0) actualAddedToAccount = 0;

      // Add the payment back with the corrected applied amount, preserving the original tendered amount.
      final updatedPayment = payment.copyWith(
        amount: amountToApply,
        amountAddedToAccount: actualAddedToAccount,
      );
      _payments.add(updatedPayment);

      if (_selectedCustomer != null && _selectedCustomer!.id != null) {
        if (updatedPayment.paymentType.value?.isCredit == true) {
          _pendingCustomerBalanceUpdates.add(PendingCustomerBalanceUpdate(
            customerId: _selectedCustomer!.id!,
            currency: _selectedCurrency!,
            customerName: _selectedCustomer!.name,
            amountChange: -amountToApply, // Debit from customer account
          ));
        }

        if (actualAddedToAccount > 0) {
          _pendingCustomerBalanceUpdates.add(PendingCustomerBalanceUpdate(
            customerId: _selectedCustomer!.id!,
            customerName: _selectedCustomer!.name,
            currency: _selectedCurrency!,
            amountChange: actualAddedToAccount, // Credit to customer account
          ));

          final String paymentTypeName = updatedPayment.paymentType.value?.name ?? 'Unknown';
          final existingAccountCreditIndex = _pendingAccountCredits.indexWhere((ac) => ac.paymentType == paymentTypeName);

          if (existingAccountCreditIndex != -1) {
            final existingAccountCredit = _pendingAccountCredits[existingAccountCreditIndex];
            _pendingAccountCredits[existingAccountCreditIndex] = existingAccountCredit.copyWith(
              amount: existingAccountCredit.amount + actualAddedToAccount,
            );
          } else {
            final MobileShiftCurrencyAmount accountCreditShiftAmount = MobileShiftCurrencyAmount(
              id: null,
              timeCreated: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
              active: true,
              currency: _selectedCurrency!,
              amount: actualAddedToAccount,
              notes: 'Change added to customer account',
              amountType: 'ACCOUNT_TOP_UP',
              ref: 'CA_${DateTime.now().millisecondsSinceEpoch}',
              posReference: null,
              shiftReference: null,
              isCash: updatedPayment.paymentType.value?.isCash == true || (updatedPayment.paymentType.value?.name.toLowerCase().startsWith('cash') ?? false),
              paymentType: paymentTypeName,
            );
            _pendingAccountCredits.add(accountCreditShiftAmount);
          }
        }
      }
    }
  }

  void _adjustPayments() {
    _recalculateAppliedAmounts();
  }

  Future<void> addToCart(BranchStock stock) async {
    final product = stock.item.value;
    if (product == null) return;

    // Eagerly load all nested properties of the product.
    await product.loadAll();

    if (!_allowOutOfStockSales && !product.isService) {
      final cartItemIndex = _cart.indexWhere((item) => item.inventoryItem.value?.id == product.id);
      double currentCartQty = 0;
      if (cartItemIndex != -1) {
        currentCartQty = _cart[cartItemIndex].quantity;
      }

      if (stock.stock <= currentCartQty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not enough stock available'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    final index = _cart.indexWhere((item) => item.inventoryItem.value?.id == product.id);
    if (index != -1) {
      final existingItem = _cart[index];
      final double newQty = existingItem.quantity + 1;
      final double taxRate = product.tax.value?.taxPercentage ?? 0.0;
      double itemTaxAmount;
      double totalInclusive = newQty * product.sellingPrice;
      itemTaxAmount = totalInclusive - (totalInclusive / (1 + taxRate / 100));

      _cart[index] = SaleItem(
        id: existingItem.id,
        quantity: newQty,
        sellingPrice: product.sellingPrice,
        total: totalInclusive,
        taxAmount: itemTaxAmount,
        isMobile: true,
        notes: existingItem.notes,
      );
      _cart[index].inventoryItem.value = product;
    } else {
      final double taxRate = product.tax.value?.taxPercentage ?? 0.0;
      double itemTaxAmount;
      double totalInclusive = 1 * product.sellingPrice;
      itemTaxAmount = totalInclusive - (totalInclusive / (1 + taxRate / 100));

      SaleItem saleItem = SaleItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        quantity: 1.0,
        sellingPrice: product.sellingPrice,
        total: totalInclusive,
        taxAmount: itemTaxAmount,
        isMobile: true,
      );
      saleItem.inventoryItem.value = product;
      _cart.add(saleItem);
    }
    _amountTenderedController.clear(); // Clear tendered amount controller
    notifyListeners();
  }

  void removeFromCart(int index) {
    final SaleItem removedItem = _cart[index];
    _cart.removeAt(index);
    final String itemId = removedItem.inventoryItem.value!.id!;
    _quantityControllers[itemId]?.dispose();
    _quantityControllers.remove(itemId);
    _priceControllers[itemId]?.dispose();
    _priceControllers.remove(itemId);
    _discountControllers[itemId]?.dispose();
    _discountControllers.remove(itemId);
    _noteControllers[itemId]?.dispose();
    _noteControllers.remove(itemId);
    _adjustPayments();
    _amountTenderedController.clear(); // Clear tendered amount controller
    notifyListeners();
  }

  void updateCartItemDetails(int index, {double? quantity, double? sellingPrice, double? discountAmount}) {
    final SaleItem existingItem = _cart[index];
    final product = existingItem.inventoryItem.value!;

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
          (s) => s.item.value?.id == product.id && s.branch.value?.id == _selectedBranch?.id,
      orElse: () {
        final bs = BranchStock(id: '', stock: 0);
        return bs;
      },
    );

    if (!_allowOutOfStockSales && !product.isService && stock.item.value != null) {
      if (newQuantity > stock.stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Not enough stock available for ${product.name}. Max: ${stock.stock.toStringAsFixed(0)}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    // The previous logic for newQuantity == 0 is now handled by the newQuantity <= 0 check above.
    // If newQuantity is 0, it will show an error and return, not remove the item.

    final double taxRate = product.tax.value?.taxPercentage ?? 0.0;
    double itemTaxAmount;
    double subtotalAfterDiscount = (newQuantity * newSellingPrice) - newDiscountAmount;
    if (subtotalAfterDiscount < 0) subtotalAfterDiscount = 0;
    itemTaxAmount = subtotalAfterDiscount - (subtotalAfterDiscount / (1 + taxRate / 100));

    _cart[index] = SaleItem(
      id: existingItem.id,
      // inventoryItem: product,
      quantity: newQuantity,
      sellingPrice: newSellingPrice,
      discountAmount: newDiscountAmount,
      total: subtotalAfterDiscount,
      taxAmount: itemTaxAmount,
      isMobile: true,
      notes: existingItem.notes,
    );
    _cart[index].inventoryItem.value = product;
    _adjustPayments();
    _amountTenderedController.clear(); // Clear tendered amount controller
    notifyListeners();
  }

  void updateCartItemQuantity(int index, double newQuantity) {
    final existingItem = _cart[index];
    updateCartItemDetails(index, quantity: newQuantity, sellingPrice: existingItem.sellingPrice, discountAmount: existingItem.discountAmount);
  }

  void updateCartItemNote(int index, String note) {
    final existingItem = _cart[index];
    final product = existingItem.inventoryItem.value!;

    _cart[index] = existingItem.copyWith(notes: note);
    _cart[index].inventoryItem.value = product;
    notifyListeners();
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
    if (_selectedCustomer!.id == null) {
      print(_selectedCustomer!.toJson());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected customer does not have a valid ID. Cannot pay from account.'), backgroundColor: Colors.red),
      );
      return;
    }

    final accountPaymentType = _paymentTypes.firstWhere(
          (pt) => pt.name == 'ACC-${_selectedCurrency?.name}' && (pt.currency.value == null || pt.currency.value?.id == _selectedCurrency?.id),
      orElse: () => PaymentType(id: 'acc_default', name: 'ACC-${_selectedCurrency?.name}', isCredit: true, currency: _selectedCurrency),
    );

    // Check if this payment type already exists
    final existingPaymentIndex = _payments.indexWhere((p) => p.paymentType.value?.name == accountPaymentType.name);

      if (existingPaymentIndex != -1) {
        // Update existing payment
        final existingPayment = _payments[existingPaymentIndex];
        _payments[existingPaymentIndex] = existingPayment.copyWith(
          amount: existingPayment.amount + balanceDueConverted,
        );
      } else {
        // Add new payment
        _payments.add(PaymentReceived(
            id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
            amount: balanceDueConverted,
            paymentType: accountPaymentType,
            currency: _selectedCurrency,
            branch: _selectedBranch,
            paymentDescription: 'SALE',
            paymentDate:DateFormat('yyyy-MM-dd').format(DateTime.now()),
            dateTime: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
            isMobile: true,
            bank: _getCorrectBank(accountPaymentType, _selectedCurrency),
        ));
      }
      _recalculateAppliedAmounts();
      _amountTenderedController.text = totalAmountTendered.toStringAsFixed(2);
      notifyListeners();
  }


  Future<void> addPayment(BuildContext context) async {
    customerSelectFocus = false;
    if (grandTotalConverted <= 0 && _selectedCustomer == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add items to the cart or select a customer to add an account payment.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    PaymentType? selectedPaymentType; // Use a local variable for the selected type
    final amountController = TextEditingController(text: balanceDueConverted > 0 ? balanceDueConverted.toStringAsFixed(2) : '');
    final accountCreditController = TextEditingController();

    bool addToAccount = _cart.isEmpty && _selectedCustomer != null; // State for the checkbox
    if (addToAccount) {
      accountCreditController.text = amountController.text;
    }
    bool isProcessingDeposit = false;

    final usedPaymentTypeIds = _payments.map((p) => p.paymentType.value?.id).toSet();
    final List<PaymentType> filteredPaymentTypes = _paymentTypes.where((pt) {
      final isAlreadyUsed = usedPaymentTypeIds.contains(pt.id);
      if (isAlreadyUsed) {
        return false; // Exclude if already used
      }

      final bool matchesCurrency = pt.currency.value == null || pt.currency.value?.id == _selectedCurrency?.id;
      final bool allowsCreditWithoutCustomer = !pt.isCredit || _selectedCustomer != null;

      // If cart is empty, only show non-credit payment types
      if (_cart.isEmpty) {
        return matchesCurrency && allowsCreditWithoutCustomer && !pt.isCredit;
      }

      return matchesCurrency && allowsCreditWithoutCustomer;
    }).toList();

    bool dialogResult = await showDialog(
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
                  onChanged: (val) {
                    setDialogState(() {
                      // Just trigger a rebuild to re-evaluate the checkbox enablement
                      if (addToAccount) {
                        var amt = double.tryParse(val) ?? 0.0;
                        var overpayment = _cart.isEmpty ? amt : (amt > balanceDueConverted ? amt - balanceDueConverted : 0.0);
                        accountCreditController.text = overpayment.toStringAsFixed(2);
                      }
                    });
                  },
                  onTap: () {
                    amountController.selection = TextSelection(baseOffset: 0, extentOffset: amountController.text.length);
                  },
                ),
                if (_selectedCustomer != null && _cart.isNotEmpty) // Only show if a customer is selected and cart is not empty
                  CheckboxListTile(
                    title: const Text('Add remaining to customer account'),
                    value: addToAccount,
                    onChanged: (double.tryParse(amountController.text) ?? 0.0) > balanceDueConverted || _cart.isEmpty
                        ? (bool? newValue) {
                      setDialogState(() {
                        addToAccount = newValue ?? false;
                        if (addToAccount) {
                          var amt = double.tryParse(amountController.text) ?? 0.0;
                          var overpayment = _cart.isEmpty ? amt : (amt > balanceDueConverted ? amt - balanceDueConverted : 0.0);
                          accountCreditController.text = overpayment.toStringAsFixed(2);
                        }
                      });
                    }
                        : null, // Disable if amount is not greater than balance due and cart is not empty
                  ),
                if (_selectedCustomer != null && _cart.isNotEmpty && addToAccount && (double.tryParse(amountController.text) ?? 0.0) > balanceDueConverted)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: accountCreditController,
                      decoration: const InputDecoration(labelText: 'Amount to add to account'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => {Navigator.pop(dialogContext, false), customerSelectFocus = false}, child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isProcessingDeposit ? null : () async {
                if (selectedPaymentType == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a payment method.'), backgroundColor: Colors.red),
                  );
                  return;
                }
                var amt = double.tryParse(amountController.text) ?? 0.0;
                if (amt <= 0) return;

                if (_cart.isEmpty) {
                  if (_selectedCustomer == null) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a customer to add a deposit.'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  setDialogState(() {
                    isProcessingDeposit = true;
                  });

                  final bank = _getCorrectBank(selectedPaymentType, _selectedCurrency);
                  final payment = await addCustomerDeposit(_selectedCustomer!, _selectedCurrency!, selectedPaymentType!, amt, selectedBank: bank);

                  if (!context.mounted) return;
                  if (payment != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deposit added successfully'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(dialogContext, true);
                    final bool? shouldPrint = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Print Receipt?'),
                        content: const Text('Do you want to print a receipt for this deposit?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Yes'),
                          ),
                        ],
                      ),
                    );
                    if (shouldPrint == true) {
                      await _printerService.printPaymentReceipt(payment);
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add deposit'), backgroundColor: Colors.red),
                    );
                  }

                  setDialogState(() {
                    isProcessingDeposit = false;
                  });
                  return;
                }

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
                }

                // Handle payment for the sale and potential overpayment to account
                double currentBalanceDue = balanceDueConverted;
                double paymentForSale = amt;

                if (paymentForSale > currentBalanceDue) {
                  paymentForSale = currentBalanceDue;
                }
                if (paymentForSale < 0) {
                  paymentForSale = 0;
                }

                double overpayment = amt - paymentForSale;
                double amountToCreditCustomer = 0;

                if (_selectedCustomer != null && addToAccount && overpayment > 0) {
                  amountToCreditCustomer = double.tryParse(accountCreditController.text) ?? overpayment;
                  if (amountToCreditCustomer > overpayment) {
                    amountToCreditCustomer = overpayment;
                  }
                }

                // Add payment record
                _payments.add(PaymentReceived(
                  id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
                  amount: paymentForSale,
                  amountTendered: amt,
                  amountAddedToAccount: amountToCreditCustomer,
                  paymentType: selectedPaymentType,
                  currency: _selectedCurrency,
                  branch: Branch(id: _selectedBranch!.id, name: _selectedBranch!.name),
                  payer: _selectedCustomer,
                  paymentDescription: _cart.isEmpty ? 'ACCOUNT_TOP_UP' : 'SALE',
                  paymentDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  dateTime: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
                  isMobile: true,
                  bank: _getCorrectBank(selectedPaymentType, _selectedCurrency),
                ));

                // Removed notifyListeners() from here
                if (!context.mounted) return;
                Navigator.pop(dialogContext, true);
              },
              child: isProcessingDeposit ? const CircularProgressIndicator() : const Text('Add'),
            ),
          ],
        ),
      ),
    ) ?? false;
    // Explicitly unfocus any active field after the dialog closes
    FocusScope.of(context).unfocus();

    amountController.dispose();
    accountCreditController.dispose();

    if (dialogResult) {
      _recalculateAppliedAmounts(); // Explicitly recalculate all payment amounts
      if (_cart.isEmpty) {
        await clearPOSScreen();
      }
    }
    _amountTenderedController.text = totalAmountTendered.toStringAsFixed(2);
    notifyListeners(); // This notifyListeners() is sufficient after the dialog closes
    customerSelectFocus = false;
  }

  void updatePaymentAmount(int index, double newAmount) {
    if (index >= 0 && index < _payments.length) {
      final oldPayment = _payments[index];

      // When a payment is edited, we assume the new value is the tendered amount.
      // We update the tendered amount and then recalculate all applied amounts.
      _payments[index] = oldPayment.copyWith(amountTendered: newAmount);
      _recalculateAppliedAmounts();

      _amountTenderedController.text = totalAmountTendered.toStringAsFixed(2);
      notifyListeners();
    }
  }

  void removePayment(int index) {
    if (index >= 0 && index < _payments.length) {
      _payments.removeAt(index);
      _recalculateAppliedAmounts();
      _amountTenderedController.text = totalAmountTendered.toStringAsFixed(2);
      notifyListeners();
    }
  }

  Future<void> printKOT() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot print KOT for an empty cart.')));
      return;
    }

    try {
      final int? kotNumber = await _getOrGenerateKOTNumber();
      await _printerService.printKOT(
        _cart,
        ticketName: _ticketName ?? _selectedCustomer?.name ?? 'Guest',
        orderNumber: kotNumber?.toString(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KOT sent to printer.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to print KOT: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> printBill(Sale sale) async {

    try {
      if (sale.kotNumber == null && _useKOT) {
        sale.kotNumber = await _getOrGenerateKOTNumber();
      }
      await _printerService.printBill(sale, currencies: _currencies);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill sent to printer.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to print bill: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> completeSale() async {
    if (_isProcessingSale) return;
    _isProcessingSale = true;
    notifyListeners();

    try {
      if (_cart.isEmpty && _pendingAccountCredits.isEmpty) return;

      if (amountPaidConverted < grandTotalConverted && _cart.isNotEmpty) {
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

      final List<Customer> customersToUpdate = [];
      if (_pendingCustomerBalanceUpdates.isNotEmpty) {
        for (var update in _pendingCustomerBalanceUpdates) {
          final int customerIndex = _customers.indexWhere((c) => 
            (update.customerId.isNotEmpty && c.id == update.customerId) || 
            (c.name.toLowerCase() == update.customerName.toLowerCase())
          );
          if (customerIndex != -1) {
            Customer customerToUpdate = _customers[customerIndex];
            List<CustomerCurrencyAmount> updatedAmounts = List.from(customerToUpdate.currencyBalance);
            final int ccaIndex = updatedAmounts.indexWhere((cca) => cca.currency.value?.id == update.currency.id);

            if (ccaIndex != -1) {
              updatedAmounts[ccaIndex].balance += update.amountChange;
            } else {
              updatedAmounts.add(CustomerCurrencyAmount(
                currency: update.currency,
                balance: update.amountChange,
              ));
            }
            customerToUpdate = customerToUpdate.copyWith(currencyBalance: updatedAmounts);
            _customers[customerIndex] = customerToUpdate;
            customersToUpdate.add(customerToUpdate);

            if (_isOnline) {
              try {
                await _customerService.updateCustomer(customerToUpdate);
              } catch (e) {
                debugPrint('Failed to sync customer update during sale completion: $e');
              }
            }
          }
        }
        if (customersToUpdate.isNotEmpty) {
          await _customerService.saveCustomersLocally(customersToUpdate);
        }
      }

      final String generatedReference = 'POS-${DateTime.now().millisecondsSinceEpoch}';
      final double exchangeRate = _selectedCurrency?.rate ?? 1.0;
      final List<SaleItem> convertedCart = _cart.map((item) {
        return item.copyWith(
          sellingPrice: item.sellingPrice * exchangeRate,
          taxAmount: item.taxAmount * exchangeRate,
          discountAmount: item.discountAmount * exchangeRate,
          total: item.total * exchangeRate,
        );
      }).toList();

      final saleTotal = grandTotalConverted;
      final change = totalAmountTendered > saleTotal ? totalAmountTendered - saleTotal : 0.0;

      double totalDiscount = 0.0;
      for (var item in convertedCart) {
        totalDiscount += item.discountAmount;
        final double originalPriceConverted = (item.inventoryItem.value?.sellingPrice ?? 0.0) * exchangeRate;
        if (item.sellingPrice < originalPriceConverted) {
          totalDiscount += (originalPriceConverted - item.sellingPrice) * item.quantity;
        }
      }

      final newSale = Sale(
          createdByName: currentShift.createdByName,
          cashierFullName: currentShift.userFullName,
          timeIniated: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
          saleStatus: 'COMPLETE',
          amountAfterDiscount: saleTotal,
          baseSaleAmount: grandTotalBase,
          totalTaxAmount: taxTotalBase * exchangeRate,
          isSynced: false,
          fiscalized: _printerService.getFiscalisationEnabled() && _fiscalizeThisSale,
          taxInvoice: _printerService.getFiscalisationEnabled() && _fiscalizeThisSale,
          totalQuantity: _cart.fold(0.0, (sum, item) => sum! + item.quantity),
          posReference: generatedReference,
          kotNumber: _currentOrderKOTNumber ?? await _getOrGenerateKOTNumber(),
          referenceNumber: generatedReference,
          shiftReference: currentShift.shiftReference,
          ticketName: _ticketName, // Include ticket name in the completed sale
          amtToAcc: totalAmtToAcc > 0 ? totalAmtToAcc.toStringAsFixed(2) : null,
          customerAccBankType:_payments.any((p)=>p.paymentType.value!.isCredit)?'ACC-${_selectedCurrency!.name}':'CASH-${_selectedCurrency!.name}',
          amountPaid: amountPaidConverted,
          amountTendered: totalAmountTendered,
          change: change,
          totalDiscount: totalDiscount,
      );
      newSale.customer.value = _selectedCustomer;
      newSale.company.value = _selectedBranch!.company.value;
      newSale.branch.value = Branch(id: _selectedBranch!.id, name: _selectedBranch!.name);
      newSale.items.addAll(convertedCart);
      newSale.paymentTypes.addAll(_payments);
      newSale.currency.value = _selectedCurrency;
      newSale.baseCurrency.value = _selectedCurrency;

      await _saleService.completeSaleTransaction(newSale,_payments ,convertedCart,customersToUpdate);

      if (_heldSaleId != null) {
        await removeHeldSale(_heldSaleId!);
      }

      try {
        if (_printerService.isConnected && (_printReceiptForThisSale)) {
          await _printerService.printSale(newSale);
        }
      } catch (e) {
        debugPrint('Error auto-printing receipt: $e');
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String stockKey = _isOnline ? AppConstants.keyBranchStock : AppConstants.keyOfflineBranchStock;
      final List<String> stockStrings = prefs.getStringList(stockKey) ?? [];
      final List<BranchStock> allStocks = stockStrings.map((e) => BranchStock.fromJson(jsonDecode(e))).toList();

      for (var cartItem in _cart) {
        if (cartItem.inventoryItem.value?.isService == true) continue;
        final stockIndex = allStocks.indexWhere((s) =>
        s.item.value?.id == cartItem.inventoryItem.value?.id &&
            s.branch.value?.id == _selectedBranch?.id
        );
        if (stockIndex != -1) {
          final stock = allStocks[stockIndex];
          allStocks[stockIndex] = stock.copyWith(stock: stock.stock - cartItem.quantity);
        }
      }
      await prefs.setStringList(stockKey, allStocks.map((e) => jsonEncode(e.toJson())).toList());

      currentShift.shiftCurrencyAmounts ??= [];
      final List<MobileShiftCurrencyAmount> newActivitiesToExport = [];

      for (var payment in _payments) {
        final MobileShiftCurrencyAmount paymentShiftAmount = MobileShiftCurrencyAmount(
          id:null,
          dateCreated:null,
          timeCreated: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
          active: true,
          currency: payment.currency.value!,
          amount: payment.amount,
          notes: _cart.isEmpty ? 'Account top up via ${payment.paymentType.value!.name}' : 'Payment for sale ${newSale.posReference} via ${payment.paymentType.value!.name}',
          amountType: _cart.isEmpty ? 'ACCOUNT_TOP_UP' : 'SALE',
          ref: 'SL_${DateTime.now().millisecondsSinceEpoch}${_payments.indexOf(payment)}',
          posReference: newSale.posReference,
          shiftReference: currentShift.shiftReference,
          isCash: payment.paymentType.value!.isCash == true || (payment.paymentType.value!.name.toLowerCase().startsWith('cash')),
          paymentType: payment.paymentType.value!.name,
        );
        currentShift.shiftCurrencyAmounts!.add(paymentShiftAmount);
        newActivitiesToExport.add(paymentShiftAmount);
      }

      for (var accountCredit in _pendingAccountCredits) {
        accountCredit.posReference = '${newSale.posReference}_CA';
        accountCredit.shiftReference = currentShift.shiftReference;
        currentShift.shiftCurrencyAmounts!.add(accountCredit);
        newActivitiesToExport.add(accountCredit);
      }
      _pendingAccountCredits.clear();

      if (newActivitiesToExport.isNotEmpty) {
        await _excelExportService.exportShiftCurrencyAmountsToExcel(newActivitiesToExport);
      }

      _saveShift(currentShift);

      if (!context.mounted) return;

      await clearPOSScreen();
    } finally {
      if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sale completed successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
      }
      _isProcessingSale = false;
      customerSelectFocus = false;
      notifyListeners();
    }
  }

  Future<PaymentReceived?> addCustomerDeposit(Customer customer, Currency selectedCurrency, PaymentType selectedPaymentType, double amount, {Bank? selectedBank}) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool isOnline = !(prefs.getBool(AppConstants.keyIsOfflineMode) ?? false);

      final newPayment = PaymentReceived(
        paymentType: selectedPaymentType,
        payer: customer,
        currency: selectedCurrency,
        branch: _selectedBranch,
        amount: amount,
        posReference: 'CA_${DateTime.now().millisecondsSinceEpoch}',
        amountPaid: amount,
        paymentDescription: 'PAY_ACCOUNT',
        accountType: 'CUSTOMER_ACCOUNT',
        paymentDate:DateFormat('yyyy-MM-dd').format(DateTime.now()),
        dateTime:DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
        notes: 'Customer deposit from mobile POS',
        bank: selectedBank,
        isMobile: true,
      );
      newPayment.paymentType.value = selectedPaymentType;
      newPayment.payer.value = customer;
      newPayment.currency.value = selectedCurrency;
      newPayment.branch.value = _selectedBranch;
      newPayment.bank.value = selectedBank;

      // Update the customer in the local list
      int customerIndex = _customers.indexWhere((c) => 
        (customer.id != null && c.id == customer.id) ||
        (c.name.toLowerCase() == customer.name.toLowerCase())
      );
      if (customerIndex != -1) {
        Customer currentLocalCustomer = _customers[customerIndex];
        
        // Create a new list of CCA objects to avoid modifying the original one in-place
        List<CustomerCurrencyAmount> updatedCurrencyBalance = 
            currentLocalCustomer.currencyBalance.map((cca) => cca.copyWith()).toList();

        CustomerCurrencyAmount? existingCca = updatedCurrencyBalance.firstWhereOrNull(
                (cca) => cca.currency.value?.id == selectedCurrency.id,
        );

        if (existingCca != null) {
          existingCca.balance += amount;
        } else {
          updatedCurrencyBalance.add(CustomerCurrencyAmount(
            currency: selectedCurrency,
            balance: amount,
          ));
        }

        Customer updatedCustomer = currentLocalCustomer.copyWith(
          currencyBalance: updatedCurrencyBalance,
          isSynced: false,
        );

        _customers[customerIndex] = updatedCustomer;
        await _customerService.saveCustomerLocally(updatedCustomer);
        _selectedCustomer = updatedCustomer;
        notifyListeners();
      }

      // Save locally first
      final savedPayment = await _paymentsService.savePaymentReceivedLocally(newPayment);

      // Then try to sync in background
      if (isOnline) {
        _paymentsService.syncReceivedPayment(savedPayment).catchError((e) {
          debugPrint('Failed to sync payment in background: $e');
          // It's already in the unsynced list, so the background sync process will pick it up
          return false;
        });
      }

      // Reload data to reflect changes.
      await _loadData();
    
      // Refresh selected customer from the reloaded list to ensure we have the latest object
      if (_selectedCustomer != null) {
        _selectedCustomer = _customers.firstWhereOrNull((c) => 
          (_selectedCustomer!.id != null && c.id == _selectedCustomer!.id) ||
          (c.name.toLowerCase() == _selectedCustomer!.name.toLowerCase())
        ) ?? _selectedCustomer;
        notifyListeners();
      }

      // Update shift
      final MobilePosShift? currentShift = await _getCurrentShift();
      if (currentShift != null && !(currentShift.isShiftClosed ?? true)) {
        final MobileShiftCurrencyAmount shiftAmount = MobileShiftCurrencyAmount(
          id: null,
          timeCreated: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
          active: true,
          currency: selectedCurrency,
          amount: amount,
          notes: 'Customer Deposit for ${customer.name}',
          amountType: 'ACCOUNT_TOP_UP',
          ref: 'AC_${DateTime.now().millisecondsSinceEpoch}',
          posReference: '${customer.name}${DateTime.now().microsecondsSinceEpoch}',
          shiftReference: currentShift.shiftReference,
          isCash: selectedPaymentType.isCash == true || (selectedPaymentType.name.toLowerCase().startsWith('cash')),
          paymentType: selectedPaymentType.name,
          bankName: selectedBank?.name,
        );
        currentShift.shiftCurrencyAmounts ??= [];
        currentShift.shiftCurrencyAmounts!.add(shiftAmount);

        await _excelExportService.exportShiftCurrencyAmountsToExcel([shiftAmount]);

        await _saveShift(currentShift);
      }
      return savedPayment;
    } catch (e) {
      debugPrint('Failed to add deposit: $e');
      return null;
    }
  }

  Future<void> clearPOSScreen({Customer? newCustomer}) async {
    _cart.clear();
    _payments.clear();
    _pendingAccountCredits.clear();
    _pendingCustomerBalanceUpdates.clear();
    _selectedCustomer = newCustomer;
    _currentOrderKOTNumber = null;
    _ticketName = null;
    _heldSaleId = null;
    _amountTenderedController.clear();
    _disposeQuantityControllers();
    _searchController.clear();
    _customerSearchController.clear();
    _searchQuery = '';
    _applyFilters();
    await _loadData();
    // Refresh selected customer from the reloaded list to ensure we have the latest object
    if (_selectedCustomer != null) {
      _selectedCustomer = _customers.firstWhereOrNull((c) => 
        (_selectedCustomer!.id != null && c.id == _selectedCustomer!.id) ||
        (c.name.toLowerCase() == _selectedCustomer!.name.toLowerCase())
      ) ?? _selectedCustomer;
    }
    _printReceiptForThisSale = _printerService.getAlwaysPrintReceipt() && _printerService.isPrinterConfigured;
    _fiscalizeThisSale = _printerService.getFiscalisationEnabled() && _printerService.getAlwaysFiscalize();
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

    String? ticketName;
    try {
      ticketName = await showDialog<String>(
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
              onPressed: () {
                FocusScope.of(dialogContext).unfocus();
                Navigator.pop(dialogContext, null); // Return null if cancelled
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FocusScope.of(dialogContext).unfocus();
                Navigator.pop(dialogContext, ticketNameController.text);
              },
              child: const Text('Hold'),
            ),
          ],
        ),
      );
    } finally {
      ticketNameController.dispose();
    }

    if (ticketName == null || ticketName.trim().isEmpty) {
      // User cancelled or entered empty name, do not hold sale
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale not held. Ticket name is required.'), backgroundColor: Colors.red),
      );
      return;
    }

    final MobilePosShift? currentShift = await _getCurrentShift();

    final double exchangeRate = _selectedCurrency?.rate ?? 1.0;

    double totalDiscount = 0.0;
    for (var item in _cart) {
      totalDiscount += item.discountAmount * exchangeRate;
      final double originalPriceConverted = (item.inventoryItem.value?.sellingPrice ?? 0.0) * exchangeRate;
      final double actualPriceConverted = item.sellingPrice * exchangeRate;
      if (actualPriceConverted < originalPriceConverted) {
        totalDiscount += (originalPriceConverted - actualPriceConverted) * item.quantity;
      }
    }

    final heldSale = Sale(
      id: 'held_${DateTime.now().millisecondsSinceEpoch}',
      kotNumber:  prefs.getInt(AppConstants.keyLastKOTNumber) ?? 0,
      createdByName: currentShift?.createdByName,
      cashierFullName: currentShift?.userFullName,
      timeIniated: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
      saleStatus: SaleStatus.ON_HOLD,
      shiftReference: currentShift?.shiftReference,
      totalTaxAmount: taxTotalBase * exchangeRate,
      amountAfterDiscount: grandTotalConverted,
      ticketName: ticketName,
      amountTendered: totalAmountTendered,
      heldItems: List<SaleItem>.from(_cart), // Store cart items in heldItems
      totalDiscount: totalDiscount,
    );
    heldSale.customer.value = _selectedCustomer;
    heldSale.branch.value = _selectedBranch;
    heldSale.items.addAll(_cart);
    heldSale.paymentTypes.addAll(_payments);
    heldSale.currency.value = _selectedCurrency;

    heldSales.add(heldSale);

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

  Future<void> loadHeldSale(Sale heldSale) async {
    await clearPOSScreen();

    _isLoading = true;
    notifyListeners();

    try {
      _cart.addAll(heldSale.heldItems); // Load items from heldItems
      _payments.addAll(heldSale.allPaymentTypes);
      _selectedCustomer = heldSale.customer.value;
      _selectedCurrency = heldSale.currency.value;
      _ticketName = heldSale.ticketName;
      _heldSaleId = heldSale.id;
      _currentOrderKOTNumber = heldSale.kotNumber;
      _amountTenderedController.text = (heldSale.amountTendered ?? 0.0).toStringAsFixed(2);

      // Re-associate inventory items from local stock
      for (var i = 0; i < _cart.length; i++) {
        final saleItem = _cart[i];
        final stockItem = _allBranchStocks.firstWhereOrNull(
              (bs) => bs.item.value?.id == saleItem.inventoryItem.value?.id,
        );
        if (stockItem != null) {
          _cart[i].inventoryItem.value = stockItem.item.value;
          await _cart[i].inventoryItem.value!.loadAll(); // Ensure all nested properties are loaded
        }
      }

      for (var item in _cart) {
        if (item.inventoryItem.value?.id != null) {
          _quantityControllers[item.inventoryItem.value!.id!] = TextEditingController(text: item.quantity.toStringAsFixed(2));
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Held sale for ${heldSale.ticketName ?? 'Guest'} loaded.'), backgroundColor: Colors.green),
        );
      }
      _printReceiptForThisSale = _printerService.getAlwaysPrintReceipt() && _printerService.isPrinterConfigured;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

      final cashPaymentType = _paymentTypes.firstWhereOrNull(
        (pt) => (pt.isCash == true || pt.name.toLowerCase().startsWith('cash')) && (pt.currency.value == null || pt.currency.value?.id == _selectedCurrency?.id),
      );

      if (cashPaymentType == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cash payment type not configured for this currency.')));
        return;
      }

      _payments.clear();
      _payments.add(
        PaymentReceived(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          amount: grandTotalConverted,
          amountTendered: grandTotalConverted,
          paymentType: cashPaymentType,
          currency: _selectedCurrency,
          branch: _selectedBranch,
          paymentDescription: 'SALE',
          paymentDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          dateTime: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
          isMobile: true,
          bank: _getCorrectBank(cashPaymentType, _selectedCurrency),
        ),
      );
      
      _amountTenderedController.text = totalAmountTendered.toStringAsFixed(2);

      _isProcessingSale = false;
      await completeSale();
    } finally {
      _isProcessingSale = false;
      notifyListeners();
    }
  }

}

extension on InventoryItem {
  Future<void> loadAll() async {
    if (category.isAttached) await category.load();
    if (unit.isAttached) await unit.load();
    if (tax.isAttached) await tax.load();
    if (currency.isAttached) await currency.load();
    if (company.isAttached) await company.load();
  }
}

extension on Customer {
  Future<void> loadAll() async {
    if (company.isAttached) await company.load();
    if (branch.isAttached) await branch.load();
    if (currencyBalanceLinks.isAttached) await currencyBalanceLinks.load();
  }
}
