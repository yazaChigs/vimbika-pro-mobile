import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../model/category.dart';
import '../../../services/category_service.dart'; // Import CategoryService
import '../../../model/branch.dart'; // Import Branch model

class CategoryManagementScreen extends StatefulWidget {
  @override
  _CategoryManagementScreenState createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isOfflineMode = false; // New state variable
  bool _canEdit = true;

  final CategoryService _categoryService = CategoryService(); // Initialize CategoryService

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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

    String categoryKey = isOfflineMode ? AppConstants.keyOfflineCategories : AppConstants.keyCategories;
    
    // Load Categories
    final List<String> categoryListJson = prefs.getStringList(categoryKey) ?? [];
    
    setState(() {
      _categories = categoryListJson
          .map((item) => Category.fromJson(jsonDecode(item)))
          .toList();
      _isLoading = false;
      _isOfflineMode = isOfflineMode; // Set the new state variable
      _canEdit = canEdit;
    });
  }

  Future<void> _saveCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;

    String categoryKey = isOfflineMode ? AppConstants.keyOfflineCategories : AppConstants.keyCategories;

    final List<String> listJson = _categories
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(categoryKey, listJson);
  }

  Future<void> _syncCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? defaultBranchJson = prefs.getString(AppConstants.keyDefaultBranch);

      if (defaultBranchJson != null) {
        final Branch defaultBranch = Branch.fromJson(jsonDecode(defaultBranchJson));
        await _categoryService.fetchCategoriesByBranch(defaultBranch.id!); // Fetch from API and save to SharedPreferences
        await _loadData(); // Reload from SharedPreferences
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categories synced from API')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No default branch set. Cannot sync categories.')),
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sync categories: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCategoryDialog({Category? category}) {
    if (!_canEdit) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You do not have permission to edit categories.')),
        );
        return;
    }
    
    final nameController = TextEditingController(text: category?.name);
    final descriptionController = TextEditingController(text: category?.description);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Category Name')),
                TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description (Optional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                
                final newCategory = Category(
                  id: category?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  description: descriptionController.text,
                );

                this.setState(() {
                  if (category == null) {
                    _categories.add(newCategory);
                  } else {
                    final index = _categories.indexWhere((c) => c.id == category.id);
                    _categories[index] = newCategory;
                  }
                });
                _saveCategories();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: Text('Manage Categories', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.nearlyBlack),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: (_isLoading || _isOfflineMode) ? null : _syncCategories, // Allow all users to sync in online mode
            tooltip: 'Sync Categories',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(child: Text('No categories added yet.'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.vimbikaBlue.withValues(alpha: 0.1),
                          child: Icon(Icons.category, color: AppTheme.vimbikaBlue),
                        ),
                        title: Text(category.name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(category.description ?? 'No description'),
                        trailing: _canEdit ? IconButton(
                          icon: Icon(Icons.edit, color: AppTheme.grey),
                          onPressed: () => _showCategoryDialog(category: category),
                        ) : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: _canEdit ? FloatingActionButton(
        onPressed: () => _showCategoryDialog(),
        backgroundColor: AppTheme.vimbikaBlue,
        child: Icon(Icons.add),
      ) : null,
    );
  }
}
