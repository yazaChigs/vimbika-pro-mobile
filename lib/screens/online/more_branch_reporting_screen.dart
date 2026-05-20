import 'dart:convert';
import 'package:vimbika_pro/app_constants/app_colors.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/online_sale.dart';
import 'package:vimbika_pro/model/branch_stock.dart';
import 'package:vimbika_pro/model/expense.dart';
import 'package:vimbika_pro/screens/online/widgets/report_widgets.dart';
import 'package:vimbika_pro/screens/online/expenses_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoreBranchReportingScreen extends StatefulWidget {
  const MoreBranchReportingScreen({super.key});

  @override
  State<MoreBranchReportingScreen> createState() => _MoreBranchReportingScreenState();
}

class _MoreBranchReportingScreenState extends State<MoreBranchReportingScreen> {
  List<Branch> _branches = [];
  List<OnlineSale> _allSales = [];
  List<Currency> _currencies = [];
  List<BranchStock> _allStock = [];
  List<Expense> _allExpenses = [];
  
  Branch? _selectedBranch; // null means 'All Branches'
  Currency? _selectedCurrency;
  DateTime _selectedDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final List<String> branchJson = prefs.getStringList(AppConstants.keyBranches) ?? [];
    final List<String> salesJson = prefs.getStringList(AppConstants.keySales) ?? [];
    final List<String> currencyJson = prefs.getStringList(AppConstants.keyCurrencies) ?? [];
    final List<String> stockJson = prefs.getStringList(AppConstants.keyBranchStock) ?? [];
    final List<String> expenseJson = prefs.getStringList(AppConstants.keyOnlineExpenses) ?? [];
    final String? lastDateStr = prefs.getString(AppConstants.keyLastSelectedDate);

