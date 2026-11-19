/// A small, dependency-free, comment/string-aware Dart source scanner.
///
/// Migrations need to find and transform *specific constructs* (a function
/// body, a constructor call) inside a real project's already-customized
/// file, without requiring the whole file to match a known template
/// byte-for-byte. Pulling in `package:analyzer` for this would be a
/// heavyweight dependency for a narrow need (see RULES.md DEP-01..DEP-06);
/// this module instead provides just enough token-awareness -- bracket
/// matching and comment/string-safe token search -- to do that safely.
///
/// Not a full Dart parser: it understands brackets, line/block comments,
/// and string literals (including `${...}` interpolation), which is
/// exactly what's needed to (a) find a function/class body by scanning
/// forward from its opening brace to the matching closing one, and (b)
/// search for an identifier used as a constructor call without matching
/// the same text inside a comment or string.
library;

class UnbalancedSourceException implements Exception {
  const UnbalancedSourceException(this.message);

  final String message;

  @override
  String toString() => message;
}

const _openToClose = {'(': ')', '{': '}', '[': ']'};
const _closeToOpen = {')': '(', '}': '{', ']': '['};

/// Returns the index right after the bracket in [source] that matches the
/// opening bracket at [openIndex] (`(`, `{`, or `[`), skipping over line
/// comments, block comments, and string literals -- `${...}` interpolation
/// inside a string is still real code and contributes to bracket balance.
///
/// Throws [UnbalancedSourceException] if [source] ends before the bracket
/// closes, or if a mismatched closing bracket is found first.
int matchingBracketEnd(String source, int openIndex) {
  final open = source[openIndex];
  if (!_openToClose.containsKey(open)) {
    throw ArgumentError('Not an opening bracket at $openIndex: "$open"');
  }

  final stack = <String>[open];
  var index = openIndex + 1;
  final length = source.length;

  while (index < length) {
    final char = source[index];

    if (char == '/' && index + 1 < length && source[index + 1] == '/') {
      index = _skipLineComment(source, index);
      continue;
    }
    if (char == '/' && index + 1 < length && source[index + 1] == '*') {
      index = _skipBlockComment(source, index);
      continue;
    }
    if (char == "'" || char == '"') {
      index = _skipStringLiteral(source, index);
      continue;
    }
    if (_openToClose.containsKey(char)) {
      stack.add(char);
      index += 1;
      continue;
    }
    if (_closeToOpen.containsKey(char)) {
      if (stack.isEmpty || stack.last != _closeToOpen[char]) {
        throw UnbalancedSourceException(
          'Unexpected "$char" at offset $index while matching brackets.',
        );
      }
      stack.removeLast();
      index += 1;
      if (stack.isEmpty) {
        return index;
      }
      continue;
    }
    index += 1;
  }

  throw UnbalancedSourceException(
    'Unterminated bracket starting at offset $openIndex.',
  );
}

/// Validates that every bracket in [source] is balanced, ignoring brackets
/// inside comments/strings the same way [matchingBracketEnd] does. Used as
/// a final structural sanity check after a migration transforms a file --
/// if this throws, the transformation produced invalid source and must not
/// be written.
void validateBalancedBrackets(String source) {
  final stack = <String>[];
  var index = 0;
  final length = source.length;

  while (index < length) {
    final char = source[index];

    if (char == '/' && index + 1 < length && source[index + 1] == '/') {
      index = _skipLineComment(source, index);
      continue;
    }
    if (char == '/' && index + 1 < length && source[index + 1] == '*') {
      index = _skipBlockComment(source, index);
      continue;
    }
    if (char == "'" || char == '"') {
      index = _skipStringLiteral(source, index);
      continue;
    }
    if (_openToClose.containsKey(char)) {
      stack.add(char);
      index += 1;
      continue;
    }
    if (_closeToOpen.containsKey(char)) {
      if (stack.isEmpty || stack.last != _closeToOpen[char]) {
        throw UnbalancedSourceException(
          'Unexpected "$char" at offset $index while validating brackets.',
        );
      }
      stack.removeLast();
      index += 1;
      continue;
    }
    index += 1;
  }

  if (stack.isNotEmpty) {
    throw UnbalancedSourceException(
      'Unterminated bracket(s) remaining after scanning: ${stack.join(', ')}.',
    );
  }
}

