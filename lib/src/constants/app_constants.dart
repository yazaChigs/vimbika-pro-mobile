import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AppConstants {
  static const CACHED_ACCESS_TOKEN = "CACHED_ACCESS_TOKEN";
  // static const VIMBIKA_BACKEND_URL = "https://business.vimbika.co.zw/vimbika-zw/api";
  // static const VIMBIKA_BACKEND_URL = "https://business.vimbika.africa/vimbika-africa/api";
  // static const VIMBIKA_BACKEND_URL = "https://demo.vimbika.africa/uat-vimbika/api";
  // static const VIMBIKA_BACKEND_URL = "https://mashwede.vimbika.africa/mashwede/api";
  //     static const VIMBIKA_BACKEND_URL = "http://192.168.1.99:8080/vimbika-pro/api";
          static const VIMBIKA_BACKEND_URL = "http://192.168.1.146:8080/vimbika-pro/api";
  // static const VIMBIKA_BACKEND_URL = "http://172.20.10.12:8080/vimbika-pro/api";
  static const USER_INFO = "USER_INFO";
  static const ACTIVE_COMPANY = "ACTIVE_COMPANY";
  static const IS_AUTHENTICATED = "IS_AUTHENTICATED";
  static const IS_SUBSCRIBED = "IS_SUBSCRIBED";
  static const RENEWAL_DATE = "RENEWAL_DATE";
  static const SUBSCRIPTIONS = "SUBSCRIPTIONS";
  static const SELECTED_BRANCH = "SELECTED_BRANCH";
  static const BRANCH_PRODUCTS = "BRANCH_PRODUCTS";

  static const BRAND_LIST = "BRAND_LIST";
  static const CATEGORY_LIST = "CATEGORY_LIST";
  static const SHIFT_SETTING = "SHIFT_SETTING";
  static const COMPANY_SETTINGS = "COMPANY_SETTINGS";

  static const BRANCH_LIST = "BRANCH_LIST";
  static const COMPANY_LIST = "COMPANY_LIST";
  static const CURRENCY_LIST = "CURRENCY_LIST";
  static const BANK_LIST = "BANK_LIST";
  static const PAYMENT_TYPE_LIST = "PAYMENT_TYPE_LIST";
  static const SALE_LIST = "SALE_LIST";
  static const PAYMENT_RECEIVED_LIST = "PAYMENT_RECEIVED_LIST";
  static const SHIFT_LIST = "SHIFT_LIST";
  static const USER_LIST = "USER_LIST";
  static const AVAILABLE_PRINTERS = "AVAILABLE_PRINTERS";
  static const CUSTOMER_LIST = "CUSTOMER_LIST";
  static const TICKET_LIST = "TICKET_LIST";
  static const TRANSFER_HISTORY_LIST = "TRANSFER_HISTORY_LIST";
  static const FISCAL_DEVICE = "FISCAL_DEVICE";
  static const IS_FISCALISATION_ENABLED = "IS_FISCALISATION_ENABLED";
  static const ALWAYS_PRINT = "ALWAYS_PRINT";
  static const USE_KOT = "USE_KOT";
  static const KOT_NUMBER = "KOT_NUMBER";
  static const SYNCING_IN_PROGRESS = "SYNCING_IN_PROGRESS";
  static const DEFAULT_CURRENCY_ID = "DEFAULT_CURRENCY_ID";
  static const DEFAULT_PAYMENT_METHOD_ID = "DEFAULT_PAYMENT_METHOD_ID";
  static const THEME_MODE = "THEME_MODE"; // 'light' | 'dark' | 'system'
  static const SELECTED_SHIFT_REF = "SELECTED_SHIFT_REF";

  static const DEFAULT_FISCAL_SETTING = "DEFAULT_FISCAL_SETTING";
  static const ENABLE_TAX = "ENABLE_TAX";
  static const USE_NFC = "USE_NFC";
  static const REQUISITION_LIST = "REQUISITION_LIST";
  static const REQUISITION_HISTORY = "REQUISITION_HISTORY";

  static const USER_PASSWORD = "USER_PASSWORD";
  static const IS_USER_INITIALLY_AUTHENTICATED = "IS_USER_INITIALLY_AUTHENTICATED";
  static const SAVED_USER_CREDENTIALS = "SAVED_USER_CREDENTIALS"; // Map of username -> {userInfo, password}
  static const APP_DATE_TIME_FMT = "yyyy-MM-dd HH:mm:ss";


  static const kItemNameStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 18);

  static const kItemColorStyle = TextStyle(fontWeight: FontWeight.w400, fontSize: 15,color: Colors.black54);

  static const kItemPriceStyle = TextStyle(fontWeight: FontWeight.w500, fontSize: 16);

  static String getDateNowRef(String prefix, int count){
    DateTime now = DateTime.now();
    int day = now.day;        // Today's day
    int month = now.month;
    int year = now.year - 2000; // Current month
    int hr = now.hour;
    int min = now.minute;
    int sec = now.second;
    String ref = "${prefix}${day}${month}${year}${hr}${min}${sec}${count}";
    return ref;
  }





  static void printLongJson(String content) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create the custom folder path
      final folderPath = '${directory.path}/jsonoutput';
      final folder = Directory(folderPath);

      // Check if the folder exists, if not, create it
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      // Create the full file path
      final filePath = '$folderPath/jsondata_love.json';
      final file = File(filePath);

      await file.writeAsString(content);
      print('File saved to $filePath');
    } catch (e) {
      print('Error writing to file: $e');
    }
  }



}