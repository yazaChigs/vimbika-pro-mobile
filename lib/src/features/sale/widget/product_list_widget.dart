import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_constants.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/sale_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';

class ProductListWidge extends StatelessWidget {
  final SaleController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    print("--print1--");
    print(controller.allProducts.length);
    Widget listViewBody(ProductFullInfoModel item, int index) {
      return GestureDetector(
        onTap: () {
          // Navigator.push(context, MaterialPageRoute(builder: (_) {
          //   return ProductDetailScreen(item.name,item.image);
          // },),);
        },
        child: Card(
          child: Row(
            children: [
              const SizedBox(width: 20),
              //Image.asset(item.item!.images![0], fit: BoxFit.contain, width: 60),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.item!.fullName ?? 'No name available', style: AppConstants.kItemNameStyle),
                  // Text(item.color, style: AppConstants.kItemColorStyle),
                 // Text(item.item!.fullName ?? 'No name available', style: AppConstants.kItemPriceStyle),
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  countButton(index, controller.increase),
                  Obx(() => Text(controller.allProducts[index].count.toString())),
                  countButton(index, controller.decrease, icon: Icons.remove)
                ],
              )
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: controller.allProducts.length,
      itemBuilder: (_, index) {
        print("--print--");
        print(controller.allProducts.length);
        ProductFullInfoModel item = controller.allProducts[index];
        if (controller.isItemListScreen) {
          return listViewBody(item, index);
        } else if (controller.isCartScreen && item.count > 0) {
          return listViewBody(item, index);
        } else {
          return Container();
        }
      },
    );
  }
  Widget countButton(int index, void Function(int index) counter,
      {IconData icon = Icons.add}) {
    return RawMaterialButton(
      onPressed: () {
        counter(index);
      },
      elevation: 2.0,
      fillColor: Colors.white,
      child: Icon(
        icon,
        size: 15,
      ),
      shape: const CircleBorder(),
    );
  }
}
