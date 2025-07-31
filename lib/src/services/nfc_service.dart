import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:vimbika_pos_app/src/shared/models/customer_model.dart';

class NfcService extends GetxController {
  RxBool isNfcAvailable = false.obs;
  RxString nfcStatus = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      bool available = await NfcManager.instance.isAvailable();
      isNfcAvailable.value = available;
      nfcStatus.value = available ? 'NFC Available' : 'NFC Not Available';
    } catch (e) {
      isNfcAvailable.value = false;
      nfcStatus.value = 'NFC Error: $e';
    }
  }

  Future<Map<String, dynamic>> getNfcHardwareInfo() async {
    try {
      bool available = await NfcManager.instance.isAvailable();
      return {
        'available': available,
        'enabled': available, // Simplified for now
        'message': available ? 'NFC is available' : 'NFC is not available',
      };
    } catch (e) {
      return {
        'available': false,
        'enabled': false,
        'message': 'Error checking NFC: $e',
      };
    }
  }

  Future<void> checkNfcOnStartup() async {
    Map<String, dynamic> nfcInfo = await getNfcHardwareInfo();

    if (!nfcInfo['available']) {
      _showNfcEnableDialog(nfcInfo);
    } else if (!nfcInfo['enabled']) {
      _showNfcEnableDialog(nfcInfo);
    }
  }

  void _showNfcEnableDialog(Map<String, dynamic> nfcInfo) {
    Get.dialog(
      AlertDialog(
        title: Text('NFC Setup Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NFC is required for customer card functionality.'),
            SizedBox(height: 10),
            Text('Current Status: ${nfcInfo['message']}'),
            SizedBox(height: 10),
            Text('To enable NFC:'),
            Text('1. Go to Settings > Connections > NFC'),
            Text('2. Turn ON "NFC and contactless payments"'),
            Text('3. Restart the app'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () => _openDeviceSettings(),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _openDeviceSettings() {
    // This would open device settings in a real implementation
    Get.back();
    Get.snackbar(
      'Settings',
      'Please manually open device settings and enable NFC',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Future<void> retryNfcCheck() async {
    await _checkNfcAvailability();
    Map<String, dynamic> nfcInfo = await getNfcHardwareInfo();

    if (nfcInfo['available'] && nfcInfo['enabled']) {
      Get.snackbar(
        'NFC Working',
        'NFC is now available and enabled!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      _showAlternativeOptions();
    }
  }

  void _showAlternativeOptions() {
    Get.dialog(
      AlertDialog(
        title: Text('NFC Not Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NFC is still not available on this device.'),
            SizedBox(height: 10),
            Text('Alternative options:'),
            SizedBox(height: 10),
            ListTile(
              leading: Icon(Icons.search),
              title: Text('Manual Search'),
              subtitle: Text('Search for customers manually'),
            ),
            ListTile(
              leading: Icon(Icons.qr_code_scanner),
              title: Text('Barcode Scanner'),
              subtitle: Text('Use camera to scan customer cards'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void showNfcWaitingDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 10),
            Text('Reading NFC Card'),
          ],
        ),
        content: Text('Please hold your device near the NFC card...'),
      ),
    );
  }

  Future<String?> readNfcCard() async {
    if (!isNfcAvailable.value) {
      nfcStatus.value = 'NFC not available on this device';
      return null;
    }

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        nfcStatus.value = 'NFC not available';
        return null;
      }

      // Show waiting dialog
      showNfcWaitingDialog();

      Completer<String?> completer = Completer<String?>();

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            // Try to read NDEF data first
            Ndef? ndef = Ndef.from(tag);
            if (ndef != null) {
              NdefMessage message = await ndef.read();
              for (NdefRecord record in message.records) {
                if (record.type.length == 1 && record.type[0] == 0x01) {
                  // Text record
                  String text = _decodeTextRecord(record);
                  if (text.isNotEmpty) {
                    NfcManager.instance.stopSession();
                    Get.back(); // Close waiting dialog
                    completer.complete(text);
                    return;
                  }
                }
              }
            }

            // If no NDEF data, try to get card UID
            String cardUid = _getCardUid(tag);
            if (cardUid.isNotEmpty) {
              NfcManager.instance.stopSession();
              Get.back(); // Close waiting dialog
              completer.complete(cardUid);
              return;
            }

            NfcManager.instance.stopSession();
            Get.back(); // Close waiting dialog
            completer.complete(null);
          } catch (e) {
            NfcManager.instance.stopSession();
            Get.back(); // Close waiting dialog
            completer.complete(null);
          }
        },
      );

      String? result = await completer.future;

      if (result != null) {
        nfcStatus.value = 'Card read successfully: $result';
        return result;
      } else {
        nfcStatus.value = 'Failed to read card';
        return null;
      }
    } catch (e) {
      nfcStatus.value = 'Error reading NFC card';
      return null;
    }
  }

  String _decodeTextRecord(NdefRecord record) {
    try {
      List<int> payload = record.payload;
      if (payload.length < 3) return '';

      // Skip status byte and language code
      int textStart = 3;
      List<int> textBytes = payload.sublist(textStart);
      return String.fromCharCodes(textBytes);
    } catch (e) {
      return '';
    }
  }

  String _getCardUid(NfcTag tag) {
    try {
      // Try to get UID from different technologies
      for (String tech in tag.data.keys) {
        Map<Object?, Object?> techData = tag.data[tech]!;

        if (techData.containsKey('identifier')) {
          List<Object?> identifierRaw = techData['identifier'] as List<Object?>;
          List<int> identifier = identifierRaw.map((e) => e as int).toList();
          String uid = identifier
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join()
              .toUpperCase();
          return uid;
        }

        // For Mifare Classic, also check for 'atqa' and 'sak'
        if (tech == 'nfca' &&
            techData.containsKey('atqa') &&
            techData.containsKey('sak')) {
          if (techData.containsKey('identifier')) {
            List<Object?> identifierRaw =
                techData['identifier'] as List<Object?>;
            List<int> identifier = identifierRaw.map((e) => e as int).toList();
            String uid = identifier
                .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
                .join()
                .toUpperCase();
            return uid;
          }
        }
      }

      return '';
    } catch (e) {
      return '';
    }
  }

  Future<bool> writeCustomerToCard(CustomerModel customer) async {
    if (!isNfcAvailable.value) {
      return false;
    }

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        return false;
      }

      Completer<bool> completer = Completer<bool>();

      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            Ndef? ndef = Ndef.from(tag);
            if (ndef != null) {
              // Create NDEF message with customer data
              String customerData =
                  '${customer.name}|${customer.accountNumber}|${customer.nfcCardId}';
              NdefRecord record = NdefRecord.createText(customerData);
              NdefMessage message = NdefMessage([record]);

              await ndef.write(message);
              NfcManager.instance.stopSession();
              completer.complete(true);
            } else {
              NfcManager.instance.stopSession();
              completer.complete(false);
            }
          } catch (e) {
            NfcManager.instance.stopSession();
            completer.complete(false);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      return false;
    }
  }
}
