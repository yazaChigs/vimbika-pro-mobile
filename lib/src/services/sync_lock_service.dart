import 'dart:async';
import 'package:get/get.dart';

/// A service to manage a lock between critical operations like charging a sale
/// and syncing offline data to prevent race conditions.
class SyncLockService extends GetxService {
  // A private RxBool to track the lock state reactively.
  final RxBool _isChargeInProgress = false.obs;

  // A completer to allow awaiting the release of the lock.
  Completer<void>? _chargeCompleter;

  /// Returns true if a charge operation is currently in progress.
  bool get isChargeInProgress => _isChargeInProgress.value;

  /// Acquires the lock for a charge operation.
  /// If a charge is already in progress, this method will wait until it completes
  /// before acquiring the new lock. This prevents multiple charge operations
  /// from running concurrently while ensuring the background sync waits for all of them.
  Future<void> acquireChargeLock() async {
    // Wait for any existing charge operation to complete.
    while (_isChargeInProgress.value && _chargeCompleter != null) {
      await _chargeCompleter!.future;
    }
    // Acquire the lock for the new charge operation.
    _isChargeInProgress.value = true;
    _chargeCompleter = Completer<void>();
    print("SyncLockService: Charge lock acquired.");
  }

  /// Releases the charge lock and notifies any waiting processes.
  void releaseChargeLock() {
    if (_isChargeInProgress.value) {
      _isChargeInProgress.value = false;
      // Complete the future to release any waiting processes (like the background sync).
      _chargeCompleter?.complete();
      _chargeCompleter = null;
      print("SyncLockService: Charge lock released.");
    }
  }

  /// Waits until the current charge operation is complete.
  /// This is used by the background sync to "pause" its execution.
  Future<void> awaitChargeLock() async {
    if (_isChargeInProgress.value && _chargeCompleter != null) {
      print("SyncLockService: Background sync is waiting for charge to finish...");
      await _chargeCompleter!.future;
      print("SyncLockService: Charge finished, background sync can now proceed.");
    }
  }
}