/// Returns a same-length copy of [source] with the *content* of every line
/// comment, block comment, and string literal (excluding `${...}`
/// interpolation, which stays visible as real code, recursively masked the
/// same way) replaced with spaces -- newlines are preserved so offsets and
/// line structure stay intact. Search [source] itself for real spans
/// (start/end offsets are 1:1 with the original), but run pattern matching
/// against this masked copy so a token that only appears inside a comment
/// or string (e.g. a Dartdoc `[MaterialPageRoute]` cross-reference) is
/// never mistaken for real code.
String maskNonCode(String source) => _maskRange(source, 0, source.length);

String _maskRange(String source, int start, int end) {
  final buffer = StringBuffer();
  var index = start;

  while (index < end) {
    final char = source[index];

    if (char == '/' && index + 1 < end && source[index + 1] == '/') {
      final stop = _clamp(_skipLineComment(source, index), end);
      buffer.write(_blank(source, index, stop));
      index = stop;
      continue;
    }
    if (char == '/' && index + 1 < end && source[index + 1] == '*') {
      final stop = _clamp(_skipBlockComment(source, index), end);
      buffer.write(_blank(source, index, stop));
      index = stop;
      continue;
    }
    if (char == "'" || char == '"') {
      final stop = _clamp(_skipStringLiteral(source, index), end);
      buffer.write(_maskStringSpan(source, index, stop));
      index = stop;
      continue;
    }

    buffer.write(char);
    index += 1;
  }

  return buffer.toString();
}

String _maskStringSpan(String source, int quoteIndex, int end) {
  final quote = source[quoteIndex];
  final raw =
      quoteIndex > 0 &&
      (source[quoteIndex - 1] == 'r' || source[quoteIndex - 1] == 'R');
  final isTriple =
      quoteIndex + 2 < source.length &&
      source[quoteIndex + 1] == quote &&
      source[quoteIndex + 2] == quote;
  final delimiter = isTriple ? quote * 3 : quote;

  final buffer = StringBuffer()
    ..write(_blank(source, quoteIndex, quoteIndex + delimiter.length));
  var index = quoteIndex + delimiter.length;

  while (index < end) {
    if (!raw && source[index] == r'\' && index + 1 < end) {
      buffer.write(_blank(source, index, index + 2));
      index += 2;
      continue;
    }
    if (!raw &&
        source[index] == r'$' &&
        index + 1 < end &&
        source[index + 1] == '{') {
      final braceStart = index + 1;
      final int braceEnd;
      try {
        braceEnd = matchingBracketEnd(source, braceStart);
      } on UnbalancedSourceException {
        buffer.write(_blank(source, index, end));
        return buffer.toString();
      }
      buffer
        ..write(r'$')
        ..write(_maskRange(source, braceStart, braceEnd));
      index = braceEnd;
      continue;
    }
    if (source.startsWith(delimiter, index)) {
      buffer.write(_blank(source, index, index + delimiter.length));
      index += delimiter.length;
      return buffer.toString();
    }
    buffer.write(source[index] == '\n' ? '\n' : ' ');
    index += 1;
  }

  buffer.write(_blank(source, index, end));
  return buffer.toString();
}

int _clamp(int value, int max) => value > max ? max : value;

String _blank(String source, int start, int end) {
  final buffer = StringBuffer();
  for (var i = start; i < end; i += 1) {
    buffer.write(source[i] == '\n' ? '\n' : ' ');
  }
  return buffer.toString();
}

int _skipLineComment(String source, int index) {
  final newline = source.indexOf('\n', index);
  return newline == -1 ? source.length : newline + 1;
}

int _skipBlockComment(String source, int index) {
  final end = source.indexOf('*/', index + 2);
  return end == -1 ? source.length : end + 2;
}

