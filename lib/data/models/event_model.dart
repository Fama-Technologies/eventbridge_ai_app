import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Plain DTO matching the EventBridge Flutter prompt spec.
/// Lives in `lib/data/models/` per the prompt's folder layout — kept
/// independent from the existing feature-scoped models.
class EventModel {
  final String id;
  final String title;
  final String category; // 'party' | 'corporate' | 'travel' | 'wedding' | 'music'
  final String date;
  final String price;
  final String location;
  final String vendorId;
  final bool isFeatured;
  final bool isAiRecommended;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.price,
    required this.location,
    required this.vendorId,
    required this.createdAt,
    this.isFeatured = false,
    this.isAiRecommended = false,
  });

  List<Color> get gradientColors {
    switch (category.toLowerCase()) {
      case 'party':
        return AppColors.partyGradient;
      case 'corporate':
        return AppColors.corporateGradient;
      case 'travel':
        return AppColors.travelGradient;
      case 'wedding':
        return AppColors.weddingGradient;
      default:
        return AppColors.musicGradient;
    }
  }

  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'party':
        return Icons.celebration;
      case 'corporate':
        return Icons.business_center;
      case 'travel':
        return Icons.flight_takeoff;
      case 'wedding':
        return Icons.favorite;
      default:
        return Icons.music_note;
    }
  }
}
