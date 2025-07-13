import 'package:flutter/material.dart';

class InfoPill extends StatelessWidget {
  final String? label;
  final Widget? labelWidget;
  final String statusText; // Displayed on right
  final double? value; // Optional, used for logic
  final bool isSystem;
  final Color? colorOverride;
  final String? subtitle;

  const InfoPill({
    super.key,
    this.label,
    required this.statusText,
    this.value,
    this.subtitle,
    this.isSystem = false,
    this.colorOverride,
    this.labelWidget,
  });

  Color? get statusColor {
    if (colorOverride != null) return colorOverride!;
    if (value != null) {
      if (value! < 60) return Colors.yellowAccent[100];
      if (value! < 85) return Colors.orangeAccent[100];
      return Colors.lightGreenAccent[100];
    }
    return Colors.lightGreenAccent[100];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 4,
            spreadRadius: 3,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored Left Section
            Expanded(child:
              Container(
                width: 130,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    bottomLeft: Radius.circular(32),
                  ),
                ),
                child: isSystem
                    ? Align(
                  alignment: Alignment.centerRight,
                  child: labelWidget ?? Text(
                    label ?? '',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    labelWidget ?? Text(
                      label ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),


            // Right Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