/// Skips a string literal starting at [quoteIndex] (a `'` or `"`),
/// including a `r`/`R` raw prefix (detected from the preceding character),
/// triple-quoted strings, escapes, and `${...}` interpolation (which
/// recurses through [matchingBracketEnd] since it can contain arbitrary
/// nested code). Returns [source.length] if unterminated.
int _skipStringLiteral(String source, int quoteIndex) {
  final quote = source[quoteIndex];
  final raw =
      quoteIndex > 0 &&
      (source[quoteIndex - 1] == 'r' || source[quoteIndex - 1] == 'R');
  final isTriple =
      quoteIndex + 2 < source.length &&
      source[quoteIndex + 1] == quote &&
      source[quoteIndex + 2] == quote;
  final delimiter = isTriple ? quote * 3 : quote;
  var index = quoteIndex + delimiter.length;
  final length = source.length;

  while (index < length) {
    if (!raw && source[index] == r'\' && index + 1 < length) {
      index += 2;
      continue;
    }
    if (!raw &&
        source[index] == r'$' &&
        index + 1 < length &&
        source[index + 1] == '{') {
      try {
        index = matchingBracketEnd(source, index + 1);
      } on UnbalancedSourceException {
        return length;
      }
      continue;
    }
    if (source.startsWith(delimiter, index)) {
      return index + delimiter.length;
    }
    index += 1;
  }
  return length;
}

/// A `[start, end)` span of real (non-comment, non-string) source text.
typedef SourceSpan = (int start, int end);

/// Finds every top-level *constructor invocation* of [className] within
/// `source[start, end)` -- the identifier [className], as a whole word,
/// optionally followed by a generic argument list (`<...>`), immediately
/// followed by `(` -- and returns each occurrence's identifier span
/// (`className` itself, not the call's arguments).
///
/// Searches a [maskNonCode]-masked copy of `source[start, end)` so an
/// occurrence inside a comment or string literal (for example a Dartdoc
/// `[$className]` cross-reference) is never matched.
List<SourceSpan> findConstructorIdentifierSpans(
  String source,
  String className, {
  int start = 0,
  int? end,
}) {
  final rangeEnd = end ?? source.length;
  final masked = _maskRange(source, start, rangeEnd);
  final pattern = RegExp(r'\b' + RegExp.escape(className) + r'\b');
  final spans = <SourceSpan>[];

  for (final match in pattern.allMatches(masked)) {
    var index = match.end;
    while (index < masked.length && _isBlank(masked[index])) {
      index += 1;
    }
    if (index < masked.length && masked[index] == '<') {
      final closeIndex = _matchAngleBrackets(masked, index);
      if (closeIndex == null) {
        continue;
      }
      index = closeIndex;
      while (index < masked.length && _isBlank(masked[index])) {
        index += 1;
      }
    }
    if (index < masked.length && masked[index] == '(') {
      spans.add((match.start + start, match.end + start));
    }
  }

  return spans;
}

/// Whether [source] contains [pattern] outside any comment or string
/// literal within `source[start, end)`.
bool containsOutsideCommentsAndStrings(
  String source,
  Pattern pattern, {
  int start = 0,
  int? end,
}) {
  final rangeEnd = end ?? source.length;
  final masked = _maskRange(source, start, rangeEnd);
  return masked.contains(pattern);
}

bool _isBlank(String char) => char == ' ' || char == '\n' || char == '\t';

/// Matches a `<...>` generic argument list starting at [ltIndex] (which
/// must be `<`) by simple depth counting -- safe here because this is only
/// ever called immediately after an identifier in call position, where the
/// content can only be type syntax (no `<=`/`>=` comparisons to worry
/// about). Returns `null` (treat as "not actually a generic") if a
/// statement/block delimiter is seen before the angle brackets balance.
int? _matchAngleBrackets(String text, int ltIndex) {
  var depth = 0;
  var index = ltIndex;
  while (index < text.length) {
    final char = text[index];
    if (char == '<') {
      depth += 1;
      index += 1;
      continue;
    }
    if (char == '>') {
      depth -= 1;
      index += 1;
      if (depth == 0) {
        return index;
      }
      continue;
    }
    if (char == ';' || char == '{' || char == '}') {
      return null;
    }
    index += 1;
  }
  return null;
}
