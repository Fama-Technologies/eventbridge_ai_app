import 'package:flutter/material.dart';

enum VendorPlanType {
  free,
  pro,
  business_pro,
}

class SubscriptionConstants {
  static const Map<VendorPlanType, int> maxPackages = {
    VendorPlanType.free: 0,
    VendorPlanType.pro: 3,
    VendorPlanType.business_pro: 6,
  };

  static const Map<VendorPlanType, int> maxPortfolioItems = {
    VendorPlanType.free: 0,
    VendorPlanType.pro: 3,
    VendorPlanType.business_pro: 6,
  };

  static const Map<VendorPlanType, double> monthlyPrice = {
    VendorPlanType.free: 0.0,
    VendorPlanType.pro: 15.0,
    VendorPlanType.business_pro: 30.0,
  };

  static String getPlanLabel(VendorPlanType type, {bool showAsFree = false}) {
    if (showAsFree) return 'FREE';
    switch (type) {
      case VendorPlanType.free:
        return 'FREE';
      case VendorPlanType.pro:
        return 'PRO';
      case VendorPlanType.business_pro:
        return 'BUSINESS PRO';
    }
  }

  static Color getPlanColor(VendorPlanType type) {
    switch (type) {
      case VendorPlanType.free:
        return Colors.grey;
      case VendorPlanType.pro:
        return const Color(0xFFF59E0B); // Amber
      case VendorPlanType.business_pro:
        return const Color(0xFF8B5CF6); // Violet
    }
  }
}
