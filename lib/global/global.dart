import 'package:flutter/material.dart';

bool isMobile(BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width;
  bool isMobile = screenWidth < 900;

  return isMobile;
}
