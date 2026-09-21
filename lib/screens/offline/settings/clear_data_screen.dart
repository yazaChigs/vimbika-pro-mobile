import 'package:flutter/material.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';
import 'package:vimbika_pro/login/login_screen.dart';
import 'package:vimbika_pro/services/clear_data_service.dart';

class ClearDataScreen extends StatefulWidget {
  const ClearDataScreen({super.key});

  @override
  State<ClearDataScreen> createState() => _ClearDataScreenState();
}

class _ClearDataScreenState extends State<ClearDataScreen> {
  final ClearDataService _clearDataService = ClearDataService();
  bool _isLoading = true;
  bool _isProcessing = false;
  Map<String, int> _dataCounts = {
    'sales': 0,
    'inventory': 0,
    'customers': 0,
    'payments': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDataCounts();
  }

  Future<void> _loadDataCounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final counts = await _clearDataService.getDataCounts();
      if (mounted) {
        setState(() {
          _dataCounts = counts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmButtonText,
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDestructive ? Colors.red.shade700 : AppTheme.darkText,
              ),
            ),
            content: Text(message),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDestructive ? Colors.red : AppTheme.vimbikaBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(confirmButtonText),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleClearAction({
    required String title,
    required String message,
    required String confirmButtonText,
    required Future<void> Function() onConfirm,
    required String successMessage,
    bool isDestructive = false,
    bool isFullReset = false,
  }) async {
    final confirmed = await _showConfirmationDialog(
      title: title,
      message: message,
      confirmButtonText: confirmButtonText,
      isDestructive: isDestructive,
    );

    if (!confirmed || !mounted) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await onConfirm();

      if (!mounted) return;

      if (isFullReset) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        await _loadDataCounts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.nearlyWhite,
      appBar: AppBar(
        title: const Text('Clear Data', style: AppTheme.title),
        backgroundColor: AppTheme.white,
        iconTheme: const IconThemeData(color: AppTheme.nearlyBlack),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isProcessing ? null : _loadDataCounts,
            tooltip: 'Refresh data statistics',
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildInfoHeader(),
              const SizedBox(height: 16),
              _buildDataSummaryCard(),
              const SizedBox(height: 24),
              const Text(
                'Data Cleaning Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkerText,
                ),
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                icon: Icons.receipt_long_outlined,
                iconColor: Colors.orange,
                title: 'Clear Transactions & Shifts',
                subtitle:
                    'Delete local sales, received payments, held sales, and shift logs. (Preserves inventory and login)',
                count: '${_dataCounts['sales'] ?? 0} sales, ${_dataCounts['payments'] ?? 0} payments',
                onTap: () => _handleClearAction(
                  title: 'Clear Transactions?',
                  message:
                      'Are you sure you want to clear all locally saved sales, payments, and shifts? Unsynced offline sales will be permanently lost.',
                  confirmButtonText: 'Clear Transactions',
                  onConfirm: _clearDataService.clearTransactionsAndShifts,
                  successMessage: 'Transactions and shifts cleared successfully.',
                  isDestructive: true,
                ),
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                icon: Icons.inventory_2_outlined,
                iconColor: Colors.blue,
                title: 'Clear Inventory Cache',
                subtitle:
                    'Remove cached products, categories, stock levels, and units so they can be re-synced.',
                count: '${_dataCounts['inventory'] ?? 0} items',
                onTap: () => _handleClearAction(
                  title: 'Clear Inventory Cache?',
                  message:
                      'This will clear local inventory items and stock caches. You can re-download them from the server when online.',
                  confirmButtonText: 'Clear Inventory',
                  onConfirm: _clearDataService.clearInventoryData,
                  successMessage: 'Inventory cache cleared successfully.',
                ),
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                icon: Icons.people_outline,
                iconColor: Colors.teal,
                title: 'Clear Customers Cache',
                subtitle:
                    'Remove cached customer records and offline balance data.',
                count: '${_dataCounts['customers'] ?? 0} customers',
                onTap: () => _handleClearAction(
                  title: 'Clear Customer Cache?',
                  message:
                      'This will clear local customer cache. Customer records can be re-synced from the server.',
                  confirmButtonText: 'Clear Customers',
                  onConfirm: _clearDataService.clearCustomerData,
                  successMessage: 'Customer cache cleared successfully.',
                ),
              ),
              const SizedBox(height: 12),
              _buildOptionCard(
                icon: Icons.cached_outlined,
                iconColor: Colors.purple,
                title: 'Clear App Cache & Temp Files',
                subtitle:
                    'Free up storage by clearing image memory cache and temporary files.',
                onTap: () => _handleClearAction(
                  title: 'Clear Temporary Cache?',
                  message:
                      'This will clear cached images and temporary app files across your device storage.',
                  confirmButtonText: 'Clear Cache',
                  onConfirm: _clearDataService.clearTempCache,
                  successMessage: 'Temporary cache cleared successfully.',
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Full Application Reset',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              _buildDangerResetCard(),
              const SizedBox(height: 32),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Clearing data...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Manage and reset local storage. Clearing data helps resolve local sync discrepancies or prepare your device for a fresh start. This feature is fully supported across Windows, Android, and iOS.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSummaryCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Local Storage Overview',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppTheme.darkerText,
              ),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCountBadge('Sales', _dataCounts['sales'] ?? 0, Colors.orange),
                      _buildCountBadge('Products', _dataCounts['inventory'] ?? 0, Colors.blue),
                      _buildCountBadge('Customers', _dataCounts['customers'] ?? 0, Colors.teal),
                      _buildCountBadge('Payments', _dataCounts['payments'] ?? 0, Colors.indigo),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBadge(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? count,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isProcessing ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: iconColor.withOpacity(0.12),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.darkText,
                            ),
                          ),
                        ),
                        if (count != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              count,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.grey,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDangerResetCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade300),
      ),
      color: Colors.red.shade50.withOpacity(0.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isProcessing
            ? null
            : () => _handleClearAction(
                  title: 'Wipe All Data (Factory Reset)?',
                  message:
                      'WARNING: This will permanently delete ALL local database tables, offline sales, payments, cached records, products, customers, and configuration files from this device, and log you out. This action CANNOT be undone.',
                  confirmButtonText: 'Wipe All Data',
                  onConfirm: _clearDataService.clearAllData,
                  successMessage: 'All data has been reset.',
                  isDestructive: true,
                  isFullReset: true,
                ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.red.shade100,
                child: const Icon(Icons.delete_forever, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clear All Data (Factory Reset)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Wipes all local database records, cached settings, and logs out to a fresh state.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.darkText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}
