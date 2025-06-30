import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/controller/stock_request_controller.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/transfer_history_model.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/transfer_item_model.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';

class ReceiveStockController extends GetxController {
  Rx<TransferHistoryModel> transferHistory = TransferHistoryModel(transferItems: [], fromBranch: null, toBranch: null).obs;
  RxBool allSelected = false.obs;
  RxList<String?> errorMessages = <String?>[].obs;
  List<TextEditingController> textControllers = [];
  final ConnectivityService _connectivityService = ConnectivityService();
  late GetStorage box;
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  final LocalStorageService _localStorageService = LocalStorageService();
  @override
  Future<void> onInit() async {
    super.onInit();
    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
  }

  void setTransferHistory(TransferHistoryModel history) {
    transferHistory.value = history;
    errorMessages.value = List.filled(history.transferItems?.length ?? 0, null);
    textControllers = List.generate(
      history.transferItems?.length ?? 0,
          (index) => TextEditingController(text: history.transferItems![index].allocated?.toString() ?? ""),
    );
    for(TransferItemModel item in transferHistory.value.transferItems!){
        item.item!.image="";
        item.item!.productImages = [];
    }
  }

  void validateAndUpdateQuantity(int index, String value) {
    if (value.isEmpty) {
      errorMessages[index] = "Value cannot be empty.";
    } else {
      double? allocated = double.tryParse(value);
      if (allocated == null || allocated < 0) {
        errorMessages[index] = "Invalid value. Must be 0 or more.";
      } else {
        errorMessages[index] = null;
        transferHistory.value.transferItems![index].allocated = allocated;
      }
    }

    errorMessages.refresh();
    transferHistory.refresh();
  }

  void toggleReceiveAll(bool value) {
    allSelected.value = value;
    for (var i = 0; i < transferHistory.value.transferItems!.length; i++) {
      transferHistory.value.transferItems![i].allocated = value ? transferHistory.value.transferItems![i].quantity : 0;
      textControllers[i].text = transferHistory.value.transferItems![i].allocated.toString();
      errorMessages[i] = null;
    }
    errorMessages.refresh();
    transferHistory.refresh();
  }

  void receiveStock() async{
    for (int i = 0; i < transferHistory.value.transferItems!.length; i++) {
      if (transferHistory.value.transferItems![i].allocated == null || transferHistory.value.transferItems![i].allocated! < 0) {
        errorMessages[i] = "Invalid value. Must be 0 or more.";
        errorMessages.refresh();
        return;
      }
    }

    // Get.snackbar("Success", "Stock received successfully!");
    bool internetStat =  await _connectivityService.checkServerConnection();
    if (internetStat) {
      TransferHistoryModel? historyModel =  await SyncService.saveTransfer(transferHistory.value, user, box);
      if(historyModel != null){
        log(historyModel.toJson());
        StockRequestController src = Get.find();
        List<TransferHistoryModel> list = src.allTransferHistory;
        List<TransferHistoryModel> items = _localStorageService.replaceTransfer(historyModel, list);
        src.allTransferHistory.value = items;
        src.allTransferHistory.refresh();
        // List<Map<String, dynamic>> itemsListMap = items.map((item) =>
        //     item.toMap()).toList();
        // box.write(AppConstants.TRANSFER_HISTORY_LIST, itemsListMap);
         Get.offNamed(AppConstants.TRANSFER_HISTORY_LIST);
        Get.snackbar("Success", "Stock received successfully!");
      }else{
        Get.snackbar("Error", "Failed to receive stock");
      }
    }else{
      Get.snackbar("Error", "Failed to receive stock, check your internet connection.");
    }
  }
  void showConfirmDialogToReceiveStock() {
    Get.defaultDialog(
      title: "Confirmation",
      middleText: "Are you sure you want to proceed?",
      textCancel: "No",
      textConfirm: "Yes",
      onCancel: () {
        Get.back(); // Close the dialog
      },
      onConfirm: () {
        receiveStock();

      },
    );
  }
}
