import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/customer.dart';
import 'package:vimbika_pro/model/sale.dart';
import 'package:vimbika_pro/model/payment_received.dart';
import 'package:vimbika_pro/model/currency.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

import '../app_constants/app_constants.dart';
import '../services/customer_service.dart';
import '../services/sale_service.dart';

class StatementEntry {
  final DateTime date;
  final String description;
  final double debit; // Sales / Charges
  final double credit; // Payments
  final String reference;
  final double balance;

  StatementEntry({
    required this.date,
    required this.description,
    this.debit = 0.0,
    this.credit = 0.0,
    required this.reference,
    this.balance = 0.0,
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
  String _baseCurrencySymbol = '\$';
  DateTime? _startDate;
  DateTime? _endDate;
  List<Currency> _currencies = [];
  Currency? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  Future<void> _initializeFilters() async {
    await _loadCurrencies();
    if (!mounted) return;
    _selectedCurrency = _currencies.isNotEmpty ? _currencies.firstWhere((c) => c.isBaseCurrency == true, orElse: () => _currencies.first) : null;
    _loadStatement();
  }

  Future<void> _loadCurrencies() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> currenciesJson = prefs.getStringList(AppConstants.keyCurrencies) ?? [];
    if (currenciesJson.isNotEmpty) {
      if (mounted) {
        setState(() {
          _currencies = currenciesJson.map((c) => Currency.fromJson(jsonDecode(c))).toList();
        });
      }
    }
  }

  Future<void> _loadStatement() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final bool isOffline = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;
    
    if (_selectedCurrency != null) {
      if (mounted) {
        setState(() {
          _baseCurrencySymbol = _selectedCurrency!.symbol ?? '\$';
        });
      }
    }
    
    List<StatementEntry> entries = [];
    double billed = 0.0;
    double paid = 0.0;

    if (isOffline) {
      // Load Sales
      final String salesKey = AppConstants.keyOfflineSales;
      final List<String> salesJson = prefs.getStringList(salesKey) ?? [];
      
      // Load unattached payments (e.g. from "Add Balance" or account top-ups)
      final String offlinePaymentsKey = AppConstants.keyOfflinePaymentsReceived;
      final List<String> offlinePaymentsJson = prefs.getStringList(offlinePaymentsKey) ?? [];
      
      final String unsyncedPaymentsKey = AppConstants.keyUnsyncedReceivedPayments;
      final List<String> unsyncedPaymentsJson = prefs.getStringList(unsyncedPaymentsKey) ?? [];

      // To avoid duplicate payments, keep track of payment IDs
      Set<String> processedPaymentIds = {};

      for (var item in salesJson) {
        final sale = Sale.fromJson(jsonDecode(item));
        if (sale.customer.value?.id == widget.customer.id) {
          
          // Add Sale as a Debit
          entries.add(StatementEntry(
            date: DateTime.tryParse(sale.timeIniated!) ?? DateTime.now(),
            description: 'Invoice Sale',
            debit: sale.grandTotal,
            reference: '#${sale.id.toString() ?? sale.posReference ?? 'N/A'}',
          ));
          billed += sale.grandTotal;

          // Add each Payment as a Credit
          if (sale.paymentTypes.isNotEmpty) {
            for (var payment in sale.paymentTypes) {
              if (payment.id != null) processedPaymentIds.add(payment.id.toString());
              
              final String paymentName = payment.paymentType.value?.name.toUpperCase() ?? '';

              if (paymentName.startsWith('ACC-')) {
                  entries.add(StatementEntry(
                    date: DateTime.tryParse(payment.paymentDate ?? sale.timeIniated!) ?? DateTime.now(),
                    description: 'Paid via Account Balance',
                    credit: payment.amount,
                    reference: '#${sale.id.toString()?? sale.posReference ?? 'N/A'}',
                  ));
                  paid += payment.amount;
              } else if (paymentName.startsWith('CREDIT-')) {
                  // Do not add as credit, as it's a debt
              } else {
                  // Standard cash/bank payment
                  entries.add(StatementEntry(
                    date: DateTime.tryParse(payment.paymentDate ?? sale.timeIniated!) ?? DateTime.now(),
                    description: 'Payment Received (${payment.paymentType.value?.name ?? "Cash"})',
                    credit: payment.amount,
                    reference: '#${sale.id.toString()?? sale.posReference ?? 'N/A'}',
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
        if (payment.payer.value?.id == widget.customer.id && (payment.id == null || !processedPaymentIds.contains(payment.id))) {
          // If it's a PAY_ACCOUNT description, it means money was deposited INTO the account
          if (payment.paymentDescription == 'PAY_ACCOUNT') {
            entries.add(StatementEntry(
              date: DateTime.tryParse(payment.dateTime ?? payment.paymentDate ?? '') ?? DateTime.now(),
              description: 'Account Deposit (${payment.paymentType.value?.name ?? "Cash"})',
              credit: payment.amount,
              reference: '#${payment.id.toString() ?? 'TOPUP'}',
            ));
            paid += payment.amount;
          } else if (payment.paymentDescription == 'SALE') {
            // In case a standalone sale payment got orphaned here

            final String paymentName = payment.paymentType.value?.name.toUpperCase() ?? '';
            if (!paymentName.startsWith('CREDIT-') && !paymentName.startsWith('ACC-')) {
              entries.add(StatementEntry(
                date: DateTime.tryParse(payment.dateTime ?? payment.paymentDate ?? '') ?? DateTime.now(),
                description: 'Payment Received (${payment.paymentType.value?.name ?? "Cash"})',
                credit: payment.amount,
                reference: '#${payment.id.toString() ?? 'PAYMENT'}',
              ));
              paid += payment.amount;
            }
          } else if (payment.paymentType.value?.isCredit == true &&
              payment.paymentType.value?.name != null &&
              !payment.paymentType.value!.name.toUpperCase().startsWith('ACC-')) {
            // This is a charge to the account (buying on credit) not attached to a sale? Unlikely but handle it
            entries.add(StatementEntry(
              date: DateTime.tryParse(payment.dateTime ?? payment.paymentDate ?? '') ?? DateTime.now(),
              description: 'Credit Charge',
              debit: payment.amount,
              reference: '#${payment.id.toString() ?? 'CREDIT'}',
            ));
            billed += payment.amount;
          }
              
              if (payment.id != null) processedPaymentIds.add(payment.id.toString());
          }
      }
    } else {
      // Online mode: Fetch statements from CustomerService
      try {
        final customerService = CustomerService();
        final ledgerResponse = await customerService.getCustomerStatements(
          currency: _selectedCurrency!.name!,
          counterPartyId: widget.customer.id,
          startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
          endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
        );

        if (ledgerResponse.lines != null) {
            final onlineEntries = ledgerResponse.lines!.map((row) {
              return StatementEntry(
                  date: row.date ?? DateTime.now(),
                  description: row.type ?? row.accountingSource ?? 'N/A',
                  debit: row.debit ?? 0.0,
                  credit: row.credit ?? 0.0,
                  reference: row.reference ?? 'N/A',
                  balance: row.runningBalance ?? 0.0
              );
            }).toList();

            entries.addAll(onlineEntries);

            for (var entry in onlineEntries) {
              billed += entry.debit;
              paid += entry.credit;
            }
        }
      } catch (e) {
        // Handle error, e.g., show a snackbar or log the error
        debugPrint('Error fetching online statement: $e');
        // Optionally, fall back to offline data or show an error message to the user
      }
    }

    // Sort by date latest first
    entries.sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _ledger = entries;
        _totalBilled = billed;
        _totalPaid = paid;
        _isLoading = false;
      });
    }
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
                _buildFilterBar(),
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
                                      entry.debit > 0 ? '$_baseCurrencySymbol${entry.debit.toStringAsFixed(2)}' : '-',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.credit > 0 ? '$_baseCurrencySymbol${entry.credit.toStringAsFixed(2)}' : '-',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(color: Colors.green),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '$_baseCurrencySymbol${entry.balance.toStringAsFixed(2)}',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<Currency>(
              value: _selectedCurrency,
              hint: const Text('Select Currency'),
              isExpanded: true,
              items: _currencies.map((Currency currency) {
                return DropdownMenuItem<Currency>(
                  value: currency,
                  child: Text(currency.name ?? 'Unnamed Currency'),
                );
              }).toList(),
              onChanged: (Currency? newValue) {
                setState(() {
                  _selectedCurrency = newValue;
                  _loadStatement();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
                initialDateRange: _startDate != null && _endDate != null
                    ? DateTimeRange(start: _startDate!, end: _endDate!)
                    : null,
              );
              if (picked != null) {
                if (mounted) {
                  setState(() {
                    _startDate = picked.start;
                    _endDate = picked.end;
                    _loadStatement();
                  });
                }
              }
            },
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _loadStatement();
                });
              },
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
          Text(widget.customer.email ?? widget.customer.mobilePhone ?? '', style: const TextStyle(color: AppTheme.grey)),
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
          Expanded(child: Text('Balance', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
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
          '$_baseCurrencySymbol${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
