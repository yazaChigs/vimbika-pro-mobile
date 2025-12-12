import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vimbika_pos_app/src/features/shift/controller/shifts_history_controller.dart';
import 'package:vimbika_pos_app/src/features/shift/model/shift_model.dart';

class ShiftsHistoryScreen extends StatelessWidget {
  final ShiftsHistoryController controller = Get.put(ShiftsHistoryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'SHIFTS HISTORY',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.refreshShifts(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.value.isNotEmpty && controller.allShifts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.refreshShifts(),
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.allShifts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No shifts found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.refreshShifts();
          },
          child: ListView.builder(
            itemCount: controller.allShifts.length,
            itemBuilder: (context, index) {
              final shift = controller.allShifts[index];
              return _buildShiftCard(shift);
            },
          ),
        );
      }),
    );
  }

  Widget _buildShiftCard(ShiftModel shift) {
    bool isClosed = shift.isShiftClosed == true;
    Color statusColor = isClosed ? Colors.red : Colors.green;
    String statusText = isClosed ? 'CLOSED' : 'OPEN';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Optional: Navigate to shift details
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shift Reference',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          shift.shiftReference ?? 'N/A',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      _buildSyncStatusBadge(shift),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Opening Time',
                      _formatDateTime(shift.openingTime),
                      Icons.access_time,
                    ),
                  ),
                  if (isClosed)
                    Expanded(
                      child: _buildInfoItem(
                        'Closing Time',
                        _formatDateTime(shift.closingTime),
                        Icons.lock_clock,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
              if (shift.userFullName != null && shift.userFullName!.isNotEmpty)
                _buildInfoItem(
                  'User',
                  shift.userFullName!,
                  Icons.person,
                ),
              if (shift.company != null)
                _buildInfoItem(
                  'Company',
                  shift.company!.name ?? 'N/A',
                  Icons.business,
                ),
              SizedBox(height: 8),
              // Sales count section
              Obx(() {
                final salesCount = controller.getSalesCountForShift(shift.shiftReference);
                if (salesCount.total > 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSalesCountItem(
                              'Total Sales',
                              salesCount.total.toString(),
                              Icons.shopping_cart,
                              Colors.blue,
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey[300],
                            ),
                            _buildSalesCountItem(
                              'Synced',
                              salesCount.synced.toString(),
                              Icons.cloud_done,
                              Colors.green,
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.grey[300],
                            ),
                            _buildSalesCountItem(
                              'Unsynced',
                              salesCount.unsynced.toString(),
                              Icons.cloud_off,
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),
                      // Sales references section
                      _buildSalesReferencesSection(salesCount),
                    ],
                  );
                } else {
                  return SizedBox.shrink();
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusBadge(ShiftModel shift) {
    // Check sync status using id only
    bool isSynced = shift.id != null && shift.id!.isNotEmpty;
    
    String syncStatusText = isSynced ? 'SYNCED' : 'UNSYNCED';
    Color syncStatusColor = isSynced ? Colors.green : Colors.orange;
    IconData syncIcon = isSynced ? Icons.cloud_done : Icons.cloud_off;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: syncStatusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: syncStatusColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(syncIcon, size: 12, color: syncStatusColor),
          SizedBox(width: 4),
          Text(
            syncStatusText,
            style: TextStyle(
              color: syncStatusColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesCountItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesReferencesSection(ShiftSalesCount salesCount) {
    if (salesCount.allReferences.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales References',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          if (salesCount.syncedReferences.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.cloud_done, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Synced (${salesCount.syncedReferences.length}):',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: salesCount.syncedReferences.map((ref) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Text(
                    ref.reference,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green[800],
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }).toList(),
            ),
            if (salesCount.unsyncedReferences.isNotEmpty) SizedBox(height: 8),
          ],
          if (salesCount.unsyncedReferences.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Unsynced (${salesCount.unsyncedReferences.length}):',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: salesCount.unsyncedReferences.map((ref) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Text(
                    ref.reference,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[800],
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return 'N/A';
    }

    try {
      // Parse the datetime string
      DateTime dateTime = DateTime.parse(dateTimeString);
      
      // Format as readable string
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeString; // Return original if parsing fails
    }
  }
}

