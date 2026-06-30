import 'package:vimbika_pro/app_constants/app_colors.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/screens/online/widgets/report_widgets.dart';
import 'package:vimbika_pro/screens/online/branch_report_screen.dart';
import 'package:vimbika_pro/screens/online/more_branch_reporting_screen.dart'; // Import the new screen
import 'package:vimbika_pro/screens/online/expenses_list_screen.dart';
import 'package:vimbika_pro/screens/online/payments_received_list_screen.dart';
import 'package:vimbika_pro/navigation_home_screen.dart';
import 'package:flutter/material.dart';
import 'online_reports_controller.dart';
import 'package:vimbika_pro/services/excel_export_service.dart'; // Import ExcelExportService
import 'package:intl/intl.dart';

class OnlineReportsScreen extends StatefulWidget {
  const OnlineReportsScreen({super.key});

  @override
  State<OnlineReportsScreen> createState() => _OnlineReportsScreenState();
}

class _OnlineReportsScreenState extends State<OnlineReportsScreen> {
  late OnlineReportsController _controller;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _overviewKey = GlobalKey();
  final GlobalKey _productsKey = GlobalKey();
  final GlobalKey _branchesKey = GlobalKey(); // Keep this key for the section, even if navigation changes
  int _currentIndex = -1;
  final ExcelExportService _excelExportService = ExcelExportService(); // Instantiate ExcelExportService

