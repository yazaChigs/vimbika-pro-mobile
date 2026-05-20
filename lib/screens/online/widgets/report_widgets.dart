import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/model/mobile_shift_currency_amount.dart'; // Import the new model

import '../../../app_constants/app_colors.dart';

class SummaryCard extends StatelessWidget {
  final double totalSales;
  final double? grossProfit;
  final double totalStockValue;
  final double totalStockCount;
  final Currency? currency;
  final DateTime date;
  final DateTime endDate;
  final VoidCallback onTapDate;
  final VoidCallback onToday;
  final VoidCallback onWeek;
  final VoidCallback onMonth;
  final Map<String, double>? branchSales;
  final Map<String, double>? branchProfits;
  // Removed salesByAgent

  const SummaryCard({
    super.key, 
    required this.totalSales, 
    this.grossProfit,
    this.totalStockValue = 0.0,
    this.totalStockCount = 0.0,
    this.currency,
    required this.date,
    required this.endDate,
    required this.onTapDate,
    required this.onToday,
    required this.onWeek,
    required this.onMonth,
    this.branchSales,
    this.branchProfits,
    // Removed salesByAgent
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 360;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Sales/Profit and Date Selector
              isSmallScreen 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateAndRangeSection(),
                      const SizedBox(height: 16),
                      _buildMetricsSection(isSmallScreen),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildMetricsSection(isSmallScreen)),
                      const SizedBox(width: 8),
                      _buildDateAndRangeSection(),
                    ],
                  ),
              
              const SizedBox(height: 12),
              Text(
                "Currency: ${currency?.name ?? 'Default'}",
                style: const TextStyle(color: AppColors.textLight, fontSize: 11),
              ),
              
              if (branchSales != null && branchSales!.isNotEmpty) ...[ // Simplified condition
                const SizedBox(height: 20),
                // Branch Comparison Chart
                constraints.maxWidth < 450
                  ? Column(
                      children: [
                        _buildChartSection("Branch Comparison", branchSales!),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildChartSection("Branch Comparison", branchSales!)),
                      ],
                    ),
              ],
            ],
          ),
        );
      }
    );
  }

  Widget _buildMetricsSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("TOTAL SALES",
                    style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  "${currency?.symbol ?? '\$'}${totalSales.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (grossProfit != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("GROSS PROFIT",
                      style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    "${currency?.symbol ?? '\$'}${grossProfit!.toStringAsFixed(2)}",
                    style: const TextStyle(
                        color: AppColors.success, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _buildMetricItem("STOCK VALUE", "${currency?.symbol ?? '\$'}${totalStockValue.toStringAsFixed(2)}"),
            _buildMetricItem("STOCK COUNT", totalStockCount.toStringAsFixed(0)),
            if (branchSales != null && branchSales!.isNotEmpty)
              SizedBox(
                width: 80,
                height: 30,
                child: BranchPerformanceMiniGraph(
                  branchSales: branchSales!,
                  branchProfits: branchProfits ?? {},
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateAndRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        InkWell(
          onTap: onTapDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, color: AppColors.primary, size: 12),
                const SizedBox(width: 4),
                Text(
                  date.day == endDate.day && date.month == endDate.month && date.year == endDate.year
                    ? DateFormat('MMM dd').format(date)
                    : "${DateFormat('MMM dd').format(date)} - ${DateFormat('MMM dd').format(endDate)}",
                  style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.end,
          children: [
            _buildRangeButton("Today", onToday),
            _buildRangeButton("Week", onWeek),
            _buildRangeButton("Month", onMonth),
          ],
        ),
      ],
    );
  }

  Widget _buildChartSection(String title, Map<String, double> data, {Color? barColor, bool showValueLabels = false, Currency? currency}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textLight, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildBarChart(data, barColor: barColor, showValueLabels: showValueLabels, currency: currency),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value, {Color color = AppColors.textDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRangeButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> data, {Color? barColor, bool showValueLabels = false, Currency? currency}) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxValue = data.values.reduce(max);
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, index) {
          final label = data.keys.elementAt(index);
          final value = data.values.elementAt(index);
          final percentage = maxValue > 0 ? value / maxValue : 0.0;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showValueLabels)
                  Text(
                    "${currency?.symbol ?? '\$'}${value.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Expanded(
                  child: Container(
                    width: 45,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 14,
                      height: (percentage * 50) + 2,
                      decoration: BoxDecoration(
                        color: barColor ?? AppColors.primary.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 55,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textDark, 
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BranchPerformanceMiniGraph extends StatelessWidget {
  final Map<String, double> branchSales;
  final Map<String, double> branchProfits;

  const BranchPerformanceMiniGraph({
    super.key,
    required this.branchSales,
    required this.branchProfits,
  });

  @override
  Widget build(BuildContext context) {
    if (branchSales.isEmpty) return const SizedBox.shrink();

    final salesValues = branchSales.values.toList();
    final profitValues = branchProfits.values.toList();

    final maxSales = salesValues.reduce(max);
    final maxProfits = profitValues.isNotEmpty ? profitValues.reduce(max) : 0.0;
    final maxVal = max(maxSales, maxProfits);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Sales Line
          LineChartBarData(
            spots: salesValues.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), maxVal > 0 ? e.value / maxVal : 0);
            }).toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          // Profit Line
          if (profitValues.isNotEmpty)
            LineChartBarData(
              spots: profitValues.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), maxVal > 0 ? e.value / maxVal : 0);
              }).toList(),
              isCurved: true,
              color: AppColors.success,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.success.withValues(alpha: 0.1),
              ),
            ),
        ],
        minX: 0,
        maxX: (salesValues.length - 1).toDouble(),
        minY: 0,
        maxY: 1.1,
      ),
    );
  }
}

