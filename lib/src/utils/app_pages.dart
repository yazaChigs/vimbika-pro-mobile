

import 'package:get/get.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/authentication/screen/choose_branch_screen.dart';
import 'package:vimbika_pos_app/src/features/authentication/screen/login_screen.dart';
import 'package:vimbika_pos_app/src/features/authentication/screen/pin_screen.dart';
import 'package:vimbika_pos_app/src/features/customers/screen/customer_form_screen.dart';
import 'package:vimbika_pos_app/src/features/customers/screen/customer_list_screen.dart';
import 'package:vimbika_pos_app/src/features/onboarding/screen/onboarding_screen.dart';
import 'package:vimbika_pos_app/src/features/printers/screen/printer_search_screen.dart';
import 'package:vimbika_pos_app/src/features/printers/screen/printer_settings_screen.dart';
import 'package:vimbika_pos_app/src/features/sale/screen/cart_screen.dart';
import 'package:vimbika_pos_app/src/features/sale/screen/checkout_screen.dart';
import 'package:vimbika_pos_app/src/features/sale/screen/sale_screen.dart';
import 'package:vimbika_pos_app/src/features/sale_receipts/screen/receipt_screen.dart';
import 'package:vimbika_pos_app/src/features/settings/screens/default_currency_screen.dart';
import 'package:vimbika_pos_app/src/features/settings/screens/default_payment_method_screen.dart';
import 'package:vimbika_pos_app/src/features/settings/screens/fiscal_settings_screen.dart';
import 'package:vimbika_pos_app/src/features/settings/screens/settings_screen.dart';
import 'package:vimbika_pos_app/src/features/shift/screen/cash_management_screen.dart';
import 'package:vimbika_pos_app/src/features/shift/screen/open_shift_screen.dart';
import 'package:vimbika_pos_app/src/features/shift/screen/submit_cash_screen.dart';
import 'package:vimbika_pos_app/src/features/shift/screen/view_shift_screen.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/screen/new_stock_request_screen.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/screen/stock_request_cart_screen.dart';
import 'package:vimbika_pos_app/src/features/stock_requests/screen/stock_request_menu_screen.dart';
import 'package:vimbika_pos_app/src/features/ticket/screen/ticket_form_screen.dart';
import 'package:vimbika_pos_app/src/features/ticket/screen/ticket_list_screen.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.ONBOARD, page: ()=>OnboardingScreen() ),
    GetPage(name: AppRoutes.LOGIN, page: ()=> const LoginScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.CHOOSE_BRANCH, page: ()=> const ChooseBranchScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.ENTER_PIN, page: ()=>  PinScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.CART, page: ()=>  CartScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.CHECKOUT, page: ()=>  CheckoutScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.SALE_RECEIPTS, page: ()=>  ReceiptScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.OPEN_SHIFT, page: ()=>  OpenShiftScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.VIEW_SHIFT, page: ()=>  ViewShiftScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.SALE, page: ()=>  SaleScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.PRINTER_SETTINGS, page: ()=>  PrinterSettingsScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.CASH_MANAGEMENT, page: ()=>  CashManagementScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.SUBMIT_CASH, page: ()=>  SubmitCashScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.CUSTOMER_LIST, page: ()=>  CustomerListScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.CUSTOMER_FORM, page: ()=>  CustomerFormScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.TICKET_LIST, page: ()=>  TicketListScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.TICKET_FORM, page: ()=>  TicketFormScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.NETWORK_PRINTERS, page: ()=>  NetworkPrintersScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.SETTINGS_SCREEN, page: ()=>  SettingsScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.DEFAULT_CURRENCY_SCREEN, page: ()=>  DefaultCurrencyScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.DEFAULT_PAYMENT_METHOD_SCREEN, page: ()=>  DefaultPaymentMethodScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.DEFAULT_FISCAL_SETTINGS, page: ()=>  FiscalSettingsScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.STOCK_REQUESTS_MENU, page: ()=>  StockRequestMenuScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.NEW_STOCK_REQUEST, page: ()=>  NewStockRequestScreen(),  transition: Transition.zoom ),
    GetPage(name: AppRoutes.NEW_STOCK_REQUEST_CART, page: ()=>  StockRequestCartScreen(),  transition: Transition.zoom )
  ];
}