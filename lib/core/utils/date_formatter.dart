import 'package:intl/intl.dart';

/// Date formatting utilities
class DateFormatter {
  /// Format date as "Jan 15, 2024"
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date and time as "Jan 15, 2024 at 3:30 PM"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(dateTime);
  }

  /// Format time only as "3:30 PM"
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Format date as "15/01/2024"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format relative time (e.g., "2 hours ago", "Yesterday")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Calculate age from birth date
  static String calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final years = (difference.inDays / 365).floor();
    final months = ((difference.inDays % 365) / 30).floor();

    if (years == 0) {
      if (months == 0) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} old';
      }
      return '$months ${months == 1 ? 'month' : 'months'} old';
    } else if (years == 1 && months == 0) {
      return '1 year old';
    } else if (months == 0) {
      return '$years years old';
    } else {
      return '$years ${years == 1 ? 'year' : 'years'}, $months ${months == 1 ? 'month' : 'months'} old';
    }
  }

  /// Format for medical records
  static String formatMedicalRecordDate(DateTime date) {
    return DateFormat('EEEE, MMM dd, yyyy').format(date);
  }

  /// Parse date string to DateTime
  static DateTime? parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Get days until date
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    return difference.inDays;
  }

  /// Format for vaccine due date
  static String formatVaccineDueDate(DateTime dueDate) {
    final daysLeft = daysUntil(dueDate);

    if (daysLeft < 0) {
      return 'Overdue by ${-daysLeft} ${-daysLeft == 1 ? 'day' : 'days'}';
    } else if (daysLeft == 0) {
      return 'Due today';
    } else if (daysLeft == 1) {
      return 'Due tomorrow';
    } else if (daysLeft <= 7) {
      return 'Due in $daysLeft days';
    } else if (daysLeft <= 30) {
      final weeks = (daysLeft / 7).ceil();
      return 'Due in $weeks ${weeks == 1 ? 'week' : 'weeks'}';
    } else {
      return formatDate(dueDate);
    }
  }
}
