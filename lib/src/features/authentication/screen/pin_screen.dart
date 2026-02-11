import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            children: [
              const Center(
                child: Text(
                  'Enter Your Pin',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.black,
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
                                  borderRadius: BorderRadius.circular(6.0),
                                  color: index <
                                          pinController.enteredPin.value.length
                                      ? pinController.isPinVisible.value
                                          ? Colors.black
                                          : CupertinoColors.activeBlue
                                      : CupertinoColors.activeBlue
                                          .withOpacity(0.1),
                                ),
                                child: pinController.isPinVisible.value &&
                                        index <
                                            pinController
                                                .enteredPin.value.length
                                    ? Center(
                                        child: Text(
                                          pinController.enteredPin.value[index],
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
              SizedBox(height: pinController.isPinVisible.value ? 50.0 : 8.0),
              /// digits
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      3,
                      (index) => numButton(1 + 3 * i + index),
                    ).toList(),
                  ),
                ),
              /// 0 digit with back remove
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const TextButton(onPressed: null, child: SizedBox()),
                    numButton(0),
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
                      child: const Icon(
                        Icons.backspace,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              /// reset button
              TextButton(
                onPressed: () {
                  pinController.enteredPin.value = "";
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget numButton(int number) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextButton(
        onPressed: () {
          pinController.onNumberEntered(number);
        },
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}