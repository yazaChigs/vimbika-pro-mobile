import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/inventory_item.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/mobile_shift_currency_amount.dart';
import 'package:vimbika_pro/model/online_sale.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/model/expense.dart';
import 'package:vimbika_pro/model/purchase.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import 'package:vimbika_pro/model/payment_paid.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:vimbika_pro/services/branch_service.dart';
import 'package:vimbika_pro/services/branch_stock_service.dart';
import 'package:vimbika_pro/services/currency_service.dart';
import 'package:vimbika_pro/services/expense_service.dart';
import 'package:vimbika_pro/services/purchase_service.dart';
import 'package:vimbika_pro/services/sale_service.dart';
import 'package:vimbika_pro/services/payments_service.dart';
import 'package:vimbika_pro/services/financial_service.dart';
import 'package:vimbika_pro/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:vimbika_pro/app_constants/app_colors.dart';
import 'package:vimbika_pro/services/mobile_shift_service.dart'; // New: MobileShiftService
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class OnlineReportsController {
  final SaleService _saleService = SaleService();
  final BranchService _branchService = BranchService();
  final CurrencyService _currencyService = CurrencyService();
  final BranchStockService _branchStockService = BranchStockService();
  final ExpenseService _expenseService = ExpenseService();
  final PurchaseService _purchaseService = PurchaseService();
  final PaymentsService _paymentsService = PaymentsService();
  final MobilePosShiftService _mobileShiftService = MobilePosShiftService(); // New: MobileShiftService

  final BuildContext context;

  // State variables
  double totalSales = 0.0;
  double totalGrossProfit = 0.0;
  double cashOnHand = 0.0;
  double totalStockValue = 0.0;
  double totalStockCount = 0.0;
  double totalExpenses = 0.0;
  double totalCostOfSales = 0.0;
  double totalOtherExpenses = 0.0;
  double totalReceivables = 0.0;
  double totalPayables = 0.0;
  int expensesCount = 0;
  int receivablesCount = 0;
  Map<String, double> salesByPaymentType = {};
  Map<String, double> branchSales = {};
  Map<String, double> branchProfits = {};
  Map<String, double> salesByAgent = {}; // New: Sales by Agent
  List<OnlineSale> onlineSales = [];
  List<Expense> expenses = [];
  List<Purchase> purchases = [];
  List<PaymentReceived> paymentsReceived = [];
  List<PaymentPaid> paymentsPaid = [];
  List<Branch> userBranches = [];
  List<Currency> currencies = [];
  List<InventoryItem> outOfStockItems = [];
  List<BranchStock> branchStocks = [];
  List<MobileShiftCurrencyAmount> mobileShifts = []; // New: List to hold mobile shift data
  Currency? selectedCurrency;
  Branch? selectedBranch;
  String? selectedShiftUser; // New: Filter for shift activity
  User? currentUser;
  List<MapEntry<String, double>> topProducts = [];
  List<MapEntry<String, double>> topCustomers = []; // New: Top Customers
  Map<int, double> hourlySales = {};
  bool isLoading = true;
  bool isSyncing = false;
  bool isStockLoading = false;
  DateTime searchDate = DateTime.now();
  DateTime endDate = DateTime.now();

  // Pagination
  int currentPage = 1;
  static const int pageSize = 10;

  final VoidCallback onStateChanged;

  OnlineReportsController({required this.context, required this.onStateChanged});

  Future<void> initData() async {
    await loadCachedData();
    await fetchReportData();
  }

  Future<void> loadCachedData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final List<String> branchJson = prefs.getStringList(AppConstants.keyBranches) ?? [];
    final List<String> currencyJson = prefs.getStringList(AppConstants.keyCurrencies) ?? [];
    final List<String> salesJson = prefs.getStringList(AppConstants.keySales) ?? [];
    final List<String> outOfStockJson = prefs.getStringList(AppConstants.keyOutOfStockItems) ?? [];
    final List<String> stockJson = prefs.getStringList(AppConstants.keyBranchStock) ?? [];
    final List<String> expenseJson = prefs.getStringList(AppConstants.keyOnlineExpenses) ?? [];
    final List<String> purchaseJson = prefs.getStringList(AppConstants.keyPurchases) ?? [];
    final List<String> paymentReceivedJson = prefs.getStringList(AppConstants.keyPaymentsReceived) ?? [];
    final List<String> paymentPaidJson = prefs.getStringList(AppConstants.keyPaymentsPaid) ?? [];
    final List<String> mobileShiftJson = prefs.getStringList(AppConstants.keyMobileShifts) ?? []; // New: Mobile Shifts

    final String? userDataStr = prefs.getString(AppConstants.keyOnlineUserData);
    if (userDataStr != null) {
      currentUser = User.fromJson(jsonDecode(userDataStr));
    }

    userBranches = branchJson.map((b) => Branch.fromJson(jsonDecode(b))).toList();
    currencies = currencyJson.map((c) => Currency.fromJson(jsonDecode(c))).toList();
    
    onlineSales = salesJson.map((s) {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) {
        return OnlineSale.fromJson(decoded);
      }
      return null;
    }).whereType<OnlineSale>().toList();

    outOfStockItems = outOfStockJson.map((i) => InventoryItem.fromJson(jsonDecode(i))).toList();
    branchStocks = stockJson.map((s) => BranchStock.fromJson(jsonDecode(s))).toList();
    expenses = expenseJson.map((e) => Expense.fromJson(jsonDecode(e))).toList();

    purchases = purchaseJson.map((p) => Purchase.fromJson(jsonDecode(p))).toList();
    paymentsReceived = paymentReceivedJson.map((p) => PaymentReceived.fromJson(jsonDecode(p))).toList();
    paymentsPaid = paymentPaidJson.map((p) => PaymentPaid.fromJson(jsonDecode(p))).toList();
    
    mobileShifts = mobileShiftJson.map((s) {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) {
        return MobileShiftCurrencyAmount.fromJson(decoded);
      }
      return null;
    }).whereType<MobileShiftCurrencyAmount>().toList();

    final String? lastDateStr = prefs.getString(AppConstants.keyLastSelectedDate);
    if (lastDateStr != null) {
      searchDate = DateTime.parse(lastDateStr);
    }

    if (currencies.isNotEmpty) {
      selectedCurrency = currencies.firstWhere((c) => c.isBaseCurrency!, orElse: () => currencies.first);
    }

    calculateTotals();

    // Set fallback stock totals based on cached stocks first
    if (branchStocks.isNotEmpty) {
      _calculateStockTotalsFromList();
    }

    if (onlineSales.isNotEmpty || userBranches.isNotEmpty || outOfStockItems.isNotEmpty || mobileShifts.isNotEmpty) { // New: Check mobileShifts
      isLoading = false;
    }
    onStateChanged();
  }

  void calculateTotals() {
    final filteredSales = getFilteredSales(ignoreCurrency: true);

    final currentCurrencySales = filteredSales.where((s) => selectedCurrency == null || s.currency?.id == selectedCurrency!.id).toList();

    totalSales = currentCurrencySales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
    totalGrossProfit = currentCurrencySales.fold(0.0, (sum, sale) => sum + (sale.grandTotal - (sale.saleCost ?? 0.0)));
    final receivableSales = currentCurrencySales.where((s) => (s.balance ?? 0.0) > 0).toList();
    totalReceivables = receivableSales.fold(0.0, (sum, sale) => sum + (sale.balance ?? 0.0));
    receivablesCount = receivableSales.length;

    final currentCurrencyExpenses = expenses.where((e) {
      final matchesCurrency = selectedCurrency == null || e.currency?.id == selectedCurrency!.id;
      final matchesBranch = selectedBranch == null || e.branch?.id == selectedBranch!.id;
      return matchesCurrency && matchesBranch;
    }).toList();

    totalCostOfSales = currentCurrencyExpenses
        .where((e) => e.expenseCategory?.name.toLowerCase().trim() == 'cost of sales')
        .fold(0.0, (sum, exp) => sum + exp.amount);

    totalOtherExpenses = currentCurrencyExpenses
        .where((e) => e.expenseCategory?.name.toLowerCase().trim() != 'cost of sales')
        .fold(0.0, (sum, exp) => sum + exp.amount);

    totalExpenses = totalCostOfSales + totalOtherExpenses; // Sum of all expenses
    expensesCount = currentCurrencyExpenses.where((e) => e.expenseCategory?.name.toLowerCase().trim() != 'cost of sales').length; // Count of other expenses

    final currentCurrencyPurchases = purchases.where((p) {
      final matchesCurrency = selectedCurrency == null || p.currency?.id == selectedCurrency!.id;
      final matchesBranch = selectedBranch == null || p.branch?.id == selectedBranch!.id;
      return matchesCurrency && matchesBranch;
    }).toList();

    final currentCurrencyPaymentsPaid = paymentsPaid.where((p) {
      final matchesCurrency = selectedCurrency == null || p.currency?.id == selectedCurrency!.id;
      final matchesBranch = selectedBranch == null || p.branch?.id == selectedBranch!.id;
      return matchesCurrency && matchesBranch; // Apply branch filter for consistency
    }).toList();

    final currentCurrencyPaymentsReceived = paymentsReceived.where((p) {
      final matchesCurrency = selectedCurrency == null || p.currency?.id == selectedCurrency!.id;
      // Note: If PaymentReceived model doesn't have branch, you might need to adjust this
      final matchesBranch = selectedBranch == null || p.branch?.id == selectedBranch!.id; // Assuming PaymentReceived can have a branch
      return matchesCurrency && matchesBranch;
    }).toList();

    double totalPurchaseAmount = currentCurrencyPurchases.fold(0.0, (sum, pur) => sum + pur.grandTotal);
    double totalAmountPaid = currentCurrencyPaymentsPaid.fold(0.0, (sum, pay) => sum + pay.amount);

    totalPayables = totalPurchaseAmount - totalAmountPaid;

    // Calculate Cash on Hand using the Financial Service
    cashOnHand = FinancialService.calculateCashOnHand(
      paymentsReceived: currentCurrencyPaymentsReceived,
      paymentsPaid: currentCurrencyPaymentsPaid,
    );

    // Pass to stats for other payment types breakdown (like Credit/Mobile Money)
    // We no longer let this method overwrite the cashOnHand value.
    _calculatePaymentTypeStatsOnly(currentCurrencySales);
    
    calculateTopProducts(currentCurrencySales);
    calculateTopCustomers(currentCurrencySales); // New: Calculate top customers
    calculateHourlySales(currentCurrencySales);
    calculateBranchPerformance(currentCurrencySales);
    calculateSalesByAgent(currentCurrencySales); // New: Calculate sales by agent
    onStateChanged();
  }

  void calculateBranchPerformance(List<OnlineSale> sales) {
    final Map<String, double> salesMap = {};
    final Map<String, double> profitsMap = {};

    for (var branch in userBranches) {
      final branchName = branch.name;
      final branchSalesList = sales.where((s) => s.branch?.id == branch.id).toList();
      
      final totalBranchSales = branchSalesList.fold(0.0, (sum, s) => sum + s.grandTotal);
      final totalBranchProfit = branchSalesList.fold(0.0, (sum, s) => sum + (s.grandTotal - (s.saleCost ?? 0.0)));
      
      salesMap[branchName] = totalBranchSales;
      profitsMap[branchName] = totalBranchProfit;
    }

    branchSales = salesMap;
    branchProfits = profitsMap;
  }

  void calculateSalesByAgent(List<OnlineSale> sales) {
    final Map<String, double> agentSalesMap = {};

    for (var sale in sales) {
      final agentName = sale.createdByName != null && sale.createdByName!.isNotEmpty
          ? sale.createdByName ?? ''
          : 'Unknown Agent';
      agentSalesMap[agentName] = (agentSalesMap[agentName] ?? 0.0) + sale.grandTotal;
    }
    salesByAgent = agentSalesMap;
  }

  void _calculateStockTotalsFromList() {
    final filteredStocks = branchStocks.where((s) => selectedBranch == null || s.branch?.id == selectedBranch!.id).toList();
    totalStockCount = filteredStocks.fold(0.0, (sum, stock) => sum + stock.quantity);
    totalStockValue = filteredStocks.fold(0.0, (sum, stock) => sum + (stock.quantity * (stock.item?.sellingPrice ?? 0.0)));
  }

  Future<void> fetchStockSummary() async {
    isStockLoading = true;
    onStateChanged();
    
    try {
      final summary = await _branchStockService.getStockSummary(branchId: selectedBranch?.id);
      totalStockValue = summary['stockValue'] ?? 0.0;
      totalStockCount = summary['stockCount'] ?? 0.0;
    } catch (e) {
      debugPrint('Error fetching stock summary: $e');
      // Fallback to local list calculation if API fails
      if (branchStocks.isNotEmpty) {
        _calculateStockTotalsFromList();
      }
    } finally {
      isStockLoading = false;
      onStateChanged();
    }
  }


  /// Internal helper to breakdown sales by type (UI visibility)
  void _calculatePaymentTypeStatsOnly(List<OnlineSale> sales) {
    final Map<String, double> paymentTypeMap = {};

    for (var sale in sales) {
      if (sale.paymentTypes != null && sale.paymentTypes!.isNotEmpty) {
        for (var payment in sale.paymentTypes!) {
          final typeName = payment.paymentType?.name ?? 'Unknown';
          paymentTypeMap[typeName] = (paymentTypeMap[typeName] ?? 0.0) + payment.amount;
        }
      } else if (sale.paymentType != null) {
        // Fallback to single payment type if paymentTypes list is empty
        final typeName = sale.paymentType!.name;
        paymentTypeMap[typeName] = (paymentTypeMap[typeName] ?? 0.0) + sale.grandTotal;
      } else {
        paymentTypeMap['Unspecified'] = (paymentTypeMap['Unspecified'] ?? 0.0) + sale.grandTotal;
      }
    }

    salesByPaymentType = paymentTypeMap;
  }

  void calculateHourlySales(List<OnlineSale> sales) {
    final Map<int, double> hourlyMap = {};
    for (int i = 0; i < 24; i++) {
      hourlyMap[i] = 0.0;
    }

    for (var sale in sales) {
      final DateTime? date = DateTime.tryParse(sale.timeIniated!); // Explicitly type as DateTime?
      if (date != null) {
        final hour = date.hour;
        hourlyMap[hour] = (hourlyMap[hour] ?? 0.0) + sale.grandTotal;
      }
    }
    hourlySales = hourlyMap;
  }

  void calculateTopProducts(List<OnlineSale> sales) {
    final Map<String, double> productQuantities = {};

    for (var sale in sales) {
      final items = sale.items;
      if (items != null) {
        for (var item in items) {
          final productName = item.inventoryItem?.name ?? 'Unknown Product';
          productQuantities[productName] = (productQuantities[productName] ?? 0.0) + item.quantity;
        }
      }
    }

    final sortedProducts = productQuantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    topProducts = sortedProducts.take(10).toList();
  }

  void calculateTopCustomers(List<OnlineSale> sales) {
    final Map<String, double> customerSales = {};

    for (var sale in sales) {
      final customerName = sale.customer?.name ?? (sale.isWalkInCustomer == true ? 'Walk-in Customer' : 'Unknown Customer');
      customerSales[customerName] = (customerSales[customerName] ?? 0.0) + sale.grandTotal;
    }

    final sortedCustomers = customerSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    topCustomers = sortedCustomers.take(10).toList();
  }

  List<OnlineSale> getFilteredSales({bool ignoreCurrency = false}) {
    return onlineSales.where((sale) {
      final matchesBranch = selectedBranch == null || sale.branch?.id == selectedBranch!.id;
      final matchesCurrency = ignoreCurrency || selectedCurrency == null || sale.currency?.id == selectedCurrency!.id;
      return matchesBranch && matchesCurrency;
    }).toList();
  }

  Future<void> _saveDataToCache(
    List<Branch> branches, 
    List<Currency> currencies, 
    List<OnlineSale> sales, 
    List<InventoryItem> outOfStock,
    List<BranchStock> stocks,
    List<Expense> expensesList,
    List<Purchase> purchasesList,
    List<PaymentReceived> paymentsReceivedList,
    List<PaymentPaid> paymentsPaidList,
    List<MobileShiftCurrencyAmount> mobileShiftsList // New: Mobile Shifts
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(AppConstants.keyBranches, branches.map((b) => jsonEncode(b.toJson())).toList());
    await prefs.setStringList(AppConstants.keyCurrencies, currencies.map((c) => jsonEncode(c.toJson())).toList());
    await prefs.setStringList(AppConstants.keySales, sales.map((s) => jsonEncode(s.toJson())).toList());
    await prefs.setStringList(AppConstants.keyOutOfStockItems, outOfStock.map((i) => jsonEncode(i.toJson())).toList());
    await prefs.setStringList(AppConstants.keyBranchStock, stocks.map((s) => jsonEncode(s.toJson())).toList());
    await prefs.setStringList(AppConstants.keyOnlineExpenses, expensesList.map((e) => jsonEncode(e.toJson())).toList());
    await prefs.setStringList(AppConstants.keyPurchases, purchasesList.map((p) => jsonEncode(p.toJson())).toList());
    await prefs.setStringList(AppConstants.keyPaymentsReceived, paymentsReceivedList.map((p) => jsonEncode(p.toJson())).toList());
    await prefs.setStringList(AppConstants.keyPaymentsPaid, paymentsPaidList.map((p) => jsonEncode(p.toJson())).toList());
    await prefs.setStringList(AppConstants.keyMobileShifts, mobileShiftsList.map((s) => jsonEncode(s.toJson())).toList()); // New: Mobile Shifts
  }

  Future<void> fetchReportData() async {
    // Check internet connection
    final connectivityResultList = await (Connectivity().checkConnectivity());
    if (connectivityResultList.contains(ConnectivityResult.none)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No internet connection. Loading locally stored data.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      await loadCachedData();
      isLoading = false;
      isSyncing = false;
      onStateChanged();
      return; // Exit early if no internet
    }

    if (onlineSales.isEmpty && userBranches.isEmpty) {
      isLoading = true;
      onStateChanged();
    }
    isSyncing = true;
    onStateChanged();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataStr = prefs.getString(AppConstants.keyOnlineUserData);
      if (userDataStr == null) throw Exception('User data not found');
      currentUser = User.fromJson(jsonDecode(userDataStr));
      final String agentId = currentUser?.id ?? '';

      final results = await Future.wait([
        _branchService.fetchUserBranches(),
        _currencyService.fetchCurrencies(),
        _saleService.fetchSales(
          startDate: DateTime(searchDate.year, searchDate.month, searchDate.day),
          endDate: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
          branchId: selectedBranch?.id
        ),
        _branchStockService.fetchOutOfStock(),
        _expenseService.fetchExpenses(
          startDate: DateTime(searchDate.year, searchDate.month, searchDate.day),
          endDate: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
          branchId: selectedBranch?.id
        ),
        _purchaseService.fetchPurchases(
          startDate: DateTime(searchDate.year, searchDate.month, searchDate.day),
          endDate: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
          branchId: selectedBranch?.id
        ),
        _paymentsService.fetchPaymentsByAgent(
          agentId: agentId,
          startDate: DateTime(searchDate.year, searchDate.month, searchDate.day),
          endDate: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
        ),
        _paymentsService.fetchPaymentsPaid(
          startDate: DateTime(searchDate.year, searchDate.month, searchDate.day),
          endDate: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
        ),
        _mobileShiftService.getMobilePosShiftCurrencyAmountsByDate( // New: Fetch mobile shifts
          startDate: DateTime(searchDate.year, searchDate.month, searchDate.day),
          endDate: DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
        ),
      ]);

      final List<Branch> branches = results[0] as List<Branch>;
      final List<Currency> currenciesList = results[1] as List<Currency>;
      
      final List<OnlineSale> fetchedSales = results[2] as List<OnlineSale>;

      final List<InventoryItem> allOutOfStock = results[3] as List<InventoryItem>;
      final List<Expense> fetchedExpenses = results[4] as List<Expense>;
      final List<Purchase> fetchedPurchases = results[5] as List<Purchase>;
      final List<PaymentReceived> fetchedPaymentsReceived = results[6] as List<PaymentReceived>;
      final List<PaymentPaid> fetchedPaymentsPaid = results[7] as List<PaymentPaid>;
      final List<MobileShiftCurrencyAmount> fetchedMobileShifts = results[8] as List<MobileShiftCurrencyAmount>; // New: Mobile Shifts

      onlineSales = fetchedSales;
      userBranches = branches;
      currencies = currenciesList;
      outOfStockItems = allOutOfStock;
      expenses = fetchedExpenses;
      purchases = fetchedPurchases;
      paymentsReceived = fetchedPaymentsReceived;
      paymentsPaid = fetchedPaymentsPaid;
      mobileShifts = fetchedMobileShifts; // New: Mobile Shifts


      if (selectedCurrency == null && currencies.isNotEmpty) {
        selectedCurrency = currencies.firstWhere((c) => c.isBaseCurrency!, orElse: () => currencies.first);
      }

      await _saveDataToCache(
        branches, 
        currenciesList, 
        fetchedSales, 
        allOutOfStock, 
        branchStocks, 
        fetchedExpenses, 
        fetchedPurchases, 
        fetchedPaymentsReceived, 
        fetchedPaymentsPaid,
        fetchedMobileShifts // New: Mobile Shifts
      );

      calculateTotals();
      isLoading = false;
      isSyncing = false;
      currentPage = 1;
      onStateChanged();

      // Fetch branch stock in background
      fetchBranchStockData();
      fetchStockSummary(); // New: Fetch the optimized summary payload
    } catch (e) {
      isLoading = false;
      isSyncing = false;
      onStateChanged();
      debugPrint('Error fetching report data: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error syncing data: $e')),
        );
      }
    }
  }

  Future<void> fetchBranchStockData() async {
    isStockLoading = true;
    onStateChanged();

    try {
      final List<BranchStock> fetchedStocks = await _branchStockService.fetchBranchStock();
      debugPrint('Saving branch stock to SharedPreferences: ${fetchedStocks.length}');
      
      branchStocks = fetchedStocks;
      // We already called fetchStockSummary, but if we haven't, we can recalculate here as a fallback
      if (totalStockCount == 0.0 && totalStockValue == 0.0) {
        _calculateStockTotalsFromList();
      }
      
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(AppConstants.keyBranchStock, fetchedStocks.map((s) => jsonEncode(s.toJson())).toList());
      
      isStockLoading = false;
      onStateChanged();
    } catch (e) {
      isStockLoading = false;
      onStateChanged();
      debugPrint('Error fetching branch stock: $e');
    }
  }

  void setSelectedBranch(Branch? branch) {
    selectedBranch = branch;
    calculateTotals();
    fetchStockSummary(); // Refresh stock summary when branch changes
  }

  void setSelectedCurrency(Currency? currency) {
    selectedCurrency = currency;
    calculateTotals();
  }

  void setSelectedShiftUser(String? username) {
    selectedShiftUser = username;
    onStateChanged();
  }

  void setToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    searchDate = today;
    endDate = today;
    fetchReportData();
  }

  void setWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Start of week (Monday)
    // now.weekday is 1 for Monday, 7 for Sunday
    searchDate = today.subtract(Duration(days: today.weekday - 1));
    endDate = today;
    fetchReportData();
  }

  void setMonth() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    searchDate = DateTime(today.year, today.month, 1);
    endDate = today;
    fetchReportData();
  }

  void setSearchDate(DateTime date) async {
    searchDate = date;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLastSelectedDate, searchDate.toIso8601String());
    fetchReportData();
  }

  void setPage(int page) {
    currentPage = page;
    onStateChanged();
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyHasUser, false);
    await prefs.remove(AppConstants.CACHED_ACCESS_TOKEN);
    await prefs.setBool(AppConstants.keyIsOfflineMode, false);

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen(initialOfflineMode: false)),
        (route) => false,
      );
    }
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: searchDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != searchDate) {
      searchDate = picked;
      endDate = picked;
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyLastSelectedDate, searchDate.toIso8601String());
      fetchReportData();
    }
  }
}
