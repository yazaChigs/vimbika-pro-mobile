import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_constants/app_constants.dart';
import '../model/mobile_shift_currency_amount.dart';
import '../model/mobile_pos_shift.dart';
import '../model/user.dart';
import '../model/sale.dart'; // Import the Sale model
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
    await prefs.setStringList(AppConstants.keyMobileShifts, list.map((e) => jsonEncode(e.toJson())).toList());

    return list;
  }

  Future<List<MobilePosShift>> getShiftsByUserId(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. Try to load from cache first
    final List<String>? cachedShiftsJson = prefs.getStringList(AppConstants.keyCachedPastShifts);
    if (cachedShiftsJson != null && cachedShiftsJson.isNotEmpty) {
      try {
        final List<MobilePosShift> cachedShifts = cachedShiftsJson
            .map((jsonString) => MobilePosShift.fromJson(jsonDecode(jsonString)))
            .toList();
        print('Loaded shifts from cache.');
        return cachedShifts;
      } catch (e) {
        print('Error decoding cached shifts: $e. Fetching from API.');
        // If cached data is corrupted, proceed to fetch from API
      }
    }

    // 2. If not in cache or cache is corrupted, fetch from API
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);

    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));

    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/mobile/pos/shift/user/$userId',
      companyId,
    );

    final List<dynamic> data = jsonDecode(responseStr);
    final List<MobilePosShift> shifts = data.map((e) => MobilePosShift.fromJson(e)).toList();

    // 3. Save fetched shifts to cache for future use
    final List<String> shiftStrings = shifts.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(AppConstants.keyCachedPastShifts, shiftStrings);
    print('Fetched shifts from API and saved to cache.');

    return shifts;
  }

  Future<Map<String, dynamic>> getOpenShift(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(AppConstants.keyOnlineUserData);

    if (userData == null) throw Exception('User not logged in');
    final user = User.fromJson(jsonDecode(userData));

    final String? companyId = user.branch?.company?.id;
    if (companyId == null) throw Exception('Company ID not found for user');

    final String responseStr = await _client.getAuthWithCompanyHeader(
      '/mobile/pos/shift/opened_shift/$userId',
      companyId,
    );

    return jsonDecode(responseStr);
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

  Future<void> recordSaleReversalActivity(Sale reversedSale, MobilePosShift currentShift) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOfflineMode = prefs.getBool(AppConstants.keyIsOfflineMode) ?? false;

    if (currentShift.shiftCurrencyAmounts == null) {
      currentShift.shiftCurrencyAmounts = [];
    }

    // Find original SALE activities related to this reversed sale
    // We assume that when a sale is recorded as a shift activity, its posReference (from the sale)
    // is used for the posReference of the MobileShiftCurrencyAmount.
    final List<MobileShiftCurrencyAmount> originalSaleActivities = currentShift.shiftCurrencyAmounts!
        .where((activity) =>
            activity.amountType == 'SALE' &&
            (activity.posReference == reversedSale.posReference || activity.posReference == reversedSale.id))
        .toList();

    if (originalSaleActivities.isEmpty) {
      print('No original SALE activities found in current shift for reversed sale: ${reversedSale.posReference ?? reversedSale.id}');
      // If no matching activities are found, we can't create specific reversals.
      // Depending on requirements, a generic reversal could be added here,
      // but for now, we'll just log and return.
      return;
    }

    for (var originalActivity in originalSaleActivities) {
      final MobileShiftCurrencyAmount reversalActivity = MobileShiftCurrencyAmount(
        id:null,
        active: true,
        amount: -originalActivity.amount, // Negative amount to reverse the original activity
        currency: originalActivity.currency,
        amountType: originalActivity.amountType, // Keep the same amountType ('SALE')
        notes: 'Reversal of Sale: ${reversedSale.posReference ?? reversedSale.id} - ${originalActivity.notes ?? ''}',
        timeCreated: DateFormat(AppConstants.APP_DATE_TIME_FMT).format(DateTime.now()),
        shiftReference: currentShift.shiftReference,
        isCash: originalActivity.isCash, // Keep the same cash status
        ref: 'REV_${originalActivity.ref ?? originalActivity.posReference}_${DateTime.now().millisecondsSinceEpoch}',
        posReference: 'REV_POS_${originalActivity.posReference ?? originalActivity.ref}_${DateTime.now().millisecondsSinceEpoch}',
        paymentType: originalActivity.paymentType, // Keep the same payment type
      );
      currentShift.shiftCurrencyAmounts!.add(reversalActivity);
    }

    // Persist the updated shift
    if (isOfflineMode) {
      await prefs.setString(AppConstants.keyCurrentOpenShift, currentShift.toJson());
      print('Shift updated locally with sale reversal activity.');
    } else {
      try {
        final updatedShift = await updateShift(currentShift);
        await prefs.setString(AppConstants.keyCurrentOpenShift, updatedShift.toJson());
        print('Shift updated on server and locally with sale reversal activity.');
      } catch (e) {
        print('Failed to update shift on server with sale reversal activity: $e');
        // If online update fails, save locally as a fallback to ensure consistency for the user
        await prefs.setString(AppConstants.keyCurrentOpenShift, currentShift.toJson());
        print('Shift updated locally as a fallback.');
      }
    }
  }
}
