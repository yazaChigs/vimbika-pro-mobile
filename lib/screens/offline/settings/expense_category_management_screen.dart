import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../model/expense_category.dart';

class ExpenseCategoryManagementScreen extends StatefulWidget {
  const ExpenseCategoryManagementScreen({super.key});

  @override
  _ExpenseCategoryManagementScreenState createState() => _ExpenseCategoryManagementScreenState();
}

class _ExpenseCategoryManagementScreenState extends State<ExpenseCategoryManagementScreen> {
  List<ExpenseCategory> _categories = [];
  bool _isLoading = true;
  bool _canEdit = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;

    bool canEdit = true;
    if (!isOfflineMode) {
      final String? userDataJson = prefs.getString(AppConstants.keyOnlineUserData);
      if (userDataJson != null) {
        final user = User.fromJson(jsonDecode(userDataJson));
        canEdit = user.userRoles?.any((role) => role.name == 'ROLE_SUPER_ADMIN') ?? false;
      } else {
        canEdit = false;
      }
    }
    
    final List<String> listJson = prefs.getStringList(AppConstants.keyExpenseCategories) ?? [];
    
    setState(() {
      _categories = listJson
          .map((item) => ExpenseCategory.fromJson(jsonDecode(item)))
          .toList();
      _isLoading = false;
      _canEdit = canEdit;
    });
  }

  Future<void> _saveCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> listJson = _categories
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(AppConstants.keyExpenseCategories, listJson);
  }

  void _showCategoryDialog({ExpenseCategory? category}) {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to edit expense categories.')),
      );
      return;
    }
    
    final nameController = TextEditingController(text: category?.name);
    final descriptionController = TextEditingController(text: category?.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Expense Category' : 'Edit Expense Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Category Name')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              
              final newCategory = ExpenseCategory(
                id: category?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                description: descriptionController.text,
              );

              setState(() {
                if (category == null) {
                  _categories.add(newCategory);
                } else {
                  final index = _categories.indexWhere((c) => c.id == category.id);
                  _categories[index] = newCategory;
                }
              });
              _saveCategories();
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Expense Categories', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(child: Text('No expense categories added yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(category.description ?? 'No description'),
                        trailing: _canEdit ? IconButton(
                          icon: const Icon(Icons.edit, color: AppTheme.grey),
                          onPressed: () => _showCategoryDialog(category: category),
                        ) : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: _canEdit ? FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: AppTheme.vimbikaBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }
}
