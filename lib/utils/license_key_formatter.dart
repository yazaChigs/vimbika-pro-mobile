import 'package:flutter/services.dart';

/// Formatter that automatically groups entered keys into blocks of [groupSize]
/// separated by [separator] (e.g. ABCD-1234-EFGH-5678).
class LicenseKeyInputFormatter extends TextInputFormatter {
  final int groupSize;
  final String separator;
  final int? maxCharacters;

  LicenseKeyInputFormatter({
    this.groupSize = 4,
    this.separator = '-',
    this.maxCharacters = 16,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final String oldText = oldValue.text;
    final String newText = newValue.text;
    final bool isDeleting = newText.length < oldText.length;

    // Handle backspace when the previous text ended with separator and user deleted the separator.
    // Deleting the separator also deletes the character immediately preceding it for a natural UX.
    if (isDeleting && oldText.endsWith(separator) && newText == oldText.substring(0, oldText.length - 1)) {
      final stripped = newText.isNotEmpty ? newText.substring(0, newText.length - 1) : '';
      String clean = stripped.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      if (maxCharacters != null && clean.length > maxCharacters!) {
        clean = clean.substring(0, maxCharacters!);
      }
      final formatted = _formatCleanText(clean, appendTrailingSeparator: false);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // Count how many alphanumeric characters exist before the cursor in newValue
    final int selectionEnd = newValue.selection.end;
    int rawCursorPos = 0;
    for (int i = 0; i < selectionEnd && i < newText.length; i++) {
      if (RegExp(r'[A-Za-z0-9]').hasMatch(newText[i])) {
        rawCursorPos++;
      }
    }

    // Clean all non-alphanumeric characters and convert to uppercase
    String cleanText = newText.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (maxCharacters != null && cleanText.length > maxCharacters!) {
      cleanText = cleanText.substring(0, maxCharacters!);
    }
    if (maxCharacters != null && rawCursorPos > maxCharacters!) {
      rawCursorPos = maxCharacters!;
    }

    // Determine whether to append trailing separator
    final bool isAtEnd = rawCursorPos == cleanText.length;
    final bool atGroupBoundary = cleanText.isNotEmpty && (cleanText.length % groupSize == 0);
    final bool isBeforeMax = maxCharacters == null || cleanText.length < maxCharacters!;
    final bool shouldAppendTrailing = !isDeleting && isAtEnd && atGroupBoundary && isBeforeMax;

    final String formattedText = _formatCleanText(
      cleanText,
      appendTrailingSeparator: shouldAppendTrailing,
    );

    // Calculate new cursor position
    int newCursorPos = 0;
    int alphanumericCount = 0;
    for (int i = 0; i < formattedText.length; i++) {
      if (alphanumericCount == rawCursorPos) {
        newCursorPos = i;
        break;
      }
      if (RegExp(r'[A-Za-z0-9]').hasMatch(formattedText[i])) {
        alphanumericCount++;
      }
      if (alphanumericCount == rawCursorPos) {
        newCursorPos = i + 1;
        break;
      }
    }

    if (shouldAppendTrailing && isAtEnd) {
      newCursorPos = formattedText.length;
    } else if (rawCursorPos >= cleanText.length) {
      newCursorPos = formattedText.length;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }

  String _formatCleanText(String clean, {required bool appendTrailingSeparator}) {
    if (clean.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % groupSize == 0) {
        buffer.write(separator);
      }
      buffer.write(clean[i]);
    }
    if (appendTrailingSeparator && !buffer.toString().endsWith(separator)) {
      buffer.write(separator);
    }
    return buffer.toString();
  }
}
