import 'package:cuboid/src/migrate/dart_source_scanner.dart';
import 'package:test/test.dart';

void main() {
  group('matchingBracketEnd', () {
    test('matches a simple paren pair', () {
      const source = 'foo(bar)';
      expect(matchingBracketEnd(source, 3), source.length);
    });

    test('matches nested brackets of different kinds', () {
      const source = 'f({"a": [1, 2, (3)]})';
      expect(matchingBracketEnd(source, 1), source.length);
    });

    test('skips brackets inside a line comment', () {
      const source = '{ // ) not a real close\n}';
      expect(matchingBracketEnd(source, 0), source.length);
    });

    test('skips brackets inside a block comment', () {
      const source = '{ /* ) still not real */ }';
      expect(matchingBracketEnd(source, 0), source.length);
    });

    test('skips brackets inside a single-quoted string', () {
      const source = "{ 'text with ) inside' }";
      expect(matchingBracketEnd(source, 0), source.length);
    });

    test('skips brackets inside a double-quoted string', () {
      const source = '{ "text with } inside" }';
      expect(matchingBracketEnd(source, 0), source.length);
    });

    test('skips brackets inside a triple-quoted string', () {
      const source = "{ '''multi\nline with } and )''' }";
      expect(matchingBracketEnd(source, 0), source.length);
    });

    test('does not treat a raw string escape specially', () {
      const source = r"{ r'\}' }";
      expect(matchingBracketEnd(source, 0), source.length);
    });

    test('honors backslash escapes inside a normal string', () {
      const source = r"{ 'escaped quote \' still inside' }";
      expect(matchingBracketEnd(source, 0), source.length);
    });

    test('counts brackets inside string interpolation as real code', () {
      const source = r"{ 'value: ${f(1, 2)}' }";
      expect(matchingBracketEnd(source, 0), source.length);
    });

    test('throws on an unterminated bracket', () {
      expect(
        () => matchingBracketEnd('{ foo(', 0),
        throwsA(isA<UnbalancedSourceException>()),
      );
    });

    test('throws on a mismatched closing bracket', () {
      expect(
        () => matchingBracketEnd('{ (]', 0),
        throwsA(isA<UnbalancedSourceException>()),
      );
    });
  });

  group('validateBalancedBrackets', () {
    test('accepts well-formed source', () {
      expect(
        () => validateBalancedBrackets('class A { void f() { return; } }'),
        returnsNormally,
      );
    });

    test('accepts brackets that only appear inside comments/strings', () {
      expect(
        () => validateBalancedBrackets(
          "class A { // ) mismatched in a comment\n  String s = '}'; }",
        ),
        returnsNormally,
      );
    });

    test('throws on a missing closing brace', () {
      expect(
        () => validateBalancedBrackets('class A { void f() {'),
        throwsA(isA<UnbalancedSourceException>()),
      );
    });

    test('throws on a stray unmatched closing brace', () {
      expect(
        () => validateBalancedBrackets('class A { } }'),
        throwsA(isA<UnbalancedSourceException>()),
      );
    });
  });

  group('maskNonCode', () {
    test('preserves length', () {
      const source = 'foo(/* comment */ "string", bar)';
      expect(maskNonCode(source).length, source.length);
    });

    test('blanks line comments but keeps newlines', () {
      const source = 'a // MaterialPageRoute\nb';
      final masked = maskNonCode(source);
      expect(masked, isNot(contains('MaterialPageRoute')));
      expect(masked.split('\n').length, 2);
    });

    test('blanks block comments', () {
      const source = 'a /* MaterialPageRoute */ b';
      expect(maskNonCode(source), isNot(contains('MaterialPageRoute')));
    });

    test('blanks string literal content', () {
      const source = "a 'MaterialPageRoute' b";
      expect(maskNonCode(source), isNot(contains('MaterialPageRoute')));
    });

    test('blanks Dartdoc cross-references like [MaterialPageRoute]', () {
      const source = '/// via [MaterialPageRoute], for views...';
      expect(maskNonCode(source), isNot(contains('MaterialPageRoute')));
    });

    test('keeps string interpolation code visible', () {
      const source = r"'${MaterialPageRoute(builder: b)}'";
      expect(maskNonCode(source), contains('MaterialPageRoute'));
    });
  });

  group('findConstructorIdentifierSpans', () {
    String applyRename(String source, String from, String to) {
      var result = source;
      for (final span in findConstructorIdentifierSpans(
        source,
        from,
      ).reversed) {
        result = result.replaceRange(span.$1, span.$2, to);
      }
      return result;
    }

    test('finds a plain constructor call', () {
      const source = 'return MaterialPageRoute(builder: b, settings: s);';
      final spans = findConstructorIdentifierSpans(source, 'MaterialPageRoute');
      expect(spans, hasLength(1));
      expect(
        source.substring(spans.single.$1, spans.single.$2),
        'MaterialPageRoute',
      );
    });

    test('finds a generic constructor call', () {
      const source = 'return MaterialPageRoute<dynamic>(builder: b);';
      final spans = findConstructorIdentifierSpans(source, 'MaterialPageRoute');
      expect(spans, hasLength(1));
    });

    test('does not match a Dartdoc cross-reference', () {
      const source = '/// via [MaterialPageRoute], for views that...';
      expect(
        findConstructorIdentifierSpans(source, 'MaterialPageRoute'),
        isEmpty,
      );
    });

    test('does not match a mention inside a string literal', () {
      const source = "final s = 'MaterialPageRoute(builder: b)';";
      expect(
        findConstructorIdentifierSpans(source, 'MaterialPageRoute'),
        isEmpty,
      );
    });

    test('does not match the bare identifier with no call', () {
      const source = 'final Type t = MaterialPageRoute;';
      expect(
        findConstructorIdentifierSpans(source, 'MaterialPageRoute'),
        isEmpty,
      );
    });

    test('finds multiple occurrences across a function body', () {
      const source = '''
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  if (settings.name == Routes.detail) {
    return MaterialPageRoute<dynamic>(builder: (_) => const Detail(), settings: settings);
  }
  final builder = appRoutes[settings.name];
  if (builder == null) return null;
  return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
}
''';
      final spans = findConstructorIdentifierSpans(source, 'MaterialPageRoute');
      expect(spans, hasLength(2));
    });

    test(
      'renaming preserves everything else exactly, including a custom branch',
      () {
        const source = '''
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  if (settings.name == Routes.detail) {
    return MaterialPageRoute<dynamic>(builder: (_) => const Detail(), settings: settings);
  }
  final builder = appRoutes[settings.name];
  if (builder == null) return null;
  return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
}
''';
        final renamed = applyRename(
          source,
          'MaterialPageRoute',
          'CuboidPageRoute',
        );
        expect(renamed, isNot(contains('MaterialPageRoute')));
        expect(renamed, contains('if (settings.name == Routes.detail) {'));
        expect(
          renamed,
          contains(
            'CuboidPageRoute<dynamic>(builder: (_) => const Detail(), settings: settings);',
          ),
        );
        expect(
          renamed,
          contains(
            'CuboidPageRoute<dynamic>(builder: builder, settings: settings);',
          ),
        );
      },
    );
  });

  group('containsOutsideCommentsAndStrings', () {
    test('finds real code matches', () {
      expect(
        containsOutsideCommentsAndStrings(
          'void navigateToView() {}',
          'navigateToView',
        ),
        isTrue,
      );
    });

    test('ignores matches only present in comments', () {
      expect(
        containsOutsideCommentsAndStrings(
          '// navigateToView is missing',
          'navigateToView',
        ),
        isFalse,
      );
    });
  });
}
