import 'package:flutter/services.dart';

/// Shared, professional form validation for every register / submission form.
///
/// Each `xxxError` returns `null` when the value is valid, or a short human
/// message to show (typically as red text under a field that turns red). The
/// `xxxFormatters` block invalid characters AS THE USER TYPES so, e.g., a name
/// field simply won't accept digits and a phone field won't accept letters.
class Validators {
  Validators._();

  // ── Name ───────────────────────────────────────────────────────────────
  // Letters, spaces, apostrophes, hyphens and dots only (covers names like
  // "D'Souza", "Jean-Luc", "Dr. Rao"). Digits and symbols are rejected.
  static final RegExp _nameAllowed = RegExp(r"^[a-zA-Z][a-zA-Z\s.'-]*$");

  static List<TextInputFormatter> get nameFormatters => [
    FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s.'-]")),
    LengthLimitingTextInputFormatter(50),
  ];

  static String? nameError(String? value, {String field = 'name'}) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your $field';
    if (v.length < 2) return 'Please enter a valid $field';
    if (!_nameAllowed.hasMatch(v)) {
      return 'Only letters are allowed in the $field';
    }
    return null;
  }

  // ── Email ──────────────────────────────────────────────────────────────
  // Practical RFC-ish check: something@something.tld, no spaces.
  static final RegExp _email = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  static List<TextInputFormatter> get emailFormatters => [
    // No spaces inside an email address.
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
    LengthLimitingTextInputFormatter(120),
  ];

  static String? emailError(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your email address';
    if (!_email.hasMatch(v)) return 'Please enter a valid email address';
    return null;
  }

  // ── Phone ──────────────────────────────────────────────────────────────
  // Digits only for typing (plus an optional leading +, spaces and hyphens for
  // formatting); validated on the digit count.
  static List<TextInputFormatter> get phoneFormatters => [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
    LengthLimitingTextInputFormatter(18),
  ];

  static String? phoneError(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter your phone number';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    if (digits.length > 15) return 'Please enter a valid phone number';
    return null;
  }

  // ── Generic required ─────────────────────────────────────────────────────
  static String? requiredError(String? value, {String field = 'this field'}) {
    if ((value ?? '').trim().isEmpty) return 'Please enter $field';
    return null;
  }
}
