import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:vimbika_pos_app/src/constants/sizes.dart';
import 'package:vimbika_pos_app/src/features/authentication/controller/offline_data_controller.dart';
import 'package:vimbika_pos_app/src/rear/sunmi_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';
import 'package:vimbika_pos_app/src/shared/models/company_model.dart';

import '../../../constants/app_constants.dart';

class ChooseBranchScreen extends StatelessWidget {

  const ChooseBranchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final OfflineDataController offlineDataController = Get.put(OfflineDataController());
    final DisplayManager display = DisplayManager();
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(tDefaultSize),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Select Branch",
                style: Theme
                    .of(context)
                    .textTheme
                    .headlineMedium,
              ),
              const SizedBox(height: 20),
          Container(
            width: double.infinity, // Make the container take full width
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: DropdownButtonHideUnderline(
              child: Obx(() {
                return DropdownButton<CompanyModel>(
                  hint: const Text("Select Company"),
                  value: offlineDataController.isCompanySelected.isTrue
                      ? offlineDataController.selectedCompany.value
                      : null,
                  icon: const Icon(Icons.food_bank_outlined),
                  elevation: 16,
                  style: const TextStyle(color: Colors.deepPurple),
                  onChanged: (CompanyModel? newValue) async {
                    // Update your state here
                    offlineDataController.isCompanySelected.value = true;
                    offlineDataController.selectedCompany.value = newValue;
                    offlineDataController.onCompanyChange(newValue!);
                    var displays = await display.getDisplays();
                    if(displays!.length>1) {
                          final cartData = {
                            'companyName': newValue!.name!,
                            'imageUrl':
                                '${AppConstants.VIMBIKA_BACKEND_URL}/company/logo/${offlineDataController.selectedCompany.value!.id}',
                            'total': 00.00,
                            'items': [],
                          };
                          await display.transferDataToPresentation(cartData);
                        }
                  },
                  items: offlineDataController.companyList.map<DropdownMenuItem<
                      CompanyModel>>((CompanyModel value) {
                    return DropdownMenuItem<CompanyModel>(
                      value: value,
                      child: Text(value.name!),
                    );
                  }).toList(),
                  isExpanded: true, // Make the dropdown take full width
                );
              }),
            ),

          ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity, // Make the container take full width
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: DropdownButtonHideUnderline(
                  child: Obx(() {
                    return DropdownButton<BranchModel>(
                      hint: const Text("Select Branch"),
                      value: offlineDataController.isBranchSelected.isTrue
                          ? offlineDataController.selectedBranch.value
                          : null,
                      icon: const Icon(Icons.location_on),
                      elevation: 16,
                      style: const TextStyle(color: Colors.deepPurple),
                      onChanged: (BranchModel? newValue) {
                        // Update your state here
                        offlineDataController.isBranchSelected.value = true;
                        offlineDataController.selectedBranch.value = newValue;
                        offlineDataController.onChangeBranch(newValue?.id);
                      },
                      items: offlineDataController.branchList.map<DropdownMenuItem<
                          BranchModel>>((BranchModel value) {
                        return DropdownMenuItem<BranchModel>(
                          value: value,
                          child: Text(value.name!),
                        );
                      }).toList(),
                      isExpanded: true, // Make the dropdown take full width
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    offlineDataController.navigateToPin();

                  },
                  child: Text("CONTINUE"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