class StockValueWidget extends StatelessWidget {
  final double totalValue;
  final int itemsInStock;
  final int itemsOutOfStock;
  final Currency? currency;

  const StockValueWidget({
    super.key,
    required this.totalValue,
    required this.itemsInStock,
    required this.itemsOutOfStock,
    this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = currency?.symbol ?? '\$';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "STOCK VALUE",
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$symbol${totalValue.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 30),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStockIndicator(
                label: "In Stock",
                count: itemsInStock,
                color: AppColors.success,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(width: 24),
              _buildStockIndicator(
                label: "Out of Stock",
                count: itemsOutOfStock,
                color: AppColors.danger,
                icon: Icons.error_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockIndicator({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ]
    );
  }
}

class SalesByPaymentTypeChart extends StatelessWidget {
  final Map<String, double> paymentTypeSales;
  final Currency? currency;

  const SalesByPaymentTypeChart({
    super.key,
    required this.paymentTypeSales,
    this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (paymentTypeSales.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = paymentTypeSales.values.fold(0.0, (sum, sales) => sum + sales);

    // Generate distinct colors for each payment type
    final List<Color> colors = [
      Colors.blue, Colors.green, Colors.red, Colors.purple, Colors.orange,
      Colors.teal, Colors.indigo, Colors.pink, Colors.brown, Colors.cyan,
    ];

    List<PieChartSectionData> pieChartSections = [];
    int colorIndex = 0;
    paymentTypeSales.forEach((paymentType, sales) {
      final percentage = total > 0 ? (sales / total) * 100 : 0.0;
      final color = colors[colorIndex % colors.length];
      pieChartSections.add(
        PieChartSectionData(
          color: color,
          value: sales,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 50, // Increased radius since it's now full width
          titleStyle: const TextStyle(
            fontSize: 12, // Increased font size
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), // Adjusted margin for full width
      padding: const EdgeInsets.all(16), // Restored padding
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PAYMENT TYPES", 
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 14, // Restored font size
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 150, // Increased height
                  child: PieChart(
                    PieChartData(
                      sections: pieChartSections,
                      centerSpaceRadius: 30, // Increased center radius
                      sectionsSpace: 2,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Legend
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: paymentTypeSales.entries.map((entry) {
                    final paymentType = entry.key;
                    final sales = entry.value;
                    final percentage = total > 0 ? (sales / total) * 100 : 0.0;
                    final legendColor = colors[paymentTypeSales.keys.toList().indexOf(paymentType) % colors.length];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            color: legendColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "$paymentType (${percentage.toStringAsFixed(0)}%)",
                              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class BranchCard extends StatelessWidget {
  final String name;
  final double sales;
  final int transactions;
  final double avgSale;
  final int change;
  final Currency? currency;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const BranchCard({
    super.key,
    required this.name,
    required this.sales,
    required this.transactions,
    required this.avgSale,
    required this.change,
    this.currency,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = currency?.symbol ?? '\$';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(4), // Reduced padding from 6 to 4
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 10, // Reduced font size from 11 to 10
                color: isSelected ? AppColors.primary : AppColors.textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1), // Reduced height from 2 to 1
            Text(
              "$symbol${sales.toStringAsFixed(0)}",
              style: const TextStyle(
                fontSize: 12, // Reduced font size from 14 to 12
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              "$transactions sales",
              style: const TextStyle(color: AppColors.textLight, fontSize: 7), // Reduced font size from 8 to 7
            ),
            Text(
              "Avg $symbol${avgSale.toStringAsFixed(0)}",
              style: const TextStyle(color: AppColors.success, fontSize: 7, fontWeight: FontWeight.w500), // Reduced font size from 8 to 7
            ),
          ],
        ),
      ),
    );
  }
}

class TopProducts extends StatelessWidget {
  final List<MapEntry<String, double>> products;
  const TopProducts({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Top Products",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (products.isEmpty)
             const Center(child: Text("No product data available", style: TextStyle(color: Colors.grey, fontSize: 12))),
          ...products.asMap().entries.map((e) {
            final index = e.key + 1;
            final product = e.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Text("$index. ", style: const TextStyle(color: Colors.grey)),
                  Expanded(child: Text(product.key, style: const TextStyle(fontWeight: FontWeight.w500))),
                  Text("${product.value.toStringAsFixed(0)} units", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class PerformanceChart extends StatelessWidget {
  final Map<int, double> hourlySales;
  const PerformanceChart({super.key, required this.hourlySales});

  @override
  Widget build(BuildContext context) {
    final maxVal = hourlySales.values.isEmpty ? 1.0 : hourlySales.values.reduce(max);
    final sortedHours = hourlySales.keys.toList()..sort();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), // Adjusted margin for full width
      padding: const EdgeInsets.all(16), // Restored padding
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hourly Sales", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // Increased font size
          const SizedBox(height: 16),
          SizedBox(
            height: 150, // Increased height
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sortedHours.where((h) => h >= 8 && h <= 18).map((hour) { 
                final val = hourlySales[hour] ?? 0.0;
                final heightFactor = maxVal == 0 ? 0.0 : val / maxVal;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2), // Slightly more spacing
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4), // Slightly more rounded
                            ),
                            height: (heightFactor * 120) + 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$hour",
                          style: const TextStyle(
                            fontSize: 10, 
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text("Time (24h)", style: TextStyle(fontSize: 10, color: AppColors.textLight)),
          ),
        ],
      ),
    );
  }
}

class FinancialsTile extends StatelessWidget {
  final double totalExpenses;
  final double totalCostOfSales;
  final double totalOtherExpenses;
  final double totalReceivables;
  final int expensesCount;
  final int receivablesCount;
  final double totalPayables;
  final double cashOnHand;
  final Currency? currency;
  final VoidCallback? onExpensesTap;
  final VoidCallback? onReceivablesTap;

  const FinancialsTile({
    super.key,
    this.totalExpenses = 0.0,
    this.totalCostOfSales = 0.0,
    this.totalOtherExpenses = 0.0,
    this.totalReceivables = 0.0,
    this.expensesCount = 0,
    this.receivablesCount = 0,
    this.totalPayables = 0.0,
    this.cashOnHand = 0.0,
    this.currency,
    this.onExpensesTap,
    this.onReceivablesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          const Text("Financial Metrics",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem("COST OF SALES",
                  "${currency?.symbol ?? '\$'}${totalCostOfSales.toStringAsFixed(2)}",
                  color: Colors.redAccent),
              _buildMetricItem("OTHER EXPENSES",
                  "${currency?.symbol ?? '\$'}${totalOtherExpenses.toStringAsFixed(2)}",
                  color: Colors.red),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onExpensesTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      _buildMetricItem("TOTAL EXPENSES",
                          "${currency?.symbol ?? '\$'}${totalExpenses.toStringAsFixed(2)}",
                          color: Colors.red,
                          subLabel: "$expensesCount transactions"),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.red),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onReceivablesTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      _buildMetricItem("RECEIVABLES",
                          "${currency?.symbol ?? '\$'}${totalReceivables.toStringAsFixed(2)}",
                          color: Colors.orange,
                          subLabel: "$receivablesCount transactions"),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.orange),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem("PAYABLES",
                  "${currency?.symbol ?? '\$'}${totalPayables.toStringAsFixed(2)}",
                  color: Colors.blue),
              _buildMetricItem("CASH ON HAND",
                  "${currency?.symbol ?? '\$'}${cashOnHand.toStringAsFixed(2)}",
                  color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, {Color color = AppColors.textDark, String? subLabel}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (subLabel != null)
          Text(
            subLabel,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
      ],
    );
  }
}

class ShiftActivitySection extends StatefulWidget {
  final List<MobileShiftCurrencyAmount> shiftActivities;
  final Currency? selectedCurrency;

  const ShiftActivitySection({
    super.key,
    required this.shiftActivities,
    this.selectedCurrency,
  });

  @override
  State<ShiftActivitySection> createState() => _ShiftActivitySectionState();
}

class _ShiftActivitySectionState extends State<ShiftActivitySection> {
  String? _selectedUsername;

  @override
  Widget build(BuildContext context) {
    if (widget.shiftActivities.isEmpty) return const SizedBox.shrink();

    // Get all unique users from the shifts
    final List<String> users = widget.shiftActivities
        .map((s) => s?.createdByName ?? 'Unknown User')
        .toSet()
        .toList()
      ..sort();

    // Filter shifts by selected currency
    var filteredShifts = widget.shiftActivities.where((shift) =>
        widget.selectedCurrency == null || shift?.currency?.id == widget.selectedCurrency!.id).toList();

    // Further filter by selected username if set
    if (_selectedUsername != null) {
      filteredShifts = filteredShifts.where((s) => (s.createdByName ?? 'Unknown User') == _selectedUsername).toList();
    }

    // Group filtered shifts by payment type and sum amounts
    final Map<String, double> paymentTypeTotals = {};
    double totalCashInHand = 0.0;
    
    for (var shift in filteredShifts) {
      final paymentType = shift.paymentType ?? 'Other';
      paymentTypeTotals[paymentType] = (paymentTypeTotals[paymentType] ?? 0.0) + shift.amount;
      
      // Calculate cash in hand specifically for 'Cash' payment type
      // Assuming 'CashOut' and 'CashSubmitted' are amountType values for deductions
      if (paymentType.toLowerCase().startsWith('cash') ) {
        if (shift.amountType == 'CASH_OUT' || shift.amountType == 'CASH_SUBMIT') {
          totalCashInHand -= shift.amount;
        } else {
          totalCashInHand += shift.amount;
        }
      }
    }

    final currencySymbol = widget.selectedCurrency?.symbol ?? 
        (filteredShifts.isNotEmpty ? filteredShifts.first.currency?.symbol : null) ?? '\$';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              const Expanded(
                child: Text(
                  "Shift Activity",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              if (_selectedUsername != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedUsername = null;
                    });
                  },
                  child: const Text("Clear User", style: TextStyle(color: AppColors.danger, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // User selection chips
          if (users.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: users.map((user) {
                  final isSelected = _selectedUsername == user;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(user, style: const TextStyle(fontSize: 10)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedUsername = selected ? user : null;
                        });
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 12),
          
          // Display Total Cash In Hand if it's not zero
          if (totalCashInHand != 0) ...[ // Changed from > 0 to != 0 to show negative cash in hand
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (totalCashInHand > 0 ? AppColors.success : AppColors.danger).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TOTAL CASH IN HAND",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success),
                  ),
                  Text(
                    "$currencySymbol${totalCashInHand.toStringAsFixed(2)}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: totalCashInHand > 0 ? AppColors.success : AppColors.danger),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (filteredShifts.isEmpty)
             const Center(child: Text("No activity for selected user", style: TextStyle(color: Colors.grey, fontSize: 12)))
          else
            ...paymentTypeTotals.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                        Text(
                          "$currencySymbol${entry.value.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(height: 16, thickness: 0.5, color: AppColors.textLight),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final bool isSyncing;
  final VoidCallback? onDashboard;
  const Header({super.key, required this.onRefresh, required this.onLogout, required this.isSyncing, this.onDashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Business Overview",
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              SizedBox(height: 4),
              Text("Cloud Connected ▼",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              if (onDashboard != null)
                IconButton(
                  onPressed: onDashboard,
                  icon: const Icon(Icons.dashboard, color: Colors.white),
                  tooltip: "Dashboard",
                ),
              IconButton(
                onPressed: isSyncing ? null : onRefresh,
                icon: Icon(
                  Icons.refresh, 
                  color: isSyncing ? Colors.white54 : Colors.white
                ),
                tooltip: "Refresh Data",
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: onLogout,
                tooltip: "Logout",
              ),
              const Icon(Icons.notifications, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.inventory_2_outlined, "Products"),
          _buildNavItem(1, Icons.storefront_outlined, "Branches"),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isActive = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? AppColors.primary : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: isActive ? AppColors.primary : Colors.grey,
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
