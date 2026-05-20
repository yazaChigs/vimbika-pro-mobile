import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pro/app_constants/app_colors.dart';
import 'package:vimbika_pro/model/expense.dart';
import 'package:vimbika_pro/model/currency.dart';

class ExpensesListScreen extends StatelessWidget {
  final List<Expense> expenses;
  final Currency? selectedCurrency;

  const ExpensesListScreen({
    super.key,
    required this.expenses,
    this.selectedCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = selectedCurrency?.symbol ?? '\$';
    final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Expenses List",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
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
                  "$symbol${totalAmount.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                ),
                const Text("Total Expenses",
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: expenses.isEmpty
                ? const Center(
                    child: Text("No expenses found for the selected period",
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.danger.withOpacity(0.1),
                            child: const Icon(Icons.money_off,
                                color: AppColors.danger),
                          ),
                          title: Text(
                            expense.expenseCategory?.name ?? 'General Expense',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (expense.notes != null &&
                                  expense.notes!.isNotEmpty)
                                Text(expense.notes!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              Text(
                                DateFormat('MMM dd, yyyy HH:mm')
                                    .format(expense.expenseDate),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              if (expense.branch != null)
                                Text(
                                  "Branch: ${expense.branch!.name}",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                            ],
                          ),
                          trailing: Text(
                            "$symbol${expense.amount.toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
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
}
