import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/supplier.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'add_supplier_screen.dart';
import 'supplier_statement_screen.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() => _SupplierManagementScreenState();
}

class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  List<Supplier> _suppliers = [];
  bool _isLoading = true;

  @override
  void initState() {
    _loadSuppliers();
    super.initState();
  }

  Future<void> _loadSuppliers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> listJson = prefs.getStringList('suppliers') ?? [];
    
    setState(() {
      _suppliers = listJson
          .map((item) => Supplier.fromJson(jsonDecode(item)))
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Manage Suppliers', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suppliers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping_outlined, size: 64, color: AppTheme.grey.withAlpha(128)),
                      const SizedBox(height: 16),
                      const Text('No suppliers added yet.', style: TextStyle(color: AppTheme.grey, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first supplier', style: TextStyle(color: AppTheme.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _suppliers.length,
                  itemBuilder: (context, index) {
                    final supplier = _suppliers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SupplierStatementScreen(supplier: supplier)),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.vimbikaBlue.withAlpha(25),
                          child: const Icon(Icons.local_shipping_outlined, color: AppTheme.vimbikaBlue),
                        ),
                        title: Text(supplier.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (supplier.contactPerson != null && supplier.contactPerson!.isNotEmpty)
                              Text('Contact: ${supplier.contactPerson!}'),
                            if (supplier.phoneNumber != null && supplier.phoneNumber!.isNotEmpty)
                              Text(supplier.phoneNumber!),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.grey),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AddSupplierScreen(supplier: supplier)),
                                );
                                if (result != null && result is Supplier) _loadSuppliers();
                              },
                            ),
                            const Icon(Icons.chevron_right, color: AppTheme.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSupplierScreen()),
          );
          if (result != null && result is Supplier) _loadSuppliers();
        },
        backgroundColor: AppTheme.vimbikaBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
