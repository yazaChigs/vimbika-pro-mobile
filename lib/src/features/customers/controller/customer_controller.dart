import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:meta/meta.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/authentication/model/user_model.dart';
import 'package:vimbika_pos_app/src/services/connectivity_service.dart';
import 'package:vimbika_pos_app/src/services/local_storage_service.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/customer_model.dart';

class CustomerController extends GetxController {
  late UserModel user = UserModel(firstName: "", lastName: "", userName: "");
  final ConnectivityService _connectivityService = ConnectivityService();
  RxList<CustomerModel> allCustomers = <CustomerModel>[].obs;
  RxList<CustomerModel> filteredCustomers = <CustomerModel>[].obs;
  Rx<String> searchQuery = "".obs;
  var isInternetAccess = false.obs;
  late GetStorage box;
  final LocalStorageService _localStorageService = LocalStorageService();
  final TextEditingController nameEditingController = TextEditingController();
  final TextEditingController mobileNumberEditingController = TextEditingController();
  final TextEditingController emailEditingController = TextEditingController();
  final TextEditingController descriptionEditingController = TextEditingController();
  final TextEditingController vatEditingController = TextEditingController();
  final TextEditingController tinEditingController = TextEditingController();
  final TextEditingController addressEditingController = TextEditingController();
  var name = "".obs;
  var mobilePhone = "".obs;
  var email = "".obs;
  var description = "".obs;

  var vat = "".obs;
  var tin = "".obs;
  var address = "".obs;
  GlobalKey<FormState> formKeyForm = GlobalKey<FormState>();


  @override
  Future<void> onInit() async {
    super.onInit();
    box = GetStorage();
    var model = box.read(AppConstants.USER_INFO) ?? {};
    user = UserModel.fromMap(Map<String, dynamic>.from(model));
    isInternetAccess.value =  await _connectivityService.checkServerConnection();
    List<CustomerModel> customers = loadCustomers(box);
    allCustomers.value = customers;
    filteredCustomers.value = customers;
  }
  void filterCustomers(String query) {
    print(query);
    searchQuery.value = query;
    filteredCustomers.value = allCustomers.value.where((cus) {
      final name = cus.name!.toLowerCase() ?? '';

      var mobilePhone = '';
      if(cus.mobilePhone != null){
         mobilePhone = cus.mobilePhone!.toString().toLowerCase();
      }
      final lowerQuery = query.toLowerCase();
      return name.contains(lowerQuery) || mobilePhone.contains(lowerQuery);
    }).toList();
  }
  List<CustomerModel> loadCustomers( GetStorage box) {
    List<CustomerModel> list = _localStorageService.getOfflineList<CustomerModel>(
        AppConstants.CUSTOMER_LIST,
            (map) => CustomerModel.fromMap(map),
        box);
    return list;
  }

  saveCustomerInfo(){
    GetStorage bb = GetStorage();
    var branchModel = bb.read(AppConstants.SELECTED_BRANCH) ?? {};
    int count  = allCustomers.length + 1;
    String ref = AppConstants.getDateNowRef("CUS", count);
    BaseNameModel branch = BaseNameModel.fromMap(Map<String, dynamic>.from(branchModel));
    CustomerModel customerModel = CustomerModel(id: null, customerId: ref, name: name.value, companyName: "", email: email.value, mobilePhone: mobilePhone.value, description: description.value, branch: branch, taxNumber: vat.value, street: address.value, tinNumber: tin.value);
    List<CustomerModel> customers = allCustomers.value;
    customers.add(customerModel);
    allCustomers.value = customers;
    List<Map<String, dynamic>> itemsListMap = customers.map((item) => item.toMap()).toList();
    bb.write(AppConstants.CUSTOMER_LIST, itemsListMap);
    Get.snackbar("New Customer", "Customer Saved Successfully", snackPosition: SnackPosition.BOTTOM);
    clearForm();
   // Get.back();

  }
  void showConfirmDialogToSaveCustomer() {
    Get.defaultDialog(
      title: "Confirmation",
      middleText: "Are you sure you want to proceed?",
      textCancel: "No",
      textConfirm: "Yes",
      onCancel: () {
        Get.back(); // Close the dialog
      },
      onConfirm: () {
        saveCustomerInfo();
        Navigator.of(Get.overlayContext!).pop();
       // Get.back();
      },
    );
  }

  void clearForm() {
    // Clear the text fields
    nameEditingController.clear();
    mobileNumberEditingController.clear();
    emailEditingController.clear();
    descriptionEditingController.clear();

    // Reset the form's state
    formKeyForm.currentState?.reset();
  }

}