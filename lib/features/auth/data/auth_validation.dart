bool isValidEmail(String value) {
  final email = value.trim();
  final at = email.indexOf('@');
  return at > 0 &&
      at == email.lastIndexOf('@') &&
      email.indexOf('.', at) > at + 1 &&
      !email.endsWith('.');
}

String? passwordError(String value) =>
    value.length < 8 ? 'Password must contain at least 8 characters' : null;