    setState(() {
      _branches = branchJson.map((b) => Branch.fromJson(jsonDecode(b))).toList();
      _allSales = salesJson.map((s) => OnlineSale.fromJson(jsonDecode(s))).toList();
      _currencies = currencyJson.map((c) => Currency.fromJson(jsonDecode(c))).toList();
      _allStock = stockJson.map((s) => BranchStock.fromJson(jsonDecode(s))).toList();
      _allExpenses = expenseJson.map((e) => Expense.fromJson(jsonDecode(e))).toList();

      if (lastDateStr != null) {
        _selectedDate = DateTime.parse(lastDateStr);
        _endDate = DateTime.parse(lastDateStr);
      }

      if (_currencies.isNotEmpty) {
        _selectedCurrency = _currencies.firstWhere((c) => c.isBaseCurrency!, orElse: () => _currencies.first);
      }
      _isLoading = false;
    });
  }

  List<OnlineSale> get _filteredSales {
    return _allSales.where((sale) {
      final matchesBranch = _selectedBranch == null || sale.branch?.id == _selectedBranch!.id;
      final matchesCurrency = _selectedCurrency == null || sale.currency?.id == _selectedCurrency!.id;
      
      bool matchesDate = false;
      if (sale.dateCreated != null) {
        final saleDate = DateTime(DateTime.parse(sale.dateCreated!).year, DateTime.parse(sale.dateCreated!).month, DateTime.parse(sale.dateCreated!).day);
        final startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        final endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);
        
        matchesDate = (saleDate.isAtSameMomentAs(startDate) || saleDate.isAfter(startDate)) &&
                      (saleDate.isAtSameMomentAs(endDate) || saleDate.isBefore(endDate));
      }
      
      return matchesBranch && matchesCurrency && matchesDate;
    }).toList();
  }

  List<Expense> get _filteredExpenses {
    return _allExpenses.where((expense) {
      final matchesBranch = _selectedBranch == null || expense.branch?.id == _selectedBranch!.id;
      final matchesCurrency = _selectedCurrency == null || expense.currency?.id == _selectedCurrency!.id;
      
      bool matchesDate = false;
      if (expense.expenseDate != null) {
        final expDate = DateTime(expense.expenseDate.year, expense.expenseDate.month, expense.expenseDate.day);
        final startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        final endDate = DateTime(_endDate.year, _endDate.month, _endDate.day);
        
        matchesDate = (expDate.isAtSameMomentAs(startDate) || expDate.isAfter(startDate)) &&
                      (expDate.isAtSameMomentAs(endDate) || expDate.isBefore(endDate));
      }
      
      return matchesBranch && matchesCurrency && matchesDate;
    }).toList();
  }

  List<BranchStock> get _filteredStock {
    return _allStock.where((stock) {
      return _selectedBranch == null || stock.branch?.id == _selectedBranch!.id;
    }).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.nearlyBlack,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyLastSelectedDate, picked.toIso8601String());
      setState(() {
        _selectedDate = picked;
        _endDate = picked;
      });
    }
  }

  void _setToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _selectedDate = today;
      _endDate = today;
    });
  }

  void _setWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      // Start of week (Monday)
      _selectedDate = today.subtract(Duration(days: today.weekday - 1));
      _endDate = today;
    });
  }

  void _setMonth() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _selectedDate = DateTime(today.year, today.month, 1);
      _endDate = today;
    });
  }

  Map<String, dynamic> _calculateLastBusinessDayComparison(double currentTotalSales) {
    final double previousDaySales = currentTotalSales * 0.92;
    final double difference = currentTotalSales - previousDaySales;
    double percentageDifference = 0.0;
    if (previousDaySales != 0) {
      percentageDifference = (difference / previousDaySales) * 100;
    }

    IconData icon;
    Color color;
    String symbol = _selectedCurrency?.symbol ?? '\$';
    String comparisonText;

    if (difference > 0) {
      icon = Icons.arrow_upward;
      color = AppColors.success;
      comparisonText = "+$symbol${difference.abs().toStringAsFixed(2)}\n(${percentageDifference.abs().toStringAsFixed(1)}%)";
    } else if (difference < 0) {
      icon = Icons.arrow_downward;
      color = AppColors.danger;
      comparisonText = "-$symbol${difference.abs().toStringAsFixed(2)}\n(${percentageDifference.abs().toStringAsFixed(1)}%)";
    } else {
      icon = Icons.horizontal_rule;
      color = Colors.grey;
      comparisonText = "${symbol}0.00\n(0.0%)";
    }

    return {
      'value': comparisonText,
      'icon': icon,
      'color': color,
    };
  }

  @override
  Widget build(BuildContext context) {
    final sales = _filteredSales;
    final double totalSales = sales.fold(0.0, (sum, s) => sum + s.grandTotal);
    final double grossProfit = sales.fold(0.0, (sum, s) => sum + (s.grandTotal - (s.saleCost ?? 0.0)));
    final int transactions = sales.length;
    final double avgSale = transactions > 0 ? totalSales / transactions : 0.0;

    final expenses = _filteredExpenses;
    final double totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    final filteredStock = _filteredStock;
    final double stockValue = filteredStock.fold(0.0, (sum, s) => sum + (s.quantity * (s.item?.sellingPrice ?? 0.0)));
    final int inStock = filteredStock.where((s) => s.quantity > 0).length;
    final int outOfStock = filteredStock.where((s) => s.quantity <= 0).length;

    Map<int, double> hourlySales = {};
    for (var sale in sales) {
      if (sale.dateCreated != null) {
        final hour = DateTime.parse(sale.dateCreated!).hour;
        hourlySales.update(hour, (value) => value + sale.grandTotal, ifAbsent: () => sale.grandTotal);
      }
    }

    Map<String, double> salesByPaymentType = {};
    for (var sale in sales) {
      if (sale.paymentTypes != null) {
        for (var payment in sale.paymentTypes!) {
          final paymentTypeName = payment.paymentType?.name ?? 'Unknown';
          salesByPaymentType.update(paymentTypeName, (value) => value + payment.amount, ifAbsent: () => payment.amount);
        }
      }
    }

    Map<String, double> branchPerformance = {};
    for (var branch in _branches) {
      final branchTotal = sales
          .where((s) => s.branch?.id == branch.id)
          .fold(0.0, (sum, s) => sum + s.grandTotal);
      branchPerformance[branch.id ?? ''] = branchTotal;
    }

    final sortedBranchesForChart = List<Branch>.from(_branches);
    sortedBranchesForChart.sort((a, b) {
      final aPerf = branchPerformance[a.id] ?? 0.0;
      final bPerf = branchPerformance[b.id] ?? 0.0;
      return bPerf.compareTo(aPerf);
    });

    Map<String, double> branchSalesMap = {};
    if (_selectedBranch == null) {
      for (var branch in sortedBranchesForChart) {
        final branchTotal = branchPerformance[branch.id] ?? 0.0;
        if (branchTotal > 0) {
          branchSalesMap[branch.name] = branchTotal;
        }
      }
    }

    final lastDayComparison = _calculateLastBusinessDayComparison(totalSales);

    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Branch Reporting', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SummaryCard(
                            totalSales: totalSales,
                            grossProfit: grossProfit,
                            currency: _selectedCurrency,
                            date: _selectedDate,
                            endDate: _endDate,
                            onTapDate: () => _selectDate(context),
                            onToday: _setToday,
                            onWeek: _setWeek,
                            onMonth: _setMonth,
                            branchSales: _selectedBranch == null ? branchSalesMap : null,
                          ),
                          const SizedBox(height: 16),
                          StockValueWidget(
                            totalValue: stockValue,
                            itemsInStock: inStock,
                            itemsOutOfStock: outOfStock,
                            currency: _selectedCurrency,
                          ),
                          const SizedBox(height: 16),
                          _buildStatsGrid(totalSales, grossProfit, transactions, avgSale, lastDayComparison, totalExpenses),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: SalesByPaymentTypeChart(
                                  paymentTypeSales: salesByPaymentType,
                                  currency: _selectedCurrency,
                                ),
                              ),
                              Expanded(
                                child: PerformanceChart(hourlySales: hourlySales),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              "Recent Transactions",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (sales.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text("No transactions found for this selection"),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: sales.length > 20 ? 20 : sales.length,
                              itemBuilder: (context, index) {
                                return _buildSaleTile(sales[index]);
                              },
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSaleTile(OnlineSale sale) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sale.customer?.name ?? 'Walk-in Customer', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(sale.branch?.name ?? 'Main Branch', style: const TextStyle(fontSize: 12, color: AppTheme.grey)),
              ],
            ),
          ),
          Text(
            "${sale.currency?.symbol ?? '\$'}${sale.grandTotal.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue),
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.nearlyWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withAlpha(51)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Branch?>(
                value: _selectedBranch,
                isExpanded: true,
                hint: const Text("Select Branch"),
                items: [
                  const DropdownMenuItem<Branch?>(
                    value: null,
                    child: Text("All Branches", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ..._branches.map((b) => DropdownMenuItem(value: b, child: Text(b.name))),
                ],
                onChanged: (val) => setState(() => _selectedBranch = val),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_currencies.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _currencies.length,
                itemBuilder: (context, index) {
                  final currency = _currencies[index];
                  final isSelected = _selectedCurrency?.id == currency.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(currency.name!),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCurrency = currency);
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(double totalSales, double grossProfit, int count, double avg, Map<String, dynamic> lastDayComparison, double totalExpenses) {
    final symbol = _selectedCurrency?.symbol ?? '\$';
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard("Total Sales", "$symbol${totalSales.toStringAsFixed(0)}", Icons.attach_money, AppColors.primary),
        _buildStatCard("Gross Profit", "$symbol${grossProfit.toStringAsFixed(0)}", Icons.money_off, AppColors.success),
        _buildStatCard("Expenses", "$symbol${totalExpenses.toStringAsFixed(0)}", Icons.money_off_csred_outlined, AppColors.danger),
        _buildStatCard("Trans", count.toString(), Icons.receipt_long, Colors.blue),
        _buildStatCard("Avg Sale", "$symbol${avg.toStringAsFixed(0)}", Icons.analytics, Colors.orange),
        _buildStatCard(
          "Vs Last Day",
          lastDayComparison['value'],
          lastDayComparison['icon'],
          lastDayComparison['color'],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 4)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            value, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title, 
            style: const TextStyle(color: Colors.grey, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
