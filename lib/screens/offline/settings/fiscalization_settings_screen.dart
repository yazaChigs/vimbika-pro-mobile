import 'package:flutter/material.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/services/printer_service.dart';

class FiscalizationSettingsScreen extends StatefulWidget {
  const FiscalizationSettingsScreen({super.key});

  @override
  State<FiscalizationSettingsScreen> createState() => _FiscalizationSettingsScreenState();
}

class _FiscalizationSettingsScreenState extends State<FiscalizationSettingsScreen> {
  bool _fiscalisationEnabled = false;
  bool _alwaysFiscalize = false;
  bool _isLoading = true;
  final PrinterService _printerService = PrinterService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _printerService.init();
    setState(() {
      _fiscalisationEnabled = _printerService.getFiscalisationEnabled();
      _alwaysFiscalize = _printerService.getAlwaysFiscalize();
      _isLoading = false;
    });
  }

  Future<void> _toggleFiscalisation(bool value) async {
    await _printerService.setFiscalisationEnabled(value);
    setState(() {
      _fiscalisationEnabled = value;
    });
  }

  Future<void> _toggleAlwaysFiscalize(bool value) async {
    await _printerService.setAlwaysFiscalize(value);
    setState(() {
      _alwaysFiscalize = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Fiscalization Settings', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSwitchTile(
                  title: 'Enable Fiscalisation',
                  subtitle: 'Enable fiscal record keeping for sales.',
                  value: _fiscalisationEnabled,
                  onChanged: _toggleFiscalisation,
                ),
                if (_fiscalisationEnabled)
                  _buildSwitchTile(
                    title: 'Always Fiscalize',
                    subtitle: 'Automatically toggle fiscalize for all sales.',
                    value: _alwaysFiscalize,
                    onChanged: _toggleAlwaysFiscalize,
                  ),
              ],
            ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.vimbikaBlue,
      ),
    );
  }
}
