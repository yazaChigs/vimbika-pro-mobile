import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/supplier.dart';
import 'package:vimbika_pro/model/purchase.dart';
import 'package:vimbika_pro/model/expense.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class SupplierStatementEntry {
  final DateTime date;
  final String description;
  final double debit; // Payments made to supplier
  final double credit; // Purchases/Expenses from supplier (what we owe)
  final String reference;

  SupplierStatementEntry({
    required this.date,
    required this.description,
    this.debit = 0.0,
    this.credit = 0.0,
    required this.reference,
  });
}

class SupplierStatementScreen extends StatefulWidget {
  final Supplier supplier;

  const SupplierStatementScreen({super.key, required this.supplier});

  @override
  State<SupplierStatementScreen> createState() => _SupplierStatementScreenState();
}

class _SupplierStatementScreenState extends State<SupplierStatementScreen> {
  List<SupplierStatementEntry> _ledger = [];
  double _totalOwed = 0.0;
  double _totalPaid = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatement();
  }

  Future<void> _loadStatement() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    final List<String> purchasesJson = prefs.getStringList('purchases') ?? [];
    final List<String> expensesJson = prefs.getStringList('expenses') ?? [];
    
    List<SupplierStatementEntry> entries = [];
    double owed = 0.0;
    double paid = 0.0;

    // 1. Process Purchases
    for (var item in purchasesJson) {
      final purchase = Purchase.fromJson(jsonDecode(item));
      if (purchase.supplier?.id == widget.supplier.id) {
        // Purchase adds to what we owe (Credit)
        entries.add(SupplierStatementEntry(
          date: purchase.purchaseDate,
          description: 'Stock Purchase',
          credit: purchase.grandTotal,
          reference: '#P${purchase.id?.substring(0, 8).toUpperCase()}',
        ));
        owed += purchase.grandTotal;

        // Each payment made reduces what we owe (Debit)
        if (purchase.payments != null) {
          for (var payment in purchase.payments!) {
            entries.add(SupplierStatementEntry(
              date: payment.paymentDate ?? purchase.purchaseDate,
              description: 'Payment Made (${payment.paymentType?.name ?? "Cash"})',
              debit: payment.amount,
              reference: '#P${purchase.id?.substring(0, 8).toUpperCase()}',
            ));
            paid += payment.amount;
          }
        }
      }
    }

    // 2. Process Expenses linked to this supplier
    for (var item in expensesJson) {
      final expense = Expense.fromJson(jsonDecode(item));
      if (expense.supplier?.id == widget.supplier.id) {
        // Expense adds to what we owe (Credit)
        entries.add(SupplierStatementEntry(
          date: expense.expenseDate,
          description: 'Expense: ${expense.expenseCategory?.name ?? "General"}',
          credit: expense.amount,
          reference: '#E${expense.id?.substring(0, 8).toUpperCase()}',
        ));
        owed += expense.amount;

        // Expense payments (Debit)
        if (expense.payments != null) {
          for (var payment in expense.payments!) {
            entries.add(SupplierStatementEntry(
              date: payment.paymentDate ?? expense.expenseDate,
              description: 'Expense Payment (${payment.paymentType?.name ?? "Cash"})',
              debit: payment.amount,
              reference: '#E${expense.id?.substring(0, 8).toUpperCase()}',
            ));
            paid += payment.amount;
          }
        }
      }
    }

    entries.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _ledger = entries;
      _totalOwed = owed;
      _totalPaid = paid;
      _isLoading = false;
    });
  }

  double get _balanceDue => _totalOwed - _totalPaid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Supplier Statement', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildLedgerHeaders(),
                Expanded(
                  child: _ledger.isEmpty
                      ? const Center(child: Text('No transaction history found.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _ledger.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final entry = _ledger[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(DateFormat('MMM dd, yyyy').format(entry.date), style: const TextStyle(fontSize: 12)),
                                        Text(entry.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(entry.reference, style: const TextStyle(fontSize: 10, color: AppTheme.grey)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.debit > 0 ? '\$${entry.debit.toStringAsFixed(2)}' : '-',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(color: Colors.green),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.credit > 0 ? '\$${entry.credit.toStringAsFixed(2)}' : '-',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppTheme.white,
      child: Column(
        children: [
          Text(widget.supplier.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.supplier.contactPerson ?? widget.supplier.phoneNumber ?? '', style: const TextStyle(color: AppTheme.grey)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Owed', _totalOwed, Colors.red),
              _buildSummaryItem('Total Paid', _totalPaid, Colors.green),
              _buildSummaryItem('Balance', _balanceDue, Colors.black),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerHeaders() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.grey.withAlpha(20),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text('Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text('Paid (Dr)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text('Owed (Cr)', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.grey)),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
