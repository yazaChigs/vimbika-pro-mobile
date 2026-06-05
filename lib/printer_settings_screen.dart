import 'package:flutter/material.dart';
import 'package:vimbika_pro/services/printer_service.dart';
import 'app_constants/app_theme.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart' hide BluetoothPrinterDevice; // Hide to avoid collision

class PrinterSettingsScreen extends StatefulWidget {
  @override
  _PrinterSettingsScreenState createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printerService = PrinterService();
  bool _isLoading = false;
  List<BluetoothPrinterDeviceModel> _bluetoothDevices = [];
  List<UsbPrinterDevice> _usbDevices = []; // List to hold discovered USB devices
  bool _alwaysPrintReceipt = true; // Initial state for the UI
  int _numberOfReceiptsPerSale = 1; // Added for the new setting
  final TextEditingController _receiptCountController = TextEditingController(); // Controller for the text field

  @override
  void initState() {
    super.initState();
    _initPrinterSettings();
  }

  Future<void> _initPrinterSettings() async {
    setState(() => _isLoading = true);
    await _printerService.init();
    _alwaysPrintReceipt = await _printerService.getAlwaysPrintReceipt();
    _numberOfReceiptsPerSale = await _printerService.getNumberOfReceiptsPerSale(); // Load initial state
    _receiptCountController.text = _numberOfReceiptsPerSale.toString(); // Set controller text
    setState(() {
      _isLoading = false;
      if (_printerService.printerType == PrinterTypes.bluetooth) {
        _getBondedBluetoothDevices();
      } else if (_printerService.printerType == PrinterTypes.usb) {
        _getUsbDevices();
      }
    });
  }

  Future<void> _getBondedBluetoothDevices() async {
    setState(() => _isLoading = true);
    try {
      // The PrinterService now handles discovery.
      await _printerService.init(); 
      setState(() {
        _bluetoothDevices = _printerService.bluetoothDevices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error fetching Bluetooth devices: $e');
    }
  }

  Future<void> _getUsbDevices() async {
    setState(() => _isLoading = true);
    try {
      _usbDevices.clear(); // Clear previous list
      // The PrinterService already handles discovery and updates its internal list.
      // We just need to trigger it and then get the updated list.
      await _printerService.init(); // Re-initialize to trigger discovery if not already running
      setState(() {
        _usbDevices = _printerService.usbDevices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error fetching USB devices: $e');
    }
  }

  void _onPrinterTypeChanged(PrinterTypes? type) async {
    if (type != null) {
      await _printerService.setPrinterType(type);
      setState(() {});
      if (type == PrinterTypes.bluetooth) {
        _getBondedBluetoothDevices();
      } else if (type == PrinterTypes.usb) {
        _getUsbDevices();
      }
    }
  }

  void _onAlwaysPrintReceiptChanged(bool value) async {
    setState(() {
      _alwaysPrintReceipt = value;
    });
    await _printerService.setAlwaysPrintReceipt(value);
  }

  void _onNumberOfReceiptsChanged(String value) async {
    int? count = int.tryParse(value);
    if (count != null && count > 0) {
      setState(() {
        _numberOfReceiptsPerSale = count;
      });
      await _printerService.setNumberOfReceiptsPerSale(count); // Persist the setting
    } else if (value.isEmpty) {
      // Allow empty input temporarily, but don't save 0 or negative
      // The user might be in the middle of typing.
      // We can add more robust validation if needed.
    } else {
      // If invalid input, revert to last valid state or show error
      _receiptCountController.text = _numberOfReceiptsPerSale.toString();
      _showSnackBar('Please enter a valid number (greater than 0).');
    }
  }

  void _connectBluetooth(BluetoothPrinterDeviceModel device) async {
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

  void _connectUsb(UsbPrinterDevice device) async {
    setState(() => _isLoading = true);
    try {
      await _printerService.setSelectedUsbDevice(device);
      _showSnackBar('Connected to ${device.name ?? 'USB Printer'}');
    } catch (e) {
      _showSnackBar('Connection failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _disconnectPrinter() async {
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
      // Print test page multiple times based on the setting
      for (int i = 0; i < _numberOfReceiptsPerSale; i++) {
        await _printerService.printReceipt("Test Page ${i + 1}\nPrinter configured successfully\n");
        if (i < _numberOfReceiptsPerSale - 1) {
          await Future.delayed(const Duration(milliseconds: 500)); // Small delay between prints
        }
      }
      _showSnackBar('Test page(s) sent to printer');
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
  void dispose() {
    _receiptCountController.dispose();
    super.dispose();
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
                          RadioListTile<PrinterTypes>(
                            title: const Text('USB Printer (Windows/Android)'),
                            value: PrinterTypes.usb,
                            groupValue: printerType,
                            onChanged: _onPrinterTypeChanged,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: SwitchListTile(
                      title: const Text('Always Print Receipt'),
                      value: _alwaysPrintReceipt,
                      onChanged: _onAlwaysPrintReceiptChanged,
                      secondary: Icon(Icons.print),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Number of Receipts per Sale', style: Theme.of(context).textTheme.titleMedium),
                          TextFormField(
                            controller: _receiptCountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Number of Copies',
                              hintText: 'e.g., 1, 2, 3',
                            ),
                            onChanged: _onNumberOfReceiptsChanged,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a number';
                              }
                              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                return 'Please enter a positive number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (printerType == PrinterTypes.bluetooth) _buildBluetoothSettings(),
                  if (printerType == PrinterTypes.sunmi) _buildSunmiSettings(),
                  if (printerType == PrinterTypes.usb) _buildUsbSettings(),
                  
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
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton(
                        onPressed: _disconnectPrinter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: AppTheme.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('Disconnect Printer', style: TextStyle(fontSize: 16)),
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

  Widget _buildUsbSettings() {
    final selectedDevice = _printerService.selectedUsbDevice;
    final connected = _printerService.isConnected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedDevice != null)
          Card(
            elevation: 2,
            child: ListTile(
              title: Text(selectedDevice.name ?? 'Unknown USB Device'),
              subtitle: Text('Vendor ID: ${selectedDevice.vendorId}, Product ID: ${selectedDevice.productId}'),
              trailing: connected
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : Icon(Icons.cancel, color: Colors.red),
            ),
          ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _getUsbDevices,
          child: Text('Refresh USB Devices'),
        ),
        SizedBox(height: 16),
        Text('Available USB Devices:', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 8),
        ..._usbDevices.map((device) => Card(
              elevation: 1,
              child: ListTile(
                title: Text(device.name ?? 'Unknown USB Device'),
                subtitle: Text('Vendor ID: ${device.vendorId}, Product ID: ${device.productId}'),
                onTap: () => _connectUsb(device),
                trailing: selectedDevice?.vendorId == device.vendorId &&
                          selectedDevice?.productId == device.productId &&
                          connected
                    ? Icon(Icons.check, color: Colors.green)
                    : null,
              ),
            )),
      ],
    );
  }
}
