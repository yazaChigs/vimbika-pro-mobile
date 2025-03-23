import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/services/app_exceptions.dart';

class AppHelper {

  static  void handleError(error) {
    hideLoading();
    if (error is BadRequestException) {
      var message = error.message;
      showErroDialog(description: message);
    } else if (error is UnAuthorizedException) {

      
    }
    else if (error is FetchDataException) {
      var message = error.message;
      showErroDialog(description: message);
    } else if (error is ApiNotRespondingException) {
      // showErroDialog(
      //     description: 'Oops! It took longer to respond.');
    }
  }

  // showLoading([String? message]) {
  //   showLoading(message);
  // }

  // hideLoading() {
  //   hideLoading();
  // }
  //show error dialog
  static void showErroDialog({String title = 'Error', String? description = 'Something went wrong'}) {
    Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Get.textTheme.headlineMedium,
              ),
              Text(
                description ?? '',
                style: Get.textTheme.headlineSmall,
              ),
              ElevatedButton(
                onPressed: () {
                  if (Get.isDialogOpen!) Get.back();
                },
                child: Text('Okay'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //show toast
  //show snack bar
  //show loading
  static void showLoading([String? message]) {
    Get.dialog(
      Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              Text(message ?? 'Loading...'),
            ],
          ),
        ),
      ),
    );
  }

  //hide loading
  static void hideLoading() {
    if (Get.isDialogOpen!) Get.back();
  }
}