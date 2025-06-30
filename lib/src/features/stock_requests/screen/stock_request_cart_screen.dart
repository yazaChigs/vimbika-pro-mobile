import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/sale/widget/custom_dropdown_widget.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/controller/stock_request_controller.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/model/requisition_model.dart';
import 'package:vimbika_pos_app/src/shared/controller/inactivity_controller.dart';
import 'package:vimbika_pos_app/src/shared/models/base_name_model.dart';
import 'package:vimbika_pos_app/src/shared/models/branch_model.dart';

class StockRequestCartScreen extends StatelessWidget {

  final InactivityController inactivityController = Get.find();
  final StockRequestController stockRequestController = Get.find();


  @override
  Widget build(BuildContext context) {
    RequisitionModel val = stockRequestController.selectedReq.value!;
    String title = val.id != null ? 'EDITING REQUEST (' + val.referenceNumber! + ')':'SELECT ITEMS';
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: inactivityController.resetInactivityTimer,
      onPanDown: (_) => inactivityController.resetInactivityTimer(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Obx(() {
          if (stockRequestController.cartItems.isEmpty) {
            return Center(child: Text('NO ITEMS SELECTED!'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: stockRequestController.cartItems.length,
                  itemBuilder: (context, index) {
                    final cartItem = stockRequestController.cartItems[index];
                    String imageUrl = cartItem.product.item!.image != null
                        ? "${AppConstants
                        .VIMBIKA_BACKEND_URL}/inventory/image?name=${cartItem
                        .product.item!.image}"
                        : "https://via.placeholder.com/150";

                    return ListTile(
                      leading: CachedNetworkImage(
                        imageUrl: imageUrl,
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/images/dummy/dummy.png', // Path to your error image
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(cartItem.product.item!.name ?? ''),
                      subtitle: Text('${cartItem.product.item!
                          .sellingPrice} x ${cartItem.quantity}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove),
                            onPressed: () =>
                                stockRequestController.decrementQuantity(cartItem),
                          ),
                          Text('${cartItem.quantity}'),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () =>
                                stockRequestController.incrementQuantity(cartItem),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () =>
                                stockRequestController.removeFromCart(cartItem),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Text(
                    //   'Total : ${cartController.selectedCurrency.value?.symbol ?? ''} ${cartController.totalCostInSelectedCurrency.toStringAsFixed(2)}',
                    //   style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    // ),
                    // Container(
                    //   width: double.infinity, // Make the container take full width
                    //   padding: const EdgeInsets.symmetric(horizontal: 12),
                    //   decoration: BoxDecoration(
                    //     border: Border.all(color: Colors.grey),
                    //     borderRadius: BorderRadius.circular(5),
                    //   ),
                    //   child: DropdownButtonHideUnderline(
                    //     child: Obx(() {
                    //       return DropdownButton<BranchModel>(
                    //         hint: const Text("Select Branch"),
                    //         value: stockRequestController.isBranchSelected.isTrue
                    //             ? stockRequestController.selectedBranch.value
                    //             : null,
                    //         icon: const Icon(Icons.location_on),
                    //         elevation: 16,
                    //         style: const TextStyle(color: Colors.deepPurple),
                    //         onChanged: (BranchModel? newValue) {
                    //           // Update your state here
                    //           stockRequestController.isBranchSelected.value = true;
                    //           stockRequestController.selectedBranch.value = newValue;
                    //           //stockRequestController.onChangeBranch(newValue?.id);
                    //         },
                    //         items: stockRequestController.branchList.map<DropdownMenuItem<
                    //             BranchModel>>((BranchModel value) {
                    //           return DropdownMenuItem<BranchModel>(
                    //             value: value,
                    //             child: Text(value.name!),
                    //           );
                    //         }).toList(),
                    //         isExpanded: true, // Make the dropdown take full width
                    //       );
                    //     }),
                    //   ),
                    // ),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Obx(() {
                        return CustomDropdownWidget<BranchModel>(
                          items: stockRequestController.branchList,
                          selectedItem: stockRequestController.selectedBranch.value,
                          hint: "Select Branch",
                          isSelected: stockRequestController.isBranchSelected,
                          selectedValue: stockRequestController.selectedBranch,
                          icon: Icons.location_city,
                          onChanged: (BranchModel? newValue) {
                            stockRequestController.selectedBranch.value = newValue;
                          },
                          validator: (value) {
                            if (stockRequestController.isBranchSelected.isFalse) {
                              return 'Please Select Branch';
                            }
                            return null;
                          },
                          itemBuilder: (BranchModel value) => Text(value.name!),
                        );
                      }),
                    ),


                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        stockRequestController.saveRequest();
                      },
                      child: Text('SAVE'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

}
