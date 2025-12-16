import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';

class SaleReference {
  String reference;
  bool isSynced;
  String? saleStatus;
  
  SaleReference({
    required this.reference,
    required this.isSynced,
    this.saleStatus,
  });
}

class ShiftSalesCount {
  int synced;
  int unsynced;
  List<SaleReference> syncedReferences;
  List<SaleReference> unsyncedReferences;
  
  ShiftSalesCount({
    this.synced = 0,
    this.unsynced = 0,
    List<SaleReference>? syncedReferences,
    List<SaleReference>? unsyncedReferences,
  })  : syncedReferences = syncedReferences ?? [],
        unsyncedReferences = unsyncedReferences ?? [];
  
  int get total => synced + unsynced;
  
  List<SaleReference> get allReferences => [...syncedReferences, ...unsyncedReferences];
}

class ShiftsHistoryController extends GetxController {
  late GetStorage box;
  late UserModel user;
  late LocalStorageService _localStorageService;
  
  RxList<ShiftModel> allShifts = <ShiftModel>[].obs;
  RxMap<String, ShiftSalesCount> shiftSalesCounts = <String, ShiftSalesCount>{}.obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxBool isInternetAccess = false.obs;

  @override
  void onInit() {
    super.onInit();
    box = GetStorage();
    _localStorageService = LocalStorageService();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    if (model.isNotEmpty) {
      user = UserModel.fromMap(Map<String, dynamic>.from(model));
    } else {
      user = UserModel(id: null, firstName: "", lastName: "", userName: "");
    }
    // Load shifts from local storage only
    // Synced shifts are already stored locally via SyncService.syncOfflineShifts()
    // Similar to how sales are handled in receipts screen
    _loadShiftsFromLocalStorage();
    _loadSalesCounts();
  }

  void _loadShiftsFromLocalStorage() {
    try {
      List<ShiftModel> localShifts = _localStorageService.getOfflineList<ShiftModel>(
        AppConstants.SHIFT_LIST,
        (map) => ShiftModel.fromMap(map),
        box,
      );

      // Filter for current user
      if (user.id != null && user.id!.isNotEmpty) {
        allShifts.value = localShifts
            .where((shift) => shift.userId == user.id)
            .toList();
      } else {
        allShifts.value = localShifts;
      }

      // Sort by opening time (newest first)
      allShifts.value.sort((a, b) {
        if (a.openingTime == null && b.openingTime == null) return 0;
        if (a.openingTime == null) return 1;
        if (b.openingTime == null) return -1;
        return b.openingTime!.compareTo(a.openingTime!);
      });

      if (allShifts.isEmpty) {
        errorMessage.value = "No shifts found in local storage";
      } else {
        errorMessage.value = '';
      }
      // Reload sales counts after loading shifts
      _loadSalesCounts();
    } catch (e) {
      errorMessage.value = "Error loading shifts: ${e.toString()}";
      print("Error loading shifts from local storage: $e");
    }
  }

  Future<void> refreshShifts() async {
    // Reload from local storage (which should have all shifts including synced ones)
    // Synced shifts are persisted via SyncService.syncOfflineShifts()
    _loadShiftsFromLocalStorage();
    _loadSalesCounts(); // Reload sales counts after refresh
  }

  void _loadSalesCounts() {
    try {
      // Load all sales from local storage
      List<SaleInfoModel> allSales = _localStorageService.getOfflineList<SaleInfoModel>(
        AppConstants.SALE_LIST,
        (map) => SaleInfoModel.fromMap(map),
        box,
      );

      // Reset counts
      Map<String, ShiftSalesCount> counts = {};

      // Count sales for each shift and collect references
      for (SaleInfoModel saleInfo in allSales) {
        if (saleInfo.sale?.shiftReference != null) {
          String shiftRef = saleInfo.sale!.shiftReference!;
          
          // Initialize count for this shift if not exists
          if (!counts.containsKey(shiftRef)) {
            counts[shiftRef] = ShiftSalesCount(
              syncedReferences: [],
              unsyncedReferences: [],
            );
          }

          // Only count COMPLETE or PENDING sales (not REVERSED)
          if (saleInfo.sale?.saleStatus == "COMPLETE" || saleInfo.sale?.saleStatus == "PENDING") {
            String? reference;
            // For synced sales, use server reference (posReference)
            // For unsynced sales, use local reference (referenceNumber)
            if (saleInfo.syncStatus == true) {
              reference = saleInfo.sale?.posReference; // Server reference
            } else {
              reference = saleInfo.sale?.referenceNumber ?? saleInfo.sale?.posReference; // Local reference, fallback to posReference if available
            }
            
            if (reference != null && reference.isNotEmpty) {
              SaleReference saleRef = SaleReference(
                reference: reference,
                isSynced: saleInfo.syncStatus == true,
                saleStatus: saleInfo.sale?.saleStatus,
              );
              
              if (saleInfo.syncStatus == true) {
                counts[shiftRef]!.synced++;
                counts[shiftRef]!.syncedReferences.add(saleRef);
              } else {
                counts[shiftRef]!.unsynced++;
                counts[shiftRef]!.unsyncedReferences.add(saleRef);
              }
            }
          }
        }
      }

      shiftSalesCounts.value = counts;
      print("Loaded sales counts for ${counts.length} shifts");
    } catch (e) {
      print("Error loading sales counts: $e");
      shiftSalesCounts.value = {};
    }
  }

  ShiftSalesCount getSalesCountForShift(String? shiftReference) {
    if (shiftReference == null || shiftReference.isEmpty) {
      return ShiftSalesCount();
    }
    return shiftSalesCounts[shiftReference] ?? ShiftSalesCount();
  }
}

