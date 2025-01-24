import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/onboarding/controller/onboarding_controller.dart';
import 'package:vimbika_pos_app/src/features/onboarding/model/onboarding_model.dart';

class OnboardingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final OnboardingController onBoardController = Get.put(OnboardingController());
    List<OnboardingPageModel> pages = onBoardController.getPages();
    final PageController pageController = PageController(initialPage: 0);

    return Scaffold(
      body: Obx(() {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          color: pages[onBoardController.currentPage.value].bgColor,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      onBoardController.currentPage.value = index;
                    },
                    itemBuilder: (context, index) {
                      final item = pages[index];
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Image.asset(
                                item.image,
                                height: 300, // You can adjust this height
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                item.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: item.textColor,
                                ),
                              ),
                            ),
                            Container(
                              constraints: BoxConstraints(maxWidth: 280),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 8.0),
                              child: Text(
                                item.description,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                  color: item.textColor,
                                ),
                              ),
                            ),
                            // Current page indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: pages
                                  .map((item) => AnimatedContainer(
                                duration:
                                const Duration(milliseconds: 250),
                                width:
                                onBoardController.currentPage.value ==
                                    pages.indexOf(item)
                                    ? 20
                                    : 4,
                                height: 4,
                                margin: const EdgeInsets.all(2.0),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                    BorderRadius.circular(10.0)),
                              ))
                                  .toList(),
                            ),
                            SizedBox(height: 20), // Add some spacing before buttons
                            // Bottom buttons
                            SizedBox(
                              height: 60, // Adjust height to fit better
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      // Handle Skipping onboarding page
                                      Get.toNamed(AppRoutes.LOGIN);
                                    },
                                    child: const Text(
                                      "Skip",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      if (onBoardController.currentPage.value ==
                                          pages.length - 1) {
                                        // This is the last page
                                        Get.toNamed(AppRoutes.LOGIN);
                                      } else {
                                        pageController.animateToPage(
                                          onBoardController.currentPage.value +
                                              1,
                                          curve: Curves.easeInOutCubic,
                                          duration:
                                          const Duration(milliseconds: 250),
                                        );
                                      }
                                    },
                                    child: Text(
                                      onBoardController.currentPage.value ==
                                          pages.length - 1
                                          ? "Finish"
                                          : "Next",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
