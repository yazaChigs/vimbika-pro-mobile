import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/image_strings.dart';
import 'package:vimbika_pos_app/src/features/onboarding/model/onboarding_model.dart';

class OnboardingController extends GetxController {

  RxInt currentPage = 0.obs;
  // final PageController pageController = PageController(initialPage: 0);

  void nextOnboardDisplay()  {
     currentPage ++;
  }

  List<OnboardingPageModel> getPages(){
    List<OnboardingPageModel> pages = [
      OnboardingPageModel(
        title: 'Sell Anywhere, Anytime',
        description:
        'Empower your business with seamless offline transactions. Continue selling even when you are off the grid.',
        image: tOnBoardingImage1,
        bgColor: Colors.indigo,
      ),
      OnboardingPageModel(
        title: 'Manage Shifts and Cash with Ease',
        description: 'Keep track of user shifts and handle cash flow effortlessly. Simplify your operations with our intuitive tools.',
        image: tOnBoardingImage2,
        bgColor: const Color(0xff1eb090),
      ),
    ];
    return pages;
  }
}