class AppValidators {
  static String? required(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String fieldName = 'Value']) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value);
    if (n == null) return '$fieldName must be a valid number';
    if (n < 0) return '$fieldName cannot be negative';
    return null;
  }

  static String? positiveInteger(String? value, [String fieldName = 'Value']) {
    if (value == null || value.trim().isEmpty) return null;
    final n = int.tryParse(value);
    if (n == null) return '$fieldName must be a whole number';
    if (n < 0) return '$fieldName cannot be negative';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    if (value.trim().length < 7) return 'Enter a valid phone number';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? minLength(String? value, int min, [String fieldName = 'Field']) {
    if (value == null || value.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  static String? sellQuantity(String? value, int availableQty) {
    if (value == null || value.trim().isEmpty) return 'Quantity is required';
    final n = int.tryParse(value);
    if (n == null) return 'Enter a valid quantity';
    if (n <= 0) return 'Quantity must be greater than 0';
    if (n > availableQty) return 'Only $availableQty units available';
    return null;
  }
}
