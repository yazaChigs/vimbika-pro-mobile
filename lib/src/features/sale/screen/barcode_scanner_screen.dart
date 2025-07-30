import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vimbika_pos_app/src/constants/app_routes.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/sale_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/controller/cart_controller.dart';
import 'package:vimbika_pos_app/src/features/sale/model/product_full_info_model.dart';
import 'package:vimbika_pos_app/src/shared/models/customer_model.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final String? scanMode; // 'product' or 'customer'

  const BarcodeScannerScreen({super.key, this.scanMode});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final SaleController saleController = Get.find<SaleController>();
  final CartController cartController = Get.find<CartController>();
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  bool hasPermission = false;
  int productsAddedInSession = 0;
  bool soundEnabled = true;
  final AudioPlayer audioPlayer = AudioPlayer();
  String lastScannedBarcode = '';
  DateTime? lastScanTime;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      hasPermission = status.isGranted;
    });

    if (!hasPermission) {
      Get.snackbar(
        "Camera Permission Required",
        "Please grant camera permission to scan barcodes",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _playSuccessSound() async {
    if (!soundEnabled) return;

    try {
      // Try to play a system notification sound
      await audioPlayer
          .play(DeviceFileSource('/system/media/audio/ui/Effect_Tick.ogg'));
    } catch (e) {
      try {
        // Fallback to another system sound
        await audioPlayer.play(
            DeviceFileSource('/system/media/audio/ui/notification_simple.ogg'));
      } catch (e) {
        try {
          // Another fallback
          await audioPlayer.play(DeviceFileSource(
              '/system/media/audio/ui/notification_default.ogg'));
        } catch (e) {
          // Final fallback: just log the error
          print('Could not play success sound: $e');
        }
      }
    }
  }

  bool _isDuplicateScan(String barcode) {
    if (lastScannedBarcode == barcode) {
      // Check if it's within 3 seconds of the last scan
      if (lastScanTime != null &&
          DateTime.now().difference(lastScanTime!).inSeconds < 3) {
        return true;
      }
    }
    return false;
  }

  void _updateScanHistory(String barcode) {
    lastScannedBarcode = barcode;
    lastScanTime = DateTime.now();
  }

  @override
  void dispose() {
    cameraController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  void onDetect(BarcodeCapture capture) {
    if (!isScanning || !hasPermission) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      setState(() {
        isScanning = false;
      });

      String scannedCode = barcodes.first.rawValue ?? '';
      processBarcode(scannedCode);
    }
  }

  void processBarcode(String scannedCode) {
    if (scannedCode.isEmpty) {
      Get.snackbar(
        "Invalid Barcode",
        "No barcode detected",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() {
        isScanning = true;
      });
      return;
    }

    // Check for duplicate scan
    if (_isDuplicateScan(scannedCode)) {
      Get.dialog(
        AlertDialog(
          title: const Text('Duplicate Scan'),
          content: Text(
              'The barcode "$scannedCode" was just scanned. Do you want to add it again?'),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                setState(() {
                  isScanning = true;
                });
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _processBarcodeLogic(scannedCode);
              },
              child: const Text('Add Again'),
            ),
          ],
        ),
      );
      return;
    }

    // Update scan history
    _updateScanHistory(scannedCode);

    // Check if this is customer scanning mode
    if (widget.scanMode == 'customer') {
      _processCustomerBarcode(scannedCode);
      return;
    }

    // Process the barcode similar to the existing logic
    String exp = scannedCode;

    if (saleController.useSerialNumbers) {
      // Search by exact barcode match for serial numbers
      var index = saleController.allProducts
          .indexWhere((item) => item.barCodes?.contains(exp) == true);

      if (index != -1) {
        ProductFullInfoModel foundItem = saleController.allProducts[index];
        var indexC = cartController.cartItems
            .indexWhere((item) => item.product.item?.id == foundItem.item?.id);

        if (indexC != -1) {
          cartController.addToCartWithBarCode(foundItem, 1, exp);
          setState(() {
            productsAddedInSession++;
          });
          _playSuccessSound();
        } else {
          Get.snackbar(
            "Product Added",
            "Product added to cart!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          cartController.addToCartWithBarCode(foundItem, 1, exp);
          setState(() {
            productsAddedInSession++;
          });
          _playSuccessSound();
        }
      } else {
        // Try item code lookup
        var index = saleController.allProducts
            .indexWhere((item) => item.item?.itemCode == exp);

        if (index != -1) {
          ProductFullInfoModel foundItem = saleController.allProducts[index];
          var indexC = cartController.cartItems.indexWhere(
              (item) => item.product.item?.id == foundItem.item?.id);

          if (indexC != -1) {
            cartController.addToCart(foundItem, 1);
            setState(() {
              productsAddedInSession++;
            });
            _playSuccessSound();
          } else {
            Get.snackbar(
              "Product Added",
              "Product added to cart!",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            cartController.addToCart(foundItem, 1);
            setState(() {
              productsAddedInSession++;
            });
            _playSuccessSound();
          }
        } else {
          Get.snackbar(
            "Product Not Found",
            "Product with code $exp is not found!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } else if (exp.length >= 12) {
      // Process weight-based barcodes
      String productCode = exp.length > 6 ? exp.substring(2, 6) : '';
      String weight = exp.length > 12 ? exp.substring(7, 12) : '0';

      double kgs = double.parse(weight) / 1000;
      double roundedValue = double.parse(kgs.toStringAsFixed(3));

      if (kgs > 0) {
        var index = saleController.allProducts
            .indexWhere((item) => item.item?.itemCode == productCode);

        if (index != -1) {
          ProductFullInfoModel foundItem = saleController.allProducts[index];
          var indexC = cartController.cartItems.indexWhere(
              (item) => item.product.item?.id == foundItem.item?.id);

          if (indexC != -1) {
            cartController.addToCart(foundItem, roundedValue);
            setState(() {
              productsAddedInSession++;
            });
            _playSuccessSound();
          } else {
            Get.snackbar(
              "Product Added",
              "Product added to cart!",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue,
              colorText: Colors.white,
            );
            cartController.addToCart(foundItem, roundedValue);
            setState(() {
              productsAddedInSession++;
            });
            _playSuccessSound();
          }
        } else {
          Get.snackbar(
            "Product Not Found",
            "Product with code $productCode is not found!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } else {
      // Try direct item code lookup
      var index = saleController.allProducts
          .indexWhere((item) => item.item?.itemCode == exp);

      if (index != -1) {
        ProductFullInfoModel foundItem = saleController.allProducts[index];
        var indexC = cartController.cartItems
            .indexWhere((item) => item.product.item?.id == foundItem.item?.id);

        if (indexC != -1) {
          cartController.addToCart(foundItem, 1);
          setState(() {
            productsAddedInSession++;
          });
          _playSuccessSound();
        } else {
          Get.snackbar(
            "Product Added",
            "Product added to cart!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          cartController.addToCart(foundItem, 1);
          setState(() {
            productsAddedInSession++;
          });
          _playSuccessSound();
        }
      } else {
        Get.snackbar(
          "Product Not Found",
          "Product with code $exp is not found!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }

    // Reset scanning after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isScanning = true;
      });
    });
  }

  void _processBarcodeLogic(String scannedCode) {
    String exp = scannedCode;

    if (saleController.useSerialNumbers) {
      // Search by exact barcode match for serial numbers
      var index = saleController.allProducts
          .indexWhere((item) => item.barCodes?.contains(exp) == true);

      if (index != -1) {
        ProductFullInfoModel foundItem = saleController.allProducts[index];
        var indexC = cartController.cartItems
            .indexWhere((item) => item.product.item?.id == foundItem.item?.id);

        if (indexC != -1) {
          cartController.addToCartWithBarCode(foundItem, 1, exp);
          setState(() {
            productsAddedInSession++;
          });
          _playSuccessSound();
        } else {
          Get.snackbar(
            "Product Added",
            "Product added to cart!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          cartController.addToCartWithBarCode(foundItem, 1, exp);
          setState(() {
            productsAddedInSession++;
          });
          _playSuccessSound();
        }
      } else {
        // Try item code lookup
        var index = saleController.allProducts
            .indexWhere((item) => item.item?.itemCode == exp);

        if (index != -1) {
          ProductFullInfoModel foundItem = saleController.allProducts[index];
          var indexC = cartController.cartItems.indexWhere(
              (item) => item.product.item?.id == foundItem.item?.id);

          if (indexC != -1) {
            cartController.addToCart(foundItem, 1);
            setState(() {
              productsAddedInSession++;
            });
            _playSuccessSound();
          } else {
            Get.snackbar(
              "Product Added",
              "Product added to cart!",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );
            cartController.addToCart(foundItem, 1);
            setState(() {
              productsAddedInSession++;
            });
            _playSuccessSound();
          }
        } else {
          Get.snackbar(
            "Product Not Found",
            "Product with code $exp is not found!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } else if (exp.length >= 12) {
      // Process weight-based barcodes
      String productCode = exp.length > 6 ? exp.substring(2, 6) : '';
      String weight = exp.length > 12 ? exp.substring(7, 12) : '0';

      double kgs = double.parse(weight) / 1000;
      double roundedValue = double.parse(kgs.toStringAsFixed(3));

      if (kgs > 0) {
        var index = saleController.allProducts
            .indexWhere((item) => item.item?.itemCode == productCode);

        if (index != -1) {
          ProductFullInfoModel foundItem = saleController.allProducts[index];
          var indexC = cartController.cartItems.indexWhere(
              (item) => item.product.item?.id == foundItem.item?.id);

          if (indexC != -1) {
            cartController.addToCart(foundItem, roundedValue);
            setState(() {
              productsAddedInSession++;
            });
            _playSuccessSound();
          } else {
            Get.snackbar(
              "Product Added",
              "Product added to cart!",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue,
              colorText: Colors.white,
            );
            cartController.addToCart(foundItem, roundedValue);
            setState(() {
              productsAddedInSession++;
            });
            _playSuccessSound();
          }
        } else {
          Get.snackbar(
            "Product Not Found",
            "Product with code $productCode is not found!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } else {
      // Try direct item code lookup
      var index = saleController.allProducts
          .indexWhere((item) => item.item?.itemCode == exp);

      if (index != -1) {
        ProductFullInfoModel foundItem = saleController.allProducts[index];
        var indexC = cartController.cartItems
            .indexWhere((item) => item.product.item?.id == foundItem.item?.id);

        if (indexC != -1) {
          cartController.addToCart(foundItem, 1);
          setState(() {
            productsAddedInSession++;
          });
          _playSuccessSound();
        } else {
          Get.snackbar(
            "Product Added",
            "Product added to cart!",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          cartController.addToCart(foundItem, 1);
          setState(() {
            productsAddedInSession++;
          });
          _playSuccessSound();
        }
      } else {
        Get.snackbar(
          "Product Not Found",
          "Product with code $exp is not found!",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }

    // Reset scanning after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isScanning = true;
      });
    });
  }

  void _processCustomerBarcode(String scannedCode) {
    // Search for customer by account number
    var customerIndex = cartController.allCustomers
        .indexWhere((customer) => customer.accountNumber == scannedCode);

    if (customerIndex != -1) {
      CustomerModel foundCustomer = cartController.allCustomers[customerIndex];

      // Set the selected customer
      cartController.onCustomerChange(foundCustomer);

      // Show success message
      Get.snackbar(
        "Customer Found",
        "Customer: ${foundCustomer.name}",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Play success sound
      _playSuccessSound();

      // Navigate back to sale screen
      Future.delayed(const Duration(seconds: 1), () {
        Get.back();
      });
    } else {
      // Customer not found
      Get.snackbar(
        "Customer Not Found",
        "No customer found with account number: $scannedCode",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Reset scanning after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          isScanning = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera Permission'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Camera Permission Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please grant camera permission to scan barcodes',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _requestCameraPermission,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scanMode == 'customer'
            ? 'Customer Scanner'
            : 'Barcode Scanner'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Products added badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // Show cart summary or navigate to cart
                  Get.snackbar(
                    "Cart Summary",
                    "Products added in this session: $productsAddedInSession",
                    snackPosition: SnackPosition.TOP,
                    backgroundColor: Colors.blue,
                    colorText: Colors.white,
                  );
                },
              ),
              if (productsAddedInSession > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '${productsAddedInSession}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              soundEnabled ? Icons.volume_up : Icons.volume_off,
            ),
            onPressed: () {
              setState(() {
                soundEnabled = !soundEnabled;
              });
              Get.snackbar(
                soundEnabled ? "Sound Enabled" : "Sound Disabled",
                soundEnabled
                    ? "Success sounds will play"
                    : "Success sounds are muted",
                snackPosition: SnackPosition.TOP,
                backgroundColor: soundEnabled ? Colors.green : Colors.grey,
                colorText: Colors.white,
                duration: const Duration(seconds: 1),
              );
            },
          ),
          IconButton(
            icon: Icon(
              cameraController.torchEnabled ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: onDetect,
                ),
                // Scanning overlay
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white,
                      width: 2.0,
                    ),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.white, width: 3),
                            bottom: BorderSide(color: Colors.white, width: 3),
                            left: BorderSide(color: Colors.white, width: 3),
                            right: BorderSide(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Instructions overlay
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          widget.scanMode == 'customer'
                              ? 'Position customer loyalty card within the frame to scan'
                              : 'Position barcode within the frame to scan',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                        if (productsAddedInSession > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Products added: $productsAddedInSession',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 75, 175, 9),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isScanning = true;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rescan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      productsAddedInSession = 0;
                    });
                    Get.snackbar(
                      "Session Reset",
                      "Product counter has been reset",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                    );
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Reset'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
