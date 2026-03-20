import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/controller/pin_controller.dart'; // For exit(0) on Android/iOS.

class PinScreen extends GetView {
  final PinController pinController = Get.put(PinController());

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        exit(0);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  Center(
                    child: Text(
                      'Enter Your Pin',
                      style: TextStyle(
                        fontSize: 32,
                        color: context.theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  /// pin code area
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double maxWidth = constraints.maxWidth;
                          double boxWidth = (maxWidth - 5 * 12) / 6;
                          boxWidth = boxWidth > 40 ? 40 : boxWidth;

                          return Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6.0,
                            runSpacing: 6.0,
                            children: List.generate(
                              6,
                              (index) {
                                return Obx(() {
                                  return Container(
                                    width: pinController.isPinVisible.value
                                        ? boxWidth
                                        : 16,
                                    height: pinController.isPinVisible.value
                                        ? boxWidth
                                        : 16,
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(6.0),
                                      color: index <
                                              pinController
                                                  .enteredPin.value.length
                                          ? pinController.isPinVisible.value
                                              ? Colors.black
                                              : Get.theme.colorScheme.primary
                                          : CupertinoColors.activeBlue
                                              .withOpacity(0.1),
                                    ),
                                    child: pinController.isPinVisible.value &&
                                            index <
                                                pinController
                                                    .enteredPin.value.length
                                        ? Center(
                                            child: Text(
                                              pinController
                                                  .enteredPin.value[index],
                                              style: const TextStyle(
                                                fontSize: 17,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          )
                                        : null,
                                  );
                                });
                              },
                            ),
                          );
                        },
                      ),
                      Opacity(
                        opacity: 0.0,
                        child: TextField(
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            pinController.enteredPin.value = value;
                            if (value.length >= 4) {
                              pinController.validatePin();
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  /// visibility toggle button
                  Obx(() {
                    return IconButton(
                      onPressed: () {
                        pinController.isPinVisible.value =
                            !pinController.isPinVisible.value;
                      },
                      icon: Icon(
                        pinController.isPinVisible.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    );
                  }),
                  SizedBox(
                      height: pinController.isPinVisible.value ? 50.0 : 8.0),
                  /// digits
                  for (var i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => numButton(1 + 3 * i + index),
                        ).toList(),
                      ),
                    ),
                  /// 0 digit with back remove
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const TextButton(
                              onPressed: null, child: SizedBox(width: 50,)),
                          numButton(0),
                          SizedBox(width: 20,),
                          TextButton(
                            onPressed: () {
                              if (pinController.enteredPin.value.isNotEmpty) {
                                pinController.enteredPin.value = pinController
                                    .enteredPin.value
                                    .substring(
                                        0,
                                        pinController.enteredPin.value.length -
                                            1);
                              }
                            },
                            child: Icon(
                              Icons.backspace,
                              color: context.theme.colorScheme.primary,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  /// reset button
                  TextButton(
                    onPressed: () {
                      pinController.enteredPin.value = "";
                    },
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 20,
                        color: context.theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: InkWell(
                onTap: () {
                  Get.dialog(
                    AlertDialog(
                      title: const Text('Confirm'),
                      content: const Text(
                          'Are you sure you want to clear all app data? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            GetStorage().erase();
                            Get.offAllNamed(AppRoutes.LOGIN);
                          },
                          child: const Text('Confirm'),
                        ),
                      ],
                    ),
                  );
                },
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: const SizedBox(
                  width: 70,
                  height: 70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget numButton(int number) {
    return InkWell(
      onTap: () {
        pinController.onNumberEntered(number);
      },
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.7),
              spreadRadius: 3,
              blurRadius: 3,
              offset: const Offset(0, 3,),
            ),
          ],
        ),
        child: Padding(
          padding:
              const EdgeInsets.only(top: 16, right: 16, left: 16, bottom: 16),
          child: TextButton(
            onPressed: () {
              pinController.onNumberEntered(number);
            },
            child: Text(
              number.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: 'Roboto',
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
