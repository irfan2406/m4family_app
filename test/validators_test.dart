import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m4_mobile/core/utils/validators.dart';

/// Applies a formatter chain the way a TextField would, to prove that invalid
/// characters are actually stripped as the user types.
String _typed(List<TextInputFormatter> formatters, String input) {
  var value = const TextEditingValue(text: '');
  for (final ch in input.split('')) {
    final next = TextEditingValue(
      text: value.text + ch,
      selection: TextSelection.collapsed(offset: value.text.length + 1),
    );
    var out = next;
    for (final f in formatters) {
      out = f.formatEditUpdate(value, out);
    }
    value = out;
  }
  return value.text;
}

void main() {
  group('name', () {
    test('accepts real names, rejects digits/symbols', () {
      expect(Validators.nameError('Abuzar Shaikh'), isNull);
      expect(Validators.nameError("D'Souza"), isNull);
      expect(Validators.nameError('Jean-Luc'), isNull);
      expect(Validators.nameError(''), isNotNull);
      expect(Validators.nameError('A'), isNotNull);
      expect(Validators.nameError('Abuzar123'), isNotNull);
      expect(Validators.nameError('John@'), isNotNull);
    });

    test('formatter blocks digits/symbols while typing', () {
      expect(_typed(Validators.nameFormatters, 'Ab123uz@r'), 'Abuzr');
      expect(_typed(Validators.nameFormatters, 'Sana!#4'), 'Sana');
    });
  });

  group('email', () {
    test('accepts valid, rejects malformed', () {
      expect(Validators.emailError('sana.m@gmail.com'), isNull);
      expect(Validators.emailError('a+b@sub.domain.co'), isNull);
      expect(Validators.emailError(''), isNotNull);
      expect(Validators.emailError('gmail'), isNotNull);
      expect(Validators.emailError('a@b'), isNotNull);
      expect(Validators.emailError('a@@b.com'), isNotNull);
      expect(Validators.emailError('a b@gmail.com'), isNotNull);
    });

    test('formatter blocks spaces while typing', () {
      expect(_typed(Validators.emailFormatters, 'a b@x.com'), 'ab@x.com');
    });
  });

  group('phone', () {
    test('accepts 10-15 digits, rejects short/empty', () {
      expect(Validators.phoneError('8104740020'), isNull);
      expect(Validators.phoneError('+91 81047 40020'), isNull);
      expect(Validators.phoneError(''), isNotNull);
      expect(Validators.phoneError('12345'), isNotNull);
      expect(Validators.phoneError('1234567890123456'), isNotNull);
    });

    test('formatter blocks letters while typing', () {
      expect(_typed(Validators.phoneFormatters, '81abc047'), '81047');
      expect(_typed(Validators.phoneFormatters, '+91-810'), '+91-810');
    });
  });
}
