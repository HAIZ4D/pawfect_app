/// Form validation utilities
class Validators {
  /// Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  /// Name validation
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    return null;
  }

  /// Phone number validation
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');

    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Required field validation
  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Pet name validation
  static String? petName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pet name is required';
    }

    if (value.length < 2) {
      return 'Pet name must be at least 2 characters';
    }

    if (value.length > 50) {
      return 'Pet name must not exceed 50 characters';
    }

    return null;
  }

  /// Weight validation
  static String? weight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }

    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid number';
    }

    if (weight <= 0) {
      return 'Weight must be greater than 0';
    }

    if (weight > 500) {
      return 'Please enter a realistic weight';
    }

    return null;
  }

  /// Microchip ID validation
  static String? microchipId(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    if (value.length < 9 || value.length > 15) {
      return 'Microchip ID must be between 9-15 characters';
    }

    return null;
  }

  /// Confirm password validation
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Breed validation
  static String? breed(String? value) {
    if (value == null || value.isEmpty) {
      return 'Breed is required';
    }

    if (value.length < 2) {
      return 'Breed must be at least 2 characters';
    }

    return null;
  }

  /// Description validation (for medical records)
  static String? description(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }

    if (value.length > 1000) {
      return 'Description must not exceed 1000 characters';
    }

    return null;
  }

  /// Title validation
  static String? title(String? value) {
    if (value == null || value.isEmpty) {
      return 'Title is required';
    }

    if (value.length < 3) {
      return 'Title must be at least 3 characters';
    }

    if (value.length > 100) {
      return 'Title must not exceed 100 characters';
    }

    return null;
  }

  /// Clinic name validation
  static String? clinicName(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }

    if (value.length < 3) {
      return 'Clinic name must be at least 3 characters';
    }

    return null;
  }

  /// Veterinarian name validation
  static String? veterinarianName(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }

    if (value.length < 2) {
      return 'Veterinarian name must be at least 2 characters';
    }

    return null;
  }
}
