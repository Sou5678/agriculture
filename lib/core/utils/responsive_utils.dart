import 'package:flutter/material.dart';
import '../constants.dart';

class ResponsiveUtils {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.mobile;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.tablet;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.tablet;
  }
  
  static double getResponsivePadding(BuildContext context) {
    if (isMobile(context)) return AppConstants.paddingMedium;
    if (isTablet(context)) return AppConstants.paddingLarge;
    return AppConstants.paddingLarge * 1.5;
  }
  
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isMobile(context)) return baseFontSize;
    if (isTablet(context)) return baseFontSize * 1.1;
    return baseFontSize * 1.2;
  }
  
  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }
  
  static double getImageHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (isMobile(context)) return screenHeight * 0.3;
    if (isTablet(context)) return screenHeight * 0.35;
    return screenHeight * 0.4;
  }
  
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final padding = getResponsivePadding(context);
    return EdgeInsets.all(padding);
  }
  
  static BorderRadius getResponsiveBorderRadius(BuildContext context) {
    if (isMobile(context)) return BorderRadius.circular(AppConstants.borderRadius);
    return BorderRadius.circular(AppConstants.borderRadius * 1.5);
  }
}