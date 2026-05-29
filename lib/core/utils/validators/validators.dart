class Validators {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) return 'Invalid email format';
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) return 'Password is required';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validateConfirmPassword({required String password, required String? confirmPassword}) {
    if (confirmPassword == null || confirmPassword.isEmpty) return 'Please confirm your password';
    if (password != confirmPassword) return 'Passwords do not match';
    return null;
  }

  static String? validateCode(String? code) {
    if (code == null || code.isEmpty) return 'Code is required';
    if (code.length != 6) return 'Code must be 6 characters';
    if (!RegExp(r'^\d{6}$').hasMatch(code)) return 'Code must be numeric';
    return null;
  }
}