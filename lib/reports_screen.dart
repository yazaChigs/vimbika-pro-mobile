import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/product_flow_report_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'model/sale.dart';
import 'model/purchase.dart';
import 'model/expense.dart';
import 'model/branch_stock.dart';
import 'app_constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'services/sale_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SaleService _saleService = SaleService();
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );

  double _totalSales = 0.0;
  double _totalCostOfSales = 0.0;
  double _totalPurchases = 0.0;
  double _totalExpenses = 0.0;
  double _totalStockValuePurchase = 0.0;
  double _totalStockValueSelling = 0.0;
  int _outOfStockCount = 0;
  int _lowStockCount = 0;
  int _totalStockItems = 0;
  List<Map<String, dynamic>> _topSoldItems = [];
  List<Map<String, dynamic>> _topCustomers = [];
  int _totalUniqueCustomers = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final bool isOffline = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    
    final String branchStockKey = isOffline ? AppConstants.keyOfflineBranchStock : AppConstants.keyBranchStock;
    final String expensesKey = isOffline ? AppConstants.keyExpenses : AppConstants.keyOnlineExpenses;

    final dateRange = _selectedDateRange;
    final endDateExclusive = dateRange.end.add(const Duration(days: 1));

    // Load Sales from Isar
    final List<Sale> sales = await _saleService.getAllSales();
    final Map<String, double> itemSalesCount = {};
    final Map<String, String> itemNames = {};
    final Map<String, double> customerSalesValue = {};
    final Map<String, String> customerNames = {};

    double salesSum = 0.0;
    double costOfSalesSum = 0.0;
    for (final sale in sales) {
      DateTime? saleDate;
      if (sale.dateCreated != null) saleDate = DateTime.tryParse(sale.dateCreated!);
      if (saleDate == null && sale.timeIniated != null && sale.timeIniated!.isNotEmpty) {
        try {
          saleDate = DateFormat(AppConstants.APP_DATE_TIME_FMT).parse(sale.timeIniated!);
        } catch (e) {
          saleDate = DateTime.tryParse(sale.timeIniated!);
        }
      }
      saleDate ??= DateTime.now();

      if (saleDate.isBefore(dateRange.start) || saleDate.isAfter(endDateExclusive) || saleDate.isAtSameMomentAs(endDateExclusive)) {
        continue;
      }

      salesSum += sale.grandTotal;

      // Top Sold Items calculation & Cost of Sales
      for (final saleItem in sale.allItems) {
        if (saleItem.inventoryItem.value != null) {
          final itemId = saleItem.inventoryItem.value!.id ?? 'unknown';
          itemSalesCount[itemId] = (itemSalesCount[itemId] ?? 0.0) + saleItem.quantity;
          itemNames[itemId] = saleItem.inventoryItem.value!.name;
          
          // Cost of sales: quantity sold * purchase price of the item
          costOfSalesSum += (saleItem.quantity * saleItem.inventoryItem.value!.purchasePrice);
        }
      }

      // Customer Statistics calculation
      if (sale.customer.value != null) {
        final customerId = sale.customer.value!.id ?? 'unknown_${sale.customer.value!.name}';
        customerSalesValue[customerId] = (customerSalesValue[customerId] ?? 0.0) + sale.grandTotal;
        customerNames[customerId] = sale.customer.value!.name;
      }
    }

    // Sort and get top items
    final sortedItems = itemSalesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topSoldItems = sortedItems.take(5).map((e) => {
      'name': itemNames[e.key] ?? 'Unknown Item',
      'quantity': e.value,
    }).toList();

    // Sort and get top customers
    final sortedCustomers = customerSalesValue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCustomers = sortedCustomers.take(5).map((e) => {
      'name': customerNames[e.key] ?? 'Unknown Customer',
      'value': e.value,
    }).toList();

    // Load Purchases
    final List<String> purchasesJson = prefs.getStringList(AppConstants.keyPurchases) ?? [];
    double purchasesSum = 0.0;
    for (final item in purchasesJson) {
      final purchase = Purchase.fromJson(jsonDecode(item));
      final purchaseDate = purchase.purchaseDate;
      
      if (purchaseDate.isBefore(dateRange.start) || purchaseDate.isAfter(endDateExclusive) || purchaseDate.isAtSameMomentAs(endDateExclusive)) {
        continue;
      }
      purchasesSum += purchase.grandTotal;
    }

    // Load Expenses
    final List<String> expensesJson = prefs.getStringList(expensesKey) ?? [];
    double expensesSum = 0.0;
    for (final item in expensesJson) {
        final dynamic decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
            final expense = Expense.fromJson(decoded);
            final expenseDate = expense.expenseDate;
            
            if (expenseDate.isBefore(dateRange.start) || expenseDate.isAfter(endDateExclusive) || expenseDate.isAtSameMomentAs(endDateExclusive)) {
              continue;
            }
            expensesSum += expense.amount;
        }
    }

    // Load Inventory Statistics (Not filtered by date as it's a current snapshot)
    final List<String> stocksJson = prefs.getStringList(branchStockKey) ?? [];
    double stockValuePurchase = 0.0;
    double stockValueSelling = 0.0;
    int outOfStock = 0;
    int lowStock = 0;
    int totalItems = 0;

    for (final stockStr in stocksJson) {
      final stock = BranchStock.fromJson(jsonDecode(stockStr));
      final item = stock.item.value;
      if (item == null) continue;

      totalItems++;
      if (stock.stock <= 0) {
        outOfStock++;
      } else if (stock.stock <= item.reorderLevel) {
        lowStock++;
      }

      stockValuePurchase += (item.purchasePrice * stock.stock);
      stockValueSelling += (item.sellingPrice * stock.stock);
    }

    setState(() {
      _totalSales = salesSum;
      _totalCostOfSales = costOfSalesSum;
      _totalPurchases = purchasesSum;
      _totalExpenses = expensesSum;
      _totalStockValuePurchase = stockValuePurchase;
      _totalStockValueSelling = stockValueSelling;
      _outOfStockCount = outOfStock;
      _lowStockCount = lowStock;
      _totalStockItems = totalItems;
      _topSoldItems = topSoldItems;
      _topCustomers = topCustomers;
      _totalUniqueCustomers = customerSalesValue.length;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Profit = Total Sales - Cost of Sales - Operating Expenses
    final double profit = _totalSales - _totalCostOfSales - _totalExpenses;

    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Business Reports', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDatePicker(),
                  const SizedBox(height: 16),
                  _buildSummaryCard('Gross Sales', _totalSales, Icons.trending_up, Colors.green),
                  const SizedBox(height: 12),
                  _buildSummaryCard('Cost of Sales', _totalCostOfSales, Icons.shopping_basket, Colors.orange),
                  const SizedBox(height: 12),
                  _buildSummaryCard('Operating Expenses', _totalExpenses, Icons.money_off, Colors.red),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildProfitCard(profit),
                  const SizedBox(height: 32),
                  const Text('Inventory Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSummaryCard('Total Stock Purchases', _totalPurchases, Icons.shopping_cart, Colors.blueGrey),
                  const SizedBox(height: 12),
                  _buildInventorySummary(),
                  const SizedBox(height: 32),
                  const Text('Most Sold Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildMostSoldItems(),
                  const SizedBox(height: 32),
                  const Text('Customer Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildCustomerStatistics(),
                  const SizedBox(height: 32),
                  const Text('Advanced Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildAdvancedReportTile(
                    title: 'Product Flow Report',
                    subtitle: 'Track product sourcing (suppliers) and distribution (buyers).',
                    icon: Icons.sync_alt,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductFlowReportScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          initialDateRange: _selectedDateRange,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.vimbikaBlue,
                  onPrimary: Colors.white,
                  onSurface: AppTheme.nearlyBlack,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null && picked != _selectedDateRange) {
          setState(() {
            _selectedDateRange = picked;
          });
          _loadReportData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.grey.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range, color: AppTheme.vimbikaBlue),
                const SizedBox(width: 12),
                Text(
                  '${DateFormat('MMM d, y').format(_selectedDateRange.start)} - ${DateFormat('MMM d, y').format(_selectedDateRange.end)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.nearlyBlack),
                ),
              ],
            ),
            const Icon(Icons.arrow_drop_down, color: AppTheme.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySummary() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Items', _totalStockItems.toString(), Icons.inventory_2, AppTheme.vimbikaBlue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Out of Stock', _outOfStockCount.toString(), Icons.error_outline, Colors.red)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Low Stock', _lowStockCount.toString(), Icons.warning_amber_rounded, Colors.orange)),
            const SizedBox(width: 12),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard('Stock Value (Purchase)', _totalStockValuePurchase, Icons.account_balance_wallet, Colors.blueGrey),
        const SizedBox(height: 12),
        _buildSummaryCard('Stock Value (Selling)', _totalStockValueSelling, Icons.monetization_on, Colors.teal),
      ],
    );
  }

  Widget _buildMostSoldItems() {
    if (_topSoldItems.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No sales data available', style: TextStyle(color: AppTheme.grey))));
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _topSoldItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _topSoldItems[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.vimbikaBlue.withAlpha(25),
              child: Text('${index + 1}', style: const TextStyle(color: AppTheme.vimbikaBlue, fontWeight: FontWeight.bold)),
            ),
            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: Text(
              '${item['quantity'].toStringAsFixed(0)} units',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerStatistics() {
    return Column(
      children: [
        _buildStatCard('Unique Customers', _totalUniqueCustomers.toString(), Icons.people_outline, Colors.indigo),
        const SizedBox(height: 12),
        if (_topCustomers.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Top Customers by Revenue', style: TextStyle(fontSize: 14, color: AppTheme.grey, fontWeight: FontWeight.w500)),
            ),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _topCustomers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final customer = _topCustomers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.withAlpha(25),
                    child: const Icon(Icons.person, color: Colors.indigo, size: 20),
                  ),
                  title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                  trailing: Text(
                    '\$${customer['value'].toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                );
              },
            ),
          ),
        ] else
          const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No customer data available', style: TextStyle(color: AppTheme.grey)))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 14, color: AppTheme.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: AppTheme.grey)),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitCard(double profit) {
    final bool isPositive = profit >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPositive ? Colors.green : Colors.red).withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            isPositive ? 'NET PROFIT' : 'NET LOSS',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${profit.abs().toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isPositive ? 'Keep up the good work!' : 'Watch your expenses.',
            style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedReportTile({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      elevation: 0,
      color: AppTheme.vimbikaBlue.withAlpha(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.vimbikaBlue.withAlpha(30))),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.vimbikaBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.vimbikaBlue),
        onTap: onTap,
      ),
    );
  }
}
