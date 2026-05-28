import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../app_constants/app_constants.dart';
import '../model/mobile_shift_currency_amount.dart';
import '../model/mobile_pos_shift.dart';
import '../model/user.dart';
import 'base_http_client.dart';

class MobilePosShiftService {
  final BaseHttpClient _client = BaseHttpClient();

  Future<List<MobileShiftCurrencyAmount>> getMobilePosShiftCurrencyAmountsByDate({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);

    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));

    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');
    final String formattedStartDate = '${startDate.toIso8601String().substring(0, 23)}Z';
    final String formattedEndDate = '${endDate.toIso8601String().substring(0, 23)}Z';


    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/mobile/pos/shift/currency-amounts-by-date/$formattedStartDate/$formattedEndDate',
      companyId,
    );


    final List<dynamic> data = jsonDecode(responseStr);
    final List<MobileShiftCurrencyAmount> list = data.map((e) => MobileShiftCurrencyAmount.fromJson(e)).toList();

    // Save expenses to local storage
    await prefs.setStringList(AppConstants.keyMobileShifts, list.map((e) => e.toJson()).toList());

    return list;
  }

  Future<MobilePosShift> createShiftOfflineFirst(MobilePosShift shift) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. Save locally as the current open shift.
    await prefs.setString(AppConstants.keyCurrentOpenShift, shift.toJson());
    print('Shift saved locally.');

    // 2. Start background sync. Do not await.
    _syncAndUpdateLocalShift(shift);

    // 3. Return the locally saved shift immediately.
    return shift;
  }

  Future<void> _syncAndUpdateLocalShift(MobilePosShift shiftToSync) async {
    print(shiftToSync.shiftCurrencyAmounts!.last.toJson());
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;

      if (isOfflineMode) {
        throw Exception('Offline mode is active');
      }

      print('Starting background shift sync...');
      // Use the existing createShift method to talk to the API
      final syncedShift = await createShift(shiftToSync, syncOnly: true);

      print(syncedShift.shiftCurrencyAmounts!.last.toJson());

      // If sync is successful, update the locally stored shift with server data (e.g., ID)
      await prefs.setString(AppConstants.keyCurrentOpenShift, syncedShift.toJson());
      print('Background shift sync successful. Local shift updated.');

      // Also, if it was in a pending queue, remove it.
      final List<String>? offlineShiftsJson = prefs.getStringList(AppConstants.keyOfflineMobileShifts);
      if (offlineShiftsJson != null) {
        List<MobilePosShift> offlineShifts = offlineShiftsJson.map((s) => MobilePosShift.fromJson(jsonDecode(s))).toList();
        offlineShifts.removeWhere((s) => s.shiftReference == syncedShift.shiftReference);
        await prefs.setStringList(AppConstants.keyOfflineMobileShifts, offlineShifts.map((s) => jsonEncode(s.toJson())).toList());
      }

    } catch (e) {
      print('Background shift sync failed: $e');
      // If sync fails, add it to the offline shifts queue to be synced later.
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? offlineShiftsJsonList = prefs.getStringList(AppConstants.keyOfflineMobileShifts);
      List<MobilePosShift> offlineShifts = [];
      if (offlineShiftsJsonList != null) {
        try {
            offlineShifts = offlineShiftsJsonList.map((s) => MobilePosShift.fromJson(jsonDecode(s))).toList();
        } catch (jsonErr) {
            print('Could not decode offline shifts json: $jsonErr');
        }
      }
      // Avoid adding duplicates
      if (!offlineShifts.any((s) => s.shiftReference == shiftToSync.shiftReference)) {
        offlineShifts.add(shiftToSync);
        await prefs.setStringList(AppConstants.keyOfflineMobileShifts, offlineShifts.map((s) => jsonEncode(s.toJson())).toList());
        print('Shift added to offline queue for later sync.');
      }
    }
  }

  Future<MobilePosShift> createShift(MobilePosShift shift, {bool syncOnly = false}) async {
    if (!syncOnly) {
      return createShiftOfflineFirst(shift);
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);

    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));

    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');
    List<MobilePosShift> shiftList = [];
    shiftList.add(shift);
    String jsonShiftItems = json.encode(
        shiftList.map((shift) => shift.toMap()).toList());
    final String responseStr = await _client.postAuthWithCompanyHeader(
      '/mobile/pos/shift/save',
      jsonShiftItems,
      companyId,
      'POST'
    );

    print(responseStr);


    // Parse the response as a map
    final Map<String, dynamic> responseMap = jsonDecode(responseStr);
    // Extract the list of items
    final List<dynamic> items = responseMap['items'];

    if (items.isEmpty) {
      throw Exception('No shift returned from the server.');
    }

    // Assuming the first item in the list is the created shift
    final MobilePosShift createdShift = MobilePosShift.fromJson(items.first);
    print(createdShift.toJson());
    
    // Save current open shift to shared prefs
    if (!(createdShift.isShiftClosed ?? false)) {
      await prefs.setString(AppConstants.keyCurrentOpenShift, createdShift.toJson());
    }

    return createdShift;
  }

  Future<MobilePosShift> updateShift(MobilePosShift shift) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);

    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));

    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');
    
    String jsonShift = json.encode(shift.toMap());

    final String responseStr = await _client.postAuthWithCompanyHeader(
      '/mobile/pos/shift/save', // Assuming the same endpoint for create and update
      jsonShift,
      companyId,
      'POST'
    );

    final MobilePosShift updatedShift = MobilePosShift.fromRawJson(responseStr);
    
    // Update current open shift in shared prefs
    if (!(updatedShift.isShiftClosed ?? false)) {
      await prefs.setString(AppConstants.keyCurrentOpenShift, updatedShift.toJson());
    } else {
      // If shift is closed, remove it from shared preferences
      await prefs.remove(AppConstants.keyCurrentOpenShift);
    }

    return updatedShift;
  }
}
