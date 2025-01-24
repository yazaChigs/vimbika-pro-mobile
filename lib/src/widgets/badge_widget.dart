import 'package:flutter/material.dart';

class BadgeWidget extends StatelessWidget {
  final Widget child;
  final Widget badgeContent;

  const BadgeWidget({super.key, required this.child, required this.badgeContent});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: 6, // Adjust to fine-tune the position
          top: 6,   // Adjust to fine-tune the position
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: BoxConstraints(
              minWidth: 14,
              minHeight: 14,
            ),
            child: Center(
              child: badgeContent,
            ),
          ),
        ),
      ],
    );
  }
}
