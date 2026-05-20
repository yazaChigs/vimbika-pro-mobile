import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/add_expense_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'model/expense.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    _loadExpenses();
    super.initState();
  }

  Future<void> _loadExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> listJson = prefs.getStringList(AppConstants.keyExpenses) ?? [];
    
    setState(() {
      _expenses = listJson
          .map((item) => Expense.fromJson(jsonDecode(item)))
          .toList()
          .reversed.toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Expenses', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.money_off_rounded, size: 64, color: AppTheme.grey.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No expenses recorded yet.', style: TextStyle(color: AppTheme.grey, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Tap + to record your first expense', style: TextStyle(color: AppTheme.grey.withOpacity(0.7))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _expenses.length,
                  itemBuilder: (context, index) {
                    final expense = _expenses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AddExpenseScreen(expense: expense)),
                          );
                          if (result == true) _loadExpenses();
                        },
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.red),
                        ),
                        title: Text(expense.expenseCategory?.name ?? 'General Expense', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${DateFormat('MMM dd, yyyy').format(expense.expenseDate)} - ${expense.notes ?? ''}'),
                            if (expense.supplier != null)
                              Text('Paid to: ${expense.supplier!.name}', style: const TextStyle(fontSize: 12)),
                            if (expense.payments != null && expense.payments!.isNotEmpty)
                              Text(
                                'Methods: ${expense.payments!.map((p) => p.paymentType?.name ?? 'Unknown').join(', ')}', 
                                style: const TextStyle(fontSize: 11, color: AppTheme.grey)
                              ),
                          ],
                        ),
                        trailing: Text(
                          '-\$${expense.amount.toStringAsFixed(2)}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
          if (result == true) _loadExpenses();
        },
        backgroundColor: AppTheme.vimbikaBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
