class AppValidators {
  const AppValidators._();

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? personName(String? value, {String label = 'name'}) {
    final name = value?.trim() ?? '';
    if (name.length < 2) {
      return 'Enter a valid $label.';
    }
    if (name.length > 60) {
      return 'Keep the $label under 60 characters.';
    }
    if (RegExp(r'\d').hasMatch(name)) {
      return 'The $label cannot contain numbers.';
    }
    if (!RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿĀ-ž' .-]+$").hasMatch(name)) {
      return 'Use letters, spaces, apostrophes or hyphens only.';
    }
    final lettersOnly = name.replaceAll(RegExp(r"[\s.'-]"), '');
    if (lettersOnly.length < 2) {
      return 'Enter a valid $label.';
    }
    return null;
  }

  static String? cardholderName(String? value) {
    return personName(value, label: 'cardholder name');
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }
    if (password.length > 30) {
      return 'Use no more than 30 characters.';
    }
    if (RegExp(r'\s').hasMatch(password)) {
      return 'Password cannot contain spaces.';
    }
    return null;
  }

  static String? requiredText(
    String? value, {
    required String label,
    int minimum = 2,
    int maximum = 120,
  }) {
    final text = value?.trim() ?? '';
    if (text.length < minimum) {
      return 'Enter a valid $label.';
    }
    if (text.length > maximum) {
      return 'Keep the $label within $maximum characters.';
    }
    return null;
  }

  static String? positiveNumber(String? value, {required String label}) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || !number.isFinite || number <= 0) {
      return 'Enter a valid $label greater than zero.';
    }
    return null;
  }

  static String? securityPhrase(String? value) {
    final phrase = value?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    if (phrase.length < 10 || phrase.split(' ').length < 3) {
      return 'Use a memorable phrase of at least 3 words.';
    }
    if (phrase.length > 120) {
      return 'Keep the recovery phrase under 120 characters.';
    }
    return null;
  }

  static String? phone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) {
      return null;
    }
    if (!RegExp(r'^[+0-9 ()-]+$').hasMatch(phone)) {
      return 'Enter a valid phone number.';
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9 || digits.length > 13) {
      return 'Use 9 to 13 digits.';
    }
    return null;
  }
}
