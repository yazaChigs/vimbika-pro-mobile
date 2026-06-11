class AppConstants {
  static const String appName = 'Vimbika Lite';
  static const VIMBIKA_BACKEND_URL = "https://business.vimbika.co.zw/vimbika-zw/api";
  // static const VIMBIKA_BACKEND_URL = "https://business.vimbika.africa/vimbika-africa/api";
  // static const VIMBIKA_BACKEND_URL = "https://demo.vimbika.africa/uat-vimbika/api";
  // static const VIMBIKA_BACKEND_URL = "https://mashwede.vimbika.africa/mashwede/api";
  //     static const VIMBIKA_BACKEND_URL = "http://192.168.1.131:8080/vimbika-pro/api";
  //         static const VIMBIKA_BACKEND_URL = "http://192.168.1.148:8080/vimbika-pro/api";
  // static const VIMBIKA_BACKEND_URL = "http://172.20.10.4:8080/vimbika-pro/api";
  static const int defaultTimeout = 30000;
  static const CACHED_ACCESS_TOKEN = "CACHED_ACCESS_TOKEN";
  static const APP_DATE_TIME_FMT = "yyyy-MM-dd HH:mm:ss";

  // SharedPreferences Keys
  static const String keyHasUser = 'hasUser';
  static const String keyHasLoggedIn = 'hasLoggedIn'; // Added to track session status
  static const String keyUserData = 'user_data'; // Generic key for some backwards compatibility or common use
  static const String keyOnlineUserData = 'online_user_data';
  static const String keyOfflineUserData = 'offline_user_data';
  static const String keyAllUsers = 'all_users';
  static const String keyCompanyData = 'company_data';
  static const String keyOnlineCompanyData = 'online_company_data';
  static const String keyOfflineCompanyData = 'offline_company_data';
  static const String keyDefaultBranch = 'default_branch';
  static const String keyOfflineBranch = 'offline_branch';
  static const String keyBranches = 'branches';
  static const String keyOfflineBranches = 'offline_branches'; // Added
  static const String keyUserRoles = 'user_roles';
  static const String keySubscriptions = 'subscriptions';
  static const String keySubscriptionDaysRemaining = 'subscription_days_remaining'; // Added for subscription days remaining
  static const String keyConfig = 'config';
  
  static const String keyCurrencies = 'currencies';
  static const String keyOfflineCurrencies = 'offline_currencies'; // Added
  static const String keyTaxes = 'taxes';
  static const String keyOfflineTaxes = 'offline_taxes'; // Added
  static const String keyCategories = 'categories';
  static const String keyOfflineCategories = 'offline_categories'; // Added
  static const String keyExpenseCategories = 'expense_categories';
  static const String keyUnits = 'units';
  static const String keyOfflineUnits = 'offline_units'; // Added
  static const String keyBanks = 'banks';
  static const String keyOfflineBanks = 'offline_banks';
  static const String keyOfflinePendingBanks = 'offline_pending_banks'; // Added for banks created offline
  static const String keyPaymentTypes = 'payment_types';
  static const String keyOfflinePaymentTypes = 'offline_payment_types'; // Added
  static const String keySuppliers = 'suppliers';
  
  static const String keyCustomers = 'customers';
  static const String keyOfflineCustomers = 'offline_customers';
  static const String keySales = 'sales';
  static const String keyOfflineSales = 'offline_sales';
  static const String keyPurchases = 'purchases';
  static const String keyInventoryItems = 'inventory_items';
  static const String keyOfflineInventoryItems = 'offline_inventory_items';
  static const String keyExpenses = 'expenses';
  static const String keyOnlineExpenses = 'online_expenses';
  static const String keyBranchStock = 'branch_stocks';
  static const String keyOfflineBranchStock = 'offline_branch_stocks';
  static const String keyOutOfStockItems = 'out_of_stock_items';
  static const String keyLastSelectedDate = 'last_selected_date';
  static const String keyPaymentsReceived = 'payments_received';
  static const String keyOfflinePaymentsReceived = 'offline_payments_received'; // Added this
  static const String keyPaymentsPaid = 'payments_paid'; // Added this
  static const String keyMobileShifts = 'mobile_shifts'; // Added this
  static const String keyOfflineMobileShifts = 'offline_mobile_shifts'; // Added this for offline shifts
  static const String keyCurrentOpenShift = 'current_open_shift'; // Added this
  static const String keyHeldSales = 'held_sales'; // Added for holding sales
  static const String keyUnsyncedReceivedPayments = 'unsynced_received_payments'; // Added for unsynced received payments
  static const String keyCachedPastShifts = 'cached_past_shifts'; // Added for caching past shifts
  // Application Settings
  static const String keyAllowOutOfStockSales = 'allow_out_of_stock_sales';
  static const String keyIsOfflineMode = 'is_offline_mode';
  static const String keyIsPriceInclusiveTax = 'is_price_inclusive_tax'; // Added this
  static const String keyCompanySettings = 'company_settings';

  // Printer Settings
  static const String keyPrinterType = 'printer_type';
  static const String keyPrinterMacAddress = 'printer_mac_address';
  static const String keyPrinterName = 'printer_name';
  static const String keyAlwaysPrintReceipt = 'always_print_receipt'; // Added for printer settings
  static const String keyNumberOfReceiptsPerSale = 'number_of_receipts_per_sale';

  static String get keyUsbPrinterDevice => 'usb_printer_device'; // Added for number of receipts
}
