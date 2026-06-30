import 'package:vimbika_pro/services/company_service.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/app_constants/app_constants.dart';
import 'package:vimbika_pro/model/branch.dart';
import 'package:vimbika_pro/model/company.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BranchManagementScreen extends StatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  Branch? _defaultBranch;
  Company? _company;
  bool _isLoading = true;
  bool _isOfflineMode = false; // New state variable
  bool _canEdit = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false; // Set offline mode state
    
    bool canEdit = true;
    if (!_isOfflineMode) {
      final String? userDataJson = prefs.getString(AppConstants.keyOnlineUserData);
      if (userDataJson != null) {
        final user = User.fromJson(jsonDecode(userDataJson));
        canEdit = user.userRoles?.any((role) => role.name == 'ROLE_SUPER_ADMIN') ?? false;
      } else {
        canEdit = false;
      }
    }

    // Load Company (this might still be an online call, but the request focuses on branch data)
    _company = await CompanyService().getCompany();

    // Determine which key to use for branches
    String branchKey = _isOfflineMode ? AppConstants.keyOfflineBranch : AppConstants.keyDefaultBranch;

    // Load Default Branch
    final String? defaultBranchJson = prefs.getString(branchKey);
    if (defaultBranchJson != null) {
      _defaultBranch = Branch.fromJson(jsonDecode(defaultBranchJson));
    }

    setState(() {
      _isLoading = false;
      _canEdit = canEdit;
    });
  }

  Future<void> _saveDefaultBranch(Branch branch) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String branchJson = jsonEncode(branch.toJson());
    
    // Determine which key to use for branches
    String branchKey = _isOfflineMode ? AppConstants.keyOfflineBranch : AppConstants.keyDefaultBranch;
    String branchesListKey = _isOfflineMode ? AppConstants.keyOfflineBranches : AppConstants.keyBranches; // Assuming a similar pattern for a list of branches

    // 1. Save to the appropriate default branch key
    await prefs.setString(branchKey, branchJson);
    
    // 2. Save to the appropriate branches list key (as a list containing only this branch)
    await prefs.setStringList(branchesListKey, [branchJson]);

    setState(() {
      _defaultBranch = branch;
    });
  }

  void _showBranchDialog() {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to edit branch data.')),
      );
      return;
    }

    final nameController = TextEditingController(text: _defaultBranch?.name);
    final addressController = TextEditingController(text: _defaultBranch?.address);
    final phoneController = TextEditingController(text: _defaultBranch?.phoneNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_defaultBranch == null ? 'Setup Branch' : 'Edit Branch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Branch Name')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              
              final branch = Branch(
                id: _defaultBranch?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                address: addressController.text,
                phoneNumber: phoneController.text,
              );
              if (_company != null) {
                branch.company.value = _company;
              }

              _saveDefaultBranch(branch);
              Navigator.pop(context);
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
        title: const Text('Branch Settings', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Active Business Branch', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('The primary location where this POS operates.', style: TextStyle(fontSize: 14, color: AppTheme.grey)),
                  const SizedBox(height: 24),
                  if (_defaultBranch == null)
                    _buildEmptyState()
                  else
                    _buildBranchCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildBranchCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.vimbikaBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.store, color: AppTheme.vimbikaBlue),
            ),
            title: Text(_defaultBranch!.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: const Text('Main Operating Branch'),
            trailing: _canEdit ? IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.vimbikaBlue),
              onPressed: _showBranchDialog,
            ) : null,
          ),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDetailRow(Icons.location_on_outlined, _defaultBranch!.address ?? 'No address set'),
                const SizedBox(height: 12),
                _buildDetailRow(Icons.phone_outlined, _defaultBranch!.phoneNumber ?? 'No phone set'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.grey),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(color: AppTheme.darkText)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.storefront_outlined, size: 80, color: AppTheme.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No branch setup yet.'),
          const SizedBox(height: 16),
          if (_canEdit)
            ElevatedButton(
              onPressed: _showBranchDialog,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.vimbikaBlue),
              child: const Text('Setup Branch', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
