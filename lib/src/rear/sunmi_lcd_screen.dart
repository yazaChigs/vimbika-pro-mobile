import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:presentation_displays/secondary_display.dart';
import 'package:vimbika_pos_app/src/features/sale/model/cart_item_model.dart';
import 'package:vimbika_pos_app/src/rear/sunmi_controller.dart';

import '../constants/app_constants.dart';
import '../constants/app_constants.dart';
import '../features/sale/controller/cart_controller.dart';
import '../shared/models/company_model.dart';
import '../shared/models/currency_model.dart';
import '../widgets/nav_drawer_widget.dart';

class SunmiLcdScreen extends GetView {

  var scaffoldKey = GlobalKey<ScaffoldState>();
  final SunmiController controller = Get.find<SunmiController>();

  @override
  Widget build(BuildContext context) {
    GetStorage box = GetStorage();
    var selectedCompany = box.read(AppConstants.ACTIVE_COMPANY) ?? null;
    String? imageUrl = null;
    if (selectedCompany != null) {
      CompanyModel company = CompanyModel.fromMap(selectedCompany);
      imageUrl =
      "${AppConstants.VIMBIKA_BACKEND_URL}/company/logo/${company.id}";
    }
    // The SecondaryDisplay widget is what listens for data transfers
    return SecondaryDisplay(
      callback: (dynamic data) {
        // Handle incoming data from the main screen here.
        if (data is Map) {
          Set<String> items = data['items'] != null ? Set<String>.from(
              data["items"].map((x) => x.toString())) : {};
          controller.items.value = items
              .toList()
              .obs;
          controller.companyName.value = data['companyName'] as String;
          controller.imageUrl.value = data['imageUrl'] as String;
          controller.totalCostInSelectedCurrency.value =
          data['total'] as double;
          controller.change.value = data['change'] as double;
          controller.numberOfItems.value = data['numberOfItems'] as double;
          controller.currency.value = data["currency"];
          controller.items.refresh();
          if (controller.items.length == 0) {
            controller.totalCostInSelectedCurrency.value = 0.00;
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(controller.companyName.value),
                Obx(() {
                  return Text(
                    'Currency: ${Get
                        .find<SunmiController>()
                        .currency}',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  );
                }),
              ],
            );
          }),
        ),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() {
              return Column(
                children: [
                  CachedNetworkImage(
                    imageUrl: controller.imageUrl.value,
                    width: 350,
                    height: 350,
                    placeholder: (context, url) =>
                        CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        Image.asset(
                          'assets/images/dummy/dummy.png',
                          // Path to your error image
                          fit: BoxFit.cover,
                        ),
                  ),
                  /* Container(
                    child:
                    CircleAvatar(
                      radius: 100,
                      backgroundImage: imageUrl != null
                          ? NetworkImage(controller.imageUrl.value)
                          : AssetImage("assets/images/logo/logo.png"),
                      // Use the backend image URL
                      onBackgroundImageError: (error, stackTrace) {
                        // Fallback if image fails to load
                        print("error nav image");
                        AssetImage("assets/images/logo/logo.png");
                      },
                    ),
                  ),*/
                  Expanded(
                    child: Center(
                      child:
                      Text("Thank You!!!!",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Image.asset(
                      'assets/images/logo/logo.png',
                      width: 300,
                      height: 400,
                    ),
                  ),
                ],
              );
            }),
            Divider(
              color: Colors.black,
              thickness: 2,
              height: 200,
            ),
            Expanded(
              child: Container(
                width: 200,
                height: 500,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.indigo, width: 4.0),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() {
                      return Text('Your Items: ${controller.numberOfItems
                          .value}',
                          style: TextStyle(fontSize: 20));
                    }),
                    Container(
                      height: 400,
                      child:
                      Obx(
                              () {
                            if (controller.items.isEmpty) {
                              return Center(
                                  child: Container(
                                    width: double.infinity,
                                    child: Column(
                                      children: [
                                        SizedBox(height: 30),
                                        Text('Your cart is empty'),
                                        SizedBox(height: 10),
                                        IconButton(
                                          icon: Icon(
                                            Icons.warning_amber,
                                            size: 50,
                                          ),
                                          color: Colors.grey,
                                          onPressed: () {},
                                        ),
                                      ],
                                    ),
                                  ));
                            }
                            return ListView.builder(
                                shrinkWrap: true,
                                itemCount: controller.items.length,
                                itemBuilder: (context, index) {
                                  final item = controller.items[index];
                                  return ListTile(
                                    tileColor: Colors.lightBlueAccent[100],
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 0.0, horizontal: 16.0),
                                    dense: true,
                                    title: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.indigo,
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                          color: Colors.grey, width: 1.0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  );
                                });
                          }),
                    ),
                    Obx(
                          () =>
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              Text(
                                'Total: \$${Get
                                    .find<SunmiController>()
                                    .totalCostInSelectedCurrency
                                    .toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo),
                              ),
                              Text(
                                'Change: \$${Get
                                    .find<SunmiController>()
                                    .change
                                    .toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent),
                              ),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}