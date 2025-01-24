import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/sale_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/model/cart_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_infor_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_item_model.dart';
import 'package:vimbika_pos_app/src/features/sale/model/sale_model.dart';
import 'package:vimbika_pos_app/src/features/ticket/model/ticket_item_response_model.dart';
import 'package:vimbika_pos_app/src/features/ticket/model/ticket_model.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';
import 'package:vimbika_pos_app/src/services/base_http_client.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/services/sync_service.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/company_model.dart';
import 'package:vimbika_pos_app/src/shared/models/currency_model.dart';
import 'package:vimbika_pos_app/src/utils/app_helper.dart';

import '../../../constants/app_constants.dart';

class StockRequestController extends GetxController {
  final SaleController saleController = Get.find();
  final CartController cartController = Get.find();
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  final ConnectivityService _connectivityService = ConnectivityService();
  Rx<String> searchQuery = "".obs;
  var isInternetAccess = false.obs;
  late GetStorage box;
  final LocalStorageService _localStorageService = LocalStorageService();
  Rx<BaseNameModel?> branch = BaseNameModel().obs;
  Rx<CompanyModel?> company = CompanyModel().obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    isInternetAccess.value =  await _connectivityService.checkServerConnection();

    var branchModel = box.read(AppConstants.SELECTED_BRANCH) ?? {};
    branch.value = BaseNameModel.fromMap(Map<String, dynamic>.from(branchModel));
    var companyModel = box.read(AppConstants.ACTIVE_COMPANY) ?? {};
    company.value = CompanyModel.fromMap(Map<String, dynamic>.from(companyModel));

  }

  @override
  void onClose() {
    super.onClose();
  }




  List<ProductFullInfoModel> getProducts(){
    List<ProductFullInfoModel> list = _localStorageService.getOfflineList<ProductFullInfoModel>(
        AppConstants.BRANCH_PRODUCTS,
            (map) => ProductFullInfoModel.fromMap(map),
        box);
    if(list != null){
      return list;
    } else{
      return [];
    }
  }


}