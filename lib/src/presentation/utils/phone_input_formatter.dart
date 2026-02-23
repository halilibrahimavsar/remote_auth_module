import 'package:flutter/services.dart';

/// A [TextInputFormatter] that applies a regional mask to a phone number.
///
/// Example:
/// - Mask: '000-000-00-00'
/// - Input: '5551234455'
/// - Output: '555-123-44-55'
class PhoneInputFormatter extends TextInputFormatter {
  final String mask;
  final String separator;

  PhoneInputFormatter({required this.mask, this.separator = '-'});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Strip all non-digits from the new value
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // 2. Apply mask
    final result = StringBuffer();
    int digitIndex = 0;

    for (int i = 0; i < mask.length && digitIndex < digitsOnly.length; i++) {
      if (mask[i] == '0') {
        result.write(digitsOnly[digitIndex]);
        digitIndex++;
      } else {
        result.write(mask[i]);
      }
    }

    final formattedText = result.toString();

    // 3. Maintain cursor position logic (basic implementation)
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
