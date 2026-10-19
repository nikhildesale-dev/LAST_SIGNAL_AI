import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// Formatting utilities for dates, numbers, and risk indicators
class Formatters {
  Formatters._();

  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy • HH:mm');
  static final DateFormat _timeOnlyFormat = DateFormat('HH:mm:ss');
  static final DateFormat _shortDateFormat = DateFormat('MMM dd, HH:mm');

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  static String formatTimeOnly(DateTime dateTime) {
    return _timeOnlyFormat.format(dateTime);
  }

  static String formatShortDate(DateTime dateTime) {
    return _shortDateFormat.format(dateTime);
  }

  static String timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  static String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).toInt()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  static Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppColors.emergencyRed;
      case 'high':
        return AppColors.warningAmber;
      case 'moderate':
        return const Color(0xFFD49A3D);
      case 'low':
      default:
        return AppColors.successGreen;
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'Pending Sync':
        return AppColors.warningAmber;
      case 'Submitted':
        return AppColors.infoBlue;
      case 'Under Review':
        return const Color(0xFF9B51E0);
      case 'Verified':
        return AppColors.successGreen;
      case 'Rejected':
        return AppColors.emergencyRed;
      case 'Resolved':
        return AppColors.mutedBlue;
      default:
        return AppColors.mutedText;
    }
  }
}
