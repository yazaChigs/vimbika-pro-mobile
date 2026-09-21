import 'package:flutter/material.dart';
import 'package:flutter_presentation_display/flutter_presentation_display.dart';
import 'package:vimbika_pro/app_constants/app_theme.dart';

class SunmiLcdScreen extends StatefulWidget {
  final ValueSetter<dynamic>? onDataHandler;

  const SunmiLcdScreen({Key? key, this.onDataHandler}) : super(key: key);

  @override
  State<SunmiLcdScreen> createState() => _SunmiLcdScreenState();
}

class _SunmiLcdScreenState extends State<SunmiLcdScreen> {
  FlutterPresentationDisplay? _presentationDisplay;
  String _companyName = 'VIMBIKA POS';
  String _imageUrl = '';
  String _currency = 'USD';
  double _total = 0.0;
  double _subtotal = 0.0;
  double _tax = 0.0;
  double _discount = 0.0;
  double _change = 0.0;
  double _numberOfItems = 0.0;
  String _statusMessage = 'Welcome to Vimbika POS!';
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    try {
      _presentationDisplay = FlutterPresentationDisplay();
      _presentationDisplay?.listenDataFromMainDisplay(handleDisplayData);
    } catch (_) {}
  }

  void handleDisplayData(dynamic data) {
    if (widget.onDataHandler != null) {
      widget.onDataHandler!(data);
    }
    if (data is! Map) return;

    setState(() {
      if (data['companyName'] != null) {
        _companyName = data['companyName'].toString();
      }
      if (data['imageUrl'] != null) {
        _imageUrl = data['imageUrl'].toString();
      }
      if (data['currency'] != null) {
        _currency = data['currency'].toString();
      }
      if (data['total'] != null) {
        _total = (data['total'] as num).toDouble();
      }
      if (data['subtotal'] != null) {
        _subtotal = (data['subtotal'] as num).toDouble();
      }
      if (data['tax'] != null) {
        _tax = (data['tax'] as num).toDouble();
      }
      if (data['discount'] != null) {
        _discount = (data['discount'] as num).toDouble();
      }
      if (data['change'] != null) {
        _change = (data['change'] as num).toDouble();
      }
      if (data['numberOfItems'] != null) {
        _numberOfItems = (data['numberOfItems'] as num).toDouble();
      }
      if (data['statusMessage'] != null) {
        _statusMessage = data['statusMessage'].toString();
      }

      if (data['items'] != null && data['items'] is List) {
        _items = (data['items'] as List).map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          } else {
            return {
              'name': item.toString(),
              'quantity': 1,
              'price': 0.0,
              'total': 0.0,
              'description': item.toString(),
            };
          }
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: Branding, Status & Summary
              Expanded(
                flex: 5,
                child: _buildLeftPanel(),
              ),
              const SizedBox(width: 16),
              // Right Panel: Itemized Cart List
              Expanded(
                flex: 6,
                child: _buildRightCartPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 2,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.point_of_sale,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _companyName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              'Currency: $_currency',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      children: [
        // Brand / Logo Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _imageUrl.isNotEmpty
                    ? Image.network(
                        _imageUrl,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset('assets/images/logo.png', height: 120),
                      )
                    : Image.asset('assets/images/logo.png', height: 120),
              ),
              const SizedBox(height: 10),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Totals & Change Box
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    _buildSummaryRow('Items Count', '${_numberOfItems.toStringAsFixed(_numberOfItems.truncateToDouble() == _numberOfItems ? 0 : 2)} items', isLight: true),
                    if (_subtotal > 0 && _subtotal != _total) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow('Subtotal', '$_currency ${_subtotal.toStringAsFixed(2)}', isLight: true),
                    ],
                    if (_tax > 0) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow('Tax', '$_currency ${_tax.toStringAsFixed(2)}', isLight: true),
                    ],
                    if (_discount > 0) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow('Discount', '-$_currency ${_discount.toStringAsFixed(2)}', isLight: true),
                    ],
                  ],
                ),
                Column(
                  children: [
                    const Divider(color: Colors.white24, thickness: 1.5),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$_currency ${_total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4ADE80), // Vibrant Green
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_change > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEF4444)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CHANGE DUE',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFCA5A5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$_currency ${_change.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF87171),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isLight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: isLight ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isLight ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildRightCartPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_cart_outlined, color: Color(0xFF334155), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Your Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_items.length} lines',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Items list or empty state
          Expanded(
            child: _items.isEmpty ? _buildEmptyCartState() : _buildCartItemsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCartState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 56,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Cart is Ready',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Items added by the cashier will appear here in real-time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (context, index) {
        final item = _items[index];
        final name = item['name']?.toString() ?? 'Item';
        final qty = (item['quantity'] as num?)?.toDouble() ?? 1.0;
        final unitPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
        final total = (item['total'] as num?)?.toDouble() ?? (qty * unitPrice);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Quantity Badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 1)}x',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Item Name & Unit Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_currency ${unitPrice.toStringAsFixed(2)} each',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Line Total
              Text(
                '$_currency ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
