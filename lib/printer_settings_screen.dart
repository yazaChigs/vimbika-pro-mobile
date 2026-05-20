import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:vimbika_pro/services/printer_service.dart';
import 'app_constants/app_theme.dart';

class PrinterSettingsScreen extends StatefulWidget {
  @override
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printerService = PrinterService();
  bool _isLoading = false;
  List<BluetoothDevice> _bluetoothDevices = [];

  @override
  void initState() {
    super.initState();
    _printerService.init().then((_) {
      setState(() {});
      if (_printerService.printerType == PrinterTypes.bluetooth) {
        _getBondedBluetoothDevices();
      }
    });
  }

  Future<void> _getBondedBluetoothDevices() async {
    setState(() => _isLoading = true);
    try {
      List<BluetoothDevice> devices = await BlueThermalPrinter.instance.getBondedDevices();
      setState(() {
        _bluetoothDevices = devices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error fetching devices: $e');
    }
  }

  void _onPrinterTypeChanged(PrinterTypes? type) async {
    if (type != null) {
      await _printerService.setPrinterType(type);
      setState(() {});
      if (type == PrinterTypes.bluetooth) {
        _getBondedBluetoothDevices();
      }
    }
  }

  void _connectBluetooth(BluetoothDevice device) async {
    setState(() => _isLoading = true);
    try {
      await _printerService.setSelectedBluetoothDevice(device);
      _showSnackBar('Connected to ${device.name}');
    } catch (e) {
      _showSnackBar('Connection failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _disconnectBluetooth() async {
    setState(() => _isLoading = true);
    await _printerService.disconnect();
    setState(() => _isLoading = false);
  }

  Future<void> _printTestPage() async {
    if (!_printerService.isConnected) {
      _showSnackBar('Please connect to a printer first');
      return;
    }

    try {
      await _printerService.printReceipt("Test Page\nPrinter configured successfully\n");
      _showSnackBar('Test page sent to printer');
    } catch (e) {
      _showSnackBar('Print Error: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _printerService.isConnected;
    final printerType = _printerService.printerType;

    return Scaffold(
      appBar: AppBar(
        title: Text('Printer Settings'),
        backgroundColor: AppTheme.white,
        iconTheme: IconThemeData(color: AppTheme.nearlyBlack),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Printer Type', style: Theme.of(context).textTheme.titleLarge),
                          RadioListTile<PrinterTypes>(
                            title: const Text('Bluetooth Printer'),
                            value: PrinterTypes.bluetooth,
                            groupValue: printerType,
                            onChanged: _onPrinterTypeChanged,
                          ),
                          RadioListTile<PrinterTypes>(
                            title: const Text('Sunmi Internal Printer'),
                            value: PrinterTypes.sunmi,
                            groupValue: printerType,
                            onChanged: _onPrinterTypeChanged,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (printerType == PrinterTypes.bluetooth) _buildBluetoothSettings(),
                  if (printerType == PrinterTypes.sunmi) _buildSunmiSettings(),
                  
                  if (connected) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: ElevatedButton(
                        onPressed: _printTestPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.vimbikaBlue,
                          foregroundColor: AppTheme.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('Print Test Page', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBluetoothSettings() {
    final selectedDevice = _printerService.selectedBluetoothDevice;
    final connected = _printerService.isConnected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedDevice != null)
          Card(
            elevation: 2,
            child: ListTile(
              title: Text(selectedDevice.name ?? 'Unknown Device'),
              subtitle: Text(selectedDevice.address ?? ''),
              trailing: connected
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : Icon(Icons.cancel, color: Colors.red),
            ),
          ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _getBondedBluetoothDevices,
          child: Text('Refresh Devices'),
        ),
        SizedBox(height: 16),
        Text('Available Devices:', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        ..._bluetoothDevices.map((device) => Card(
              elevation: 1,
              child: ListTile(
                title: Text(device.name ?? 'Unknown Device'),
                subtitle: Text(device.address ?? ''),
                onTap: () => _connectBluetooth(device),
                trailing: selectedDevice?.address == device.address && connected
                    ? Icon(Icons.check, color: Colors.green)
                    : null,
              ),
            )),
        if (connected)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: ElevatedButton(
              onPressed: _disconnectBluetooth,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: Text('Disconnect'),
            ),
          ),
      ],
    );
  }

  Widget _buildSunmiSettings() {
    final connected = _printerService.isConnected;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              connected ? Icons.print : Icons.print_disabled,
              size: 48,
              color: connected ? Colors.green : Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              connected ? 'Sunmi Printer is Ready' : 'Sunmi Printer Not Found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}