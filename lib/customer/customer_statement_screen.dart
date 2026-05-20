import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../app_constants/app_constants.dart';

class StatementEntry {
  final DateTime date;
  final String description;
  final double debit; // Sales / Charges
  final double credit; // Payments
  final String reference;

  StatementEntry({
    required this.date,
    required this.description,
    this.debit = 0.0,
    this.credit = 0.0,
    required this.reference,
  });
}

class CustomerStatementScreen extends StatefulWidget {
  final Customer customer;

  const CustomerStatementScreen({super.key, required this.customer});

  @override
  State<CustomerStatementScreen> createState() => _CustomerStatementScreenState();
}

class _CustomerStatementScreenState extends State<CustomerStatementScreen> {
  List<StatementEntry> _ledger = [];
  double _totalBilled = 0.0;
  double _totalPaid = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatement();
  }

  Future<void> _loadStatement() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOffline = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    
    // Load Sales
    final String salesKey = isOffline ? AppConstants.keyOfflineSales : AppConstants.keySales;
    final List<String> salesJson = prefs.getStringList(salesKey) ?? [];
    
    // Load unattached payments (e.g. from "Add Balance" or account top-ups)
    final String offlinePaymentsKey = AppConstants.keyOfflinePaymentsReceived;
    final List<String> offlinePaymentsJson = prefs.getStringList(offlinePaymentsKey) ?? [];
    
    final String unsyncedPaymentsKey = AppConstants.keyUnsyncedReceivedPayments;
    final List<String> unsyncedPaymentsJson = prefs.getStringList(unsyncedPaymentsKey) ?? [];

    List<StatementEntry> entries = [];
    double billed = 0.0;
    double paid = 0.0;
    
    // To avoid duplicate payments, keep track of payment IDs
    Set<String> processedPaymentIds = {};

    for (var item in salesJson) {
      final sale = Sale.fromJson(jsonDecode(item));
      if (sale.customer?.id == widget.customer.id) {
        
        bool isCreditSale = false;

        // Check if the sale was entirely a credit sale
        if (sale.payments != null && sale.payments!.isNotEmpty) {
           // A sale is considered a "credit sale" if the payment method used implies they are not paying cash now.
           // Since our payment types for credit start with CREDIT- or ACC- (sometimes), we need to check.
           // Actually, if they use ACC- it means they paid from existing balance. 
           // If they use CREDIT-, it means they are creating a debt.
           
           // For simplicity, let's just say a sale creates a debit (bill) no matter what.
           // If they pay immediately (even from account), it creates a matching credit.
        }

        // Add Sale as a Debit
        entries.add(StatementEntry(
          date: DateTime.tryParse(sale.timeIniated) ?? DateTime.now(),
          description: 'Invoice Sale',
          debit: sale.grandTotal,
          reference: '#${sale.id?.substring(0, 8).toUpperCase() ?? sale.posReference ?? 'N/A'}',
        ));
        billed += sale.grandTotal;

        // Add each Payment as a Credit
        if (sale.payments != null) {
          for (var payment in sale.payments!) {
            if (payment.id != null) processedPaymentIds.add(payment.id!);
            
            final String paymentName = payment.paymentType?.name.toUpperCase() ?? '';

            if (paymentName.startsWith('ACC-')) {
                // Paying FROM account reduces the debt on this specific invoice, 
                // but technically means we are using pre-existing credits.
                // It still acts as a credit against this sale in the ledger context.
                entries.add(StatementEntry(
                  date: DateTime.tryParse(payment.paymentDate ?? sale.timeIniated) ?? DateTime.now(),
                  description: 'Paid via Account Balance',
                  credit: payment.amount,
                  reference: '#${sale.id?.substring(0, 8).toUpperCase() ?? sale.posReference ?? 'N/A'}',
                ));
                paid += payment.amount;
            } else if (paymentName.startsWith('CREDIT-')) {
                // If the payment type is CREDIT-, it means they are taking it on credit.
                // This means NO actual money was received.
                // We should NOT add this as a credit to their statement, because they still owe this money.
                // The sale itself already added the debit.
            } else {
                // Standard cash/bank payment
                entries.add(StatementEntry(
                  date: DateTime.tryParse(payment.paymentDate ?? sale.timeIniated) ?? DateTime.now(),
                  description: 'Payment Received (${payment.paymentType?.name ?? "Cash"})',
                  credit: payment.amount,
                  reference: '#${sale.id?.substring(0, 8).toUpperCase() ?? sale.posReference ?? 'N/A'}',
                ));
                paid += payment.amount;
            }
          }
        }
      }
    }
    
    // Process standalone payments (Top-ups / Add Balance)
    // Combine offline and unsynced to ensure we get all local ones
    List<PaymentReceived> standalonePayments = [];
    for (var item in offlinePaymentsJson) {
        standalonePayments.add(PaymentReceived.fromJson(jsonDecode(item)));
    }
    for (var item in unsyncedPaymentsJson) {
        final payment = PaymentReceived.fromJson(jsonDecode(item));
        if (!standalonePayments.any((p) => p.id == payment.id)) {
            standalonePayments.add(payment);
        }
    }
    
    for (var payment in standalonePayments) {
        // Only process if it belongs to this customer and wasn't already processed as part of a sale
        if (payment.payer?.id == widget.customer.id && (payment.id == null || !processedPaymentIds.contains(payment.id))) {
            
            // If it's a PAY_ACCOUNT description, it means money was deposited INTO the account
            if (payment.paymentDescription == 'PAY_ACCOUNT') {
                entries.add(StatementEntry(
                  date: DateTime.tryParse(payment.dateTime ?? payment.paymentDate ?? '') ?? DateTime.now(),
                  description: 'Account Deposit (${payment.paymentType?.name ?? "Cash"})',
                  credit: payment.amount,
                  reference: '#${payment.id?.substring(0, 8).toUpperCase() ?? 'TOPUP'}',
                ));
                paid += payment.amount;
            } else if (payment.paymentDescription == 'SALE') {
                 // In case a standalone sale payment got orphaned here
                
                final String paymentName = payment.paymentType?.name.toUpperCase() ?? '';
                if (!paymentName.startsWith('CREDIT-') && !paymentName.startsWith('ACC-')) {
                   entries.add(StatementEntry(
                    date: DateTime.tryParse(payment.dateTime ?? payment.paymentDate ?? '') ?? DateTime.now(),
                    description: 'Payment Received (${payment.paymentType?.name ?? "Cash"})',
                    credit: payment.amount,
                    reference: '#${payment.id?.substring(0, 8).toUpperCase() ?? 'PAYMENT'}',
                  ));
                  paid += payment.amount;
                }
            } else if (payment.paymentType?.isCredit == true && payment.paymentType?.name != null && !payment.paymentType!.name.toUpperCase().startsWith('ACC-')) {
                 // This is a charge to the account (buying on credit) not attached to a sale? Unlikely but handle it
                 entries.add(StatementEntry(
                  date: DateTime.tryParse(payment.dateTime ?? payment.paymentDate ?? '') ?? DateTime.now(),
                  description: 'Credit Charge',
                  debit: payment.amount,
                  reference: '#${payment.id?.substring(0, 8).toUpperCase() ?? 'CREDIT'}',
                ));
                billed += payment.amount;
            }
            
            if (payment.id != null) processedPaymentIds.add(payment.id!);
        }
    }

    // Sort by date latest first
    entries.sort((a, b) => b.date.compareTo(a.date));

    setState(() {
      _ledger = entries;
      _totalBilled = billed;
      _totalPaid = paid;
      _isLoading = false;
    });
  }

  double get _balanceDue => _totalBilled - _totalPaid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Account Statement', style: AppTheme.title),
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
                                        Text(DateFormat('MMM dd, yyyy HH:mm').format(entry.date), style: const TextStyle(fontSize: 12)),
                                        Text(entry.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        Text(entry.reference, style: const TextStyle(fontSize: 10, color: AppTheme.grey)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.debit > 0 ? '\$${entry.debit.toStringAsFixed(2)}' : '-',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.credit > 0 ? '\$${entry.credit.toStringAsFixed(2)}' : '-',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(color: Colors.green),
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
          Text(widget.customer.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.customer.email ?? widget.customer.phoneNumber ?? '', style: const TextStyle(color: AppTheme.grey)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Debits', _totalBilled, Colors.red),
              _buildSummaryItem('Total Credits', _totalPaid, Colors.green),
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
          Expanded(child: Text('Debit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          Expanded(child: Text('Credit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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