  void _onScroll() {
    if (_scrollController.hasClients) {
      final double offset = _scrollController.offset;
      int newIndex = -1;

      // Logic to determine which section is currently visible
      // This is a simple approximation
      if (_productsKey.currentContext != null) {
        final renderObject = _productsKey.currentContext!.findRenderObject() as RenderBox;
        final position = renderObject.localToGlobal(Offset.zero).dy;
        if (position < MediaQuery.of(context).size.height / 2) {
          newIndex = 0; // Products
        }
      }

      if (_currentIndex != newIndex) {
        setState(() {
          _currentIndex = newIndex;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _controller = OnlineReportsController(
      context: context,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    _controller.initData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleBottomNavTap(int index) {
    if (index == 1) { // Index 1 is now for Branches/More Branch Reporting
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MoreBranchReportingScreen(),
        ),
      );
    } else {
      // Products
      _scrollController.removeListener(_onScroll);
      setState(() {
        _currentIndex = index;
      });
      GlobalKey? targetKey = _productsKey;

      if (targetKey.currentContext != null) {
        Scrollable.ensureVisible(
          targetKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        ).then((_) {
          // Re-add listener after scroll completes to avoid index flickering during manual-triggered scroll
          Future.delayed(const Duration(milliseconds: 100), () {
            _scrollController.addListener(_onScroll);
          });
        });
      }
    }
  }

  Future<void> _exportShiftActivities() async {
    if (_controller.mobileShifts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No shift activities to export.'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final String fileName = 'Shift_Activities_Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
      await _excelExportService.exportShiftCurrencyAmountsToExcel(_controller.mobileShifts);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shift activities exported as $fileName.xlsx'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export shift activities: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _handleBottomNavTap, // Use the new handler
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_controller.isSyncing)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 3,
              ),
            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _controller.fetchReportData,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            Header(
                                key: _overviewKey,
                                onRefresh: _controller.fetchReportData,
                                onLogout: _controller.logout,
                                isSyncing: _controller.isSyncing,
                                onDashboard: () {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => NavigationHomeScreen()),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.account_circle_outlined, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Logged in as: ${_controller.currentUser?.firstName ?? ''} ${_controller.currentUser?.lastName ?? 'Administrator'}",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            _buildCurrencySelector(),
                            SummaryCard(
                              totalSales: _controller.totalSales,
                              grossProfit: _controller.totalGrossProfit,
                              totalStockValue: _controller.totalStockValue,
                              totalStockCount: _controller.totalStockCount,
                              currency: _controller.selectedCurrency,
                              date: _controller.searchDate,
                              endDate: _controller.endDate,
                              onTapDate: _controller.selectDate,
                              onToday: _controller.setToday,
                              onWeek: _controller.setWeek,
                              onMonth: _controller.setMonth,
                              branchSales: _controller.branchSales,
                              branchProfits: _controller.branchProfits,
                              // Removed salesByAgent
                            ),
                            if (_controller.userBranches.isNotEmpty)
                              Column(
                                key: _branchesKey,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Branches (${_controller.userBranches.length})",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                        if (_controller.selectedBranch != null)
                                          TextButton(
                                            onPressed: () {
                                              _controller.setSelectedBranch(null);
                                              _controller.setPage(1);
                                            },
                                            child: const Text("Clear Filter",
                                                style: TextStyle(color: AppColors.danger, fontSize: 12)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      // Sort branches by performance (total sales)
                                      final sortedBranches = List<Branch>.from(_controller.userBranches);
                                      
                                      // Calculate performance for each branch to sort
                                      final branchPerformance = <String, double>{};
                                      for (var branch in sortedBranches) {
                                        final branchSpecificSales = _controller.onlineSales
                                            .where((s) =>
                                                s.branch?.id == branch.id &&
                                                (_controller.selectedCurrency == null ||
                                                    s.currency?.id == _controller.selectedCurrency!.id))
                                            .toList();
                                        branchPerformance[branch.id ?? ''] = branchSpecificSales.fold(0.0, (sum, s) => sum + s.grandTotal);
                                      }
                                      
                                      sortedBranches.sort((a, b) {
                                        final aPerf = branchPerformance[a.id] ?? 0.0;
                                        final bPerf = branchPerformance[b.id] ?? 0.0;
                                        return bPerf.compareTo(aPerf); // Descending order
                                      });

                                      return GridView.builder(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2, // Changed from 3 to 2
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: 1.4,
                                        ),
                                        itemCount: sortedBranches.length,
                                        itemBuilder: (context, index) {
                                          final branch = sortedBranches[index];
                                          final branchSpecificSales = _controller.onlineSales
                                              .where((s) =>
                                                  s.branch?.id == branch.id &&
                                                  (_controller.selectedCurrency == null ||
                                                      s.currency?.id == _controller.selectedCurrency!.id))
                                              .toList();
                                          final branchSalesSum = branchPerformance[branch.id ?? ''] ?? 0.0;
                                          final branchTransactions = branchSpecificSales.length;

                                          return BranchCard(
                                            name: branch.name!,
                                            sales: branchSalesSum,
                                            transactions: branchTransactions,
                                            avgSale: branchTransactions > 0 ? branchSalesSum / branchTransactions : 0.0,
                                            change: 0,
                                            currency: _controller.selectedCurrency,
                                            isSelected: _controller.selectedBranch?.id == branch.id,
                                            onLongPress: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => BranchReportScreen(
                                                    branch: branch,
                                                    branchSales: branchSpecificSales,
                                                    selectedCurrency: _controller.selectedCurrency,
                                                  ),
                                                ),
                                              );
                                            },
                                            onTap: () {
                                              if (_controller.selectedBranch?.id == branch.id) {
                                                _controller.setSelectedBranch(null);
                                              } else {
                                                _controller.setSelectedBranch(branch);
                                              }
                                              _controller.setPage(1);
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            SalesByPaymentTypeChart(
                              paymentTypeSales: _controller.salesByPaymentType,
                              currency: _controller.selectedCurrency,
                            ),
                            const SizedBox(height: 16),
                            PerformanceChart(hourlySales: _controller.hourlySales),
                            const SizedBox(height: 16),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: ElevatedButton.icon(
                                        onPressed: _exportShiftActivities,
                                        icon: const Icon(Icons.file_download_outlined, size: 18),
                                        label: const Text('Export Activities'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                ShiftActivitySection(
                                  shiftActivities: _controller.mobileShifts,
                                  selectedCurrency: _controller.selectedCurrency,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FinancialsTile(
                              totalExpenses: _controller.totalExpenses,
                              totalCostOfSales: _controller.totalCostOfSales,
                              totalOtherExpenses: _controller.totalOtherExpenses,
                              totalReceivables: _controller.totalReceivables,
                              expensesCount: _controller.expensesCount,
                              receivablesCount: _controller.receivablesCount,
                              totalPayables: _controller.totalPayables,
                              cashOnHand: _controller.cashOnHand,
                              currency: _controller.selectedCurrency,
                              onExpensesTap: () {
                                final filteredExpenses = _controller.expenses.where((e) {
                                  final matchesCurrency = _controller.selectedCurrency == null ||
                                      e.currency?.id == _controller.selectedCurrency!.id;
                                  final matchesBranch = _controller.selectedBranch == null ||
                                      e.branch?.id == _controller.selectedBranch!.id;
                                  final isNotCostOfSales = e.expenseCategory?.name.toLowerCase().trim() != 'cost of sales';
                                  return matchesCurrency && matchesBranch && isNotCostOfSales;
                                }).toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ExpensesListScreen(
                                      expenses: filteredExpenses,
                                      selectedCurrency: _controller.selectedCurrency,
                                    ),
                                  ),
                                );
                              },
                              onReceivablesTap: () {
                                final filteredPayments = _controller.paymentsReceived.where((p) {
                                  final matchesCurrency = _controller.selectedCurrency == null ||
                                      p.currency.value?.id == _controller.selectedCurrency!.id;
                                  // PaymentReceived model doesn't seem to have a branch field directly, 
                                  // but if it's related to a sale, we might filter it.
                                  // For now, filtering only by currency as that's what's available in the model.
                                  return matchesCurrency;
                                }).toList();

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentsReceivedListScreen(
                                      payments: filteredPayments,
                                      selectedCurrency: _controller.selectedCurrency,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // Out of Stock List Section
                            _buildOutOfStockList(key: _productsKey),

                            const SizedBox(height: 16),
                            TopProducts(products: _controller.topProducts),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutOfStockList({Key? key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Out of Stock Items", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_controller.outOfStockItems.length} items",
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_controller.outOfStockItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text("All items are in stock", style: TextStyle(color: Colors.grey))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _controller.outOfStockItems.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _controller.outOfStockItems[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text(item.category.value?.name ?? 'No Category',
                                style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(
                        item.quantity.toStringAsFixed(0),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector() {
    if (_controller.currencies.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _controller.currencies.length,
        itemBuilder: (context, index) {
          final currency = _controller.currencies[index];
          final isSelected = _controller.selectedCurrency?.id == currency.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(currency.name!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _controller.setSelectedCurrency(currency);
                }
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

}
