class AuthValidators {
  static final RegExp _phonePattern = RegExp(r'^\d{10}$');
  static final RegExp _emailPattern = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
    caseSensitive: false,
  );
  static final RegExp _letterPattern = RegExp(r'[A-Za-z]');
  static final RegExp _digitPattern = RegExp(r'\d');

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName inahitajika.';
    }
    return null;
  }

  static String? fullName(String? value) {
    final requiredError = required(value, 'Jina kamili');
    if (requiredError != null) {
      return requiredError;
    }

    final normalized = value!.trim();
    if (normalized.length < 3) {
      return 'Jina kamili lazima liwe na angalau herufi 3.';
    }
    if (!_letterPattern.hasMatch(normalized)) {
      return 'Jina kamili lazima liwe na herufi.';
    }
    return null;
  }

  static String? phoneNumber(String? value) {
    final requiredError = required(value, 'Namba ya simu');
    if (requiredError != null) {
      return requiredError;
    }

    final normalized = value!.trim().replaceAll(RegExp(r'\s+'), '');
    if (!_phonePattern.hasMatch(normalized)) {
      return 'Weka namba ya simu sahihi yenye tarakimu 10.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final normalized = value.trim();
    if (!_emailPattern.hasMatch(normalized)) {
      return 'Weka barua pepe sahihi.';
    }
    return null;
  }

  static String? emailRequired(String? value) {
    final requiredError = required(value, 'Barua pepe');
    if (requiredError != null) {
      return requiredError;
    }
    return email(value);
  }

  static String? emailOrPhone(String? value) {
    final requiredError = required(value, 'Barua pepe au namba ya simu');
    if (requiredError != null) {
      return requiredError;
    }

    final normalized = value!.trim();
    if (_emailPattern.hasMatch(normalized) || _phonePattern.hasMatch(normalized)) {
      return null;
    }

    return 'Weka barua pepe sahihi au namba ya simu yenye tarakimu 10.';
  }

  static String? password(String? value) {
    final requiredError = required(value, 'Nenosiri');
    if (requiredError != null) {
      return requiredError;
    }

    final normalized = value!;
    if (normalized.length < 8) {
      return 'Nenosiri lazima liwe na angalau herufi 8.';
    }
    if (!_letterPattern.hasMatch(normalized) || !_digitPattern.hasMatch(normalized)) {
      return 'Nenosiri liwe na herufi na namba.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final requiredError = required(value, 'Thibitisha nenosiri');
    if (requiredError != null) {
      return requiredError;
    }

    if (value != password) {
      return 'Nenosiri halilingani.';
    }
    return null;
  }
}
