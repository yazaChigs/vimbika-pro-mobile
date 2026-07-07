import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pro/app_constants/app_colors.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/online_sale.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:vimbika_pro/screens/online/widgets/report_widgets.dart';

class BranchReportScreen extends StatelessWidget {
  final Branch branch;
  final List<OnlineSale> branchSales;
  final Currency? selectedCurrency;

  const BranchReportScreen({
    super.key,
    required this.branch,
    required this.branchSales,
    this.selectedCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final double totalSales = branchSales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
    final int transactionCount = branchSales.length;
    final double avgSale = transactionCount > 0 ? totalSales / transactionCount : 0.0;
    final symbol = selectedCurrency?.symbol ?? '\$';

    // Calculate hourly sales for this branch
    final Map<int, double> hourlySales = {};
    for (int i = 0; i < 24; i++) {
      hourlySales[i] = 0.0;
    }
    for (var sale in branchSales) {
      final date = DateTime.tryParse(sale.timeIniated ?? '');
      if (date != null) {
        hourlySales[date.hour] = (hourlySales[date.hour] ?? 0.0) + sale.grandTotal;
      }
    }

    // Calculate top products for this branch
    final Map<String, double> productSales = {};
    for (var sale in branchSales) {
      if (sale.allItems.isNotEmpty) {
        for (var item in sale.allItems) {
          final name = item.inventoryItem.value?.name ?? 'Unknown';
          productSales[name] = (productSales[name] ?? 0.0) + item.quantity;
        }
      }
    }
    final topProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayProducts = topProducts.take(10).toList();

    // Sort recent transactions
    final recentTransactions = List<OnlineSale>.from(branchSales)
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a.timeIniated ?? '');
        final dateB = DateTime.tryParse(b.timeIniated ?? '');
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
    final displayTransactions = recentTransactions.take(10).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("${branch.name} Report", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "$symbol${totalSales.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const Text("Total Sales Today", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem("Transactions", transactionCount.toString(), Icons.receipt_long),
                      _buildStatItem("Average Sale", "$symbol${avgSale.toStringAsFixed(2)}", Icons.analytics),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Hourly Performance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  PerformanceChart(hourlySales: hourlySales),
                  const SizedBox(height: 24),
                  const Text("Recent Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRecentTransactionsList(displayTransactions),
                  const SizedBox(height: 24),
                  const Text("Branch Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildBranchDetailsCard(),
                  const SizedBox(height: 24),
                  const Text("Top Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTopProductsList(displayProducts),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildRecentTransactionsList(List<OnlineSale> sales) {
    if (sales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text("No transactions available", style: TextStyle(color: Colors.grey))),
      );
    }

    final symbol = selectedCurrency?.symbol ?? '\$';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sales.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final sale = sales[index];
          final date = DateTime.tryParse(sale.timeIniated ?? '');
          final timeStr = date != null ? DateFormat('HH:mm').format(date) : 'N/A';
          final agentName = sale.createdByName ?? 'Unknown Agent';
          final itemCount = sale.allItems.length;
          final paymentType = sale.paymentType?.name ?? 'N/A'; // Assuming PaymentType has a 'name' field

          return ListTile(
            onTap: () {
              // TODO: Implement navigation to transaction details screen
              print('Tapped on transaction: ${sale.referenceNumber}');
            },
            leading: CircleAvatar(
              backgroundColor: AppColors.success.withOpacity(0.1),
              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.success, size: 20),
            ),
            title: Text("$symbol${sale.grandTotal.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              "$timeStr • $agentName • $itemCount items • $paymentType",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sale.status ?? 'PAID',
                style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopProductsList(List<MapEntry<String, double>> products) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text("No product data available", style: TextStyle(color: Colors.grey))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text("${index + 1}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(product.key, style: const TextStyle(fontWeight: FontWeight.w500)),
            trailing: Text("${product.value.toStringAsFixed(0)} sold", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.vimbikaBlue)),
          );
        },
      ),
    );
  }

  Widget _buildBranchDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.location_on_outlined, "Address", branch.address ?? "No address provided"),
          const Divider(),
          _buildDetailRow(Icons.phone_outlined, "Phone", branch.phoneNumber ?? "No phone number"),
          const Divider(),
          _buildDetailRow(Icons.email_outlined, "Email", branch.email ?? "No email provided"),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
