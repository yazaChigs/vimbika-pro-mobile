
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppWidgets{
  Widget buildSettingButton(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,

      style: ElevatedButton.styleFrom(
        backgroundColor: context.theme.colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.theme.colorScheme.inverseSurface,),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 18),
        ],
      ),
    );
  }
}