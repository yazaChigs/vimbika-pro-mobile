import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/model/user.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../app_constants/app_constants.dart';
import '../../../model/unit.dart';

class UnitManagementScreen extends StatefulWidget {
  @override
  _UnitManagementScreenState createState() => _UnitManagementScreenState();
}

class _UnitManagementScreenState extends State<UnitManagementScreen> {
  List<Unit> _units = [];
  bool _isLoading = true;
  bool _isOfflineMode = false; // New state variable
  bool _canEdit = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
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

    final String unitKey = _isOfflineMode ? AppConstants.keyOfflineUnits : AppConstants.keyUnits;
    final List<String> listJson = prefs.getStringList(unitKey) ?? [];
    
    setState(() {
      _units = listJson
          .map((item) => Unit.fromJson(jsonDecode(item)))
          .toList();
      _isLoading = false;
      _canEdit = canEdit;
    });
  }

  Future<void> _saveUnits() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String unitKey = _isOfflineMode ? AppConstants.keyOfflineUnits : AppConstants.keyUnits;
    final List<String> listJson = _units
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(unitKey, listJson);
  }

  void _showUnitDialog({Unit? unit}) {
    if (!_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You do not have permission to edit units.')),
      );
      return;
    }

    final nameController = TextEditingController(text: unit?.name);
    final abbreviationController = TextEditingController(text: unit?.abbreviation);
    final descriptionController = TextEditingController(text: unit?.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(unit == null ? 'Add Unit' : 'Edit Unit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Unit Name (e.g. Kilogram)')),
              TextField(controller: abbreviationController, decoration: InputDecoration(labelText: 'Abbreviation (e.g. Kg)')),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              
              final newUnit = Unit(
                id: unit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                abbreviation: abbreviationController.text,
                description: descriptionController.text,
              );

              setState(() {
                if (unit == null) {
                  _units.add(newUnit);
                } else {
                  final index = _units.indexWhere((u) => u.id == unit.id);
                  _units[index] = newUnit;
                }
              });
              _saveUnits();
              Navigator.pop(context);
            },
            child: Text('Save'),
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
        title: Text('Manage Units', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.nearlyBlack),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _units.isEmpty
              ? Center(child: Text('No units added yet.'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _units.length,
                  itemBuilder: (context, index) {
                    final unit = _units[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(unit.name, style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${unit.abbreviation ?? ''} - ${unit.description ?? ''}'),
                        trailing: _canEdit ? IconButton(
                          icon: Icon(Icons.edit, color: AppTheme.grey),
                          onPressed: () => _showUnitDialog(unit: unit),
                        ) : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: _canEdit ? FloatingActionButton(
        onPressed: () => _showUnitDialog(),
        backgroundColor: AppTheme.vimbikaBlue,
        child: Icon(Icons.add),
      ) : null,
    );
  }
}
