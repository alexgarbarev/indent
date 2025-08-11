import 'dart:convert';

/// Change indentation in a [String] while preserving existing relative
/// indentation.
///
/// For easier usage, see [IndentedString] in string_extensions.dart.
class Indentation {
  const Indentation(this._input);
  final String _input;

  /// Returns the indentation level of [_input].
  ///
  /// An indentation level is determined by finding a non-empty line with the
  /// least amount of leading whitespace.
  ///
  /// For example, with input:
  ///
  ///   Hello
  ///  World
  ///
  /// the indentation level is 1, because the line with " World" has the least
  /// amount of leading whitespace.
  int getLevel() {
    final lines = _processLines();
    return _findCommonIndentationLevel(lines);
  }

  /// Returns [_input] with all extra indentation stripped while preserving
  /// relative indentation.
  ///
  /// For example, the input:
  ///
  ///          Hello
  ///        there
  ///           World
  ///
  /// will become:
  ///
  ///   Hello
  /// there
  ///    World
  ///
  /// Calling [unindent] is equivalent of calling [indent] with the value of 0.
  String unindent() => indent(0);

  /// Returns [_input] with [indentationLevel] applied while preserving relative
  /// indentation.
  ///
  /// For example, the input:
  ///
  ///  Hello
  /// World
  ///
  /// applied with [indentationLevel] of 3 results in:
  ///
  ///     Hello
  ///    World
  ///
  /// If the starting indentation level is higher than [indentationLevel], the
  /// value will be unindented accordingly.
  ///
  /// For example, the input:
  ///
  ///        Hello
  ///       World
  ///
  /// applied with [indentationLevel] of 3 also results in:
  ///
  ///     Hello
  ///    World
  String indent(int indentationLevel) {
    final lines = _processLines();
    final currentIndentationLevel = _findCommonIndentationLevel(lines);
    return _indent(lines, currentIndentationLevel, indentationLevel);
  }

  /// Returns [_input] with indentation level changed by [howMuch].
  ///
  /// For example, the input:
  ///
  ///    Hello
  ///   World
  ///
  /// with [howMuch] of 2 will result in:
  ///
  ///      Hello
  ///     World
  ///
  /// If [howMuch] is negative, the indentation level will be decreased.
  ///
  /// For example, the input:
  ///
  ///    Hello
  ///   World
  ///
  /// with [howMuch] of -2 will result in:
  ///
  ///  Hello
  /// World
  String indentBy(int howMuch) {
    final lines = _processLines();
    final currentIndentationLevel = _findCommonIndentationLevel(lines);
    return _indent(
      lines,
      currentIndentationLevel,
      currentIndentationLevel + howMuch,
    );
  }

  /// Returns [_input], but trims leading whitespace characters followed by the
  /// given [marginPrefix] from each line.
  ///
  /// Also removes the first and last lines if they are blank, i.e. they only
  /// contain whitespace characters.
  ///
  /// For example, given that the [marginPrefix] is "|" (the default), the input:
  ///
  ///       |   Hello
  ///       | there
  ///       |    World
  ///
  /// will become:
  ///
  ///    Hello
  ///  there
  ///     World
  ///
  /// Leaves lines that don't contain [marginPrefix] untouched.
  String trimMargin([String marginPrefix = '|']) {
    if (_inputIsBlank()) return _input;

    final lines = LineSplitter.split(_input);
    final buffer = StringBuffer();
    var i = -1;

    for (final line in lines) {
      i++;

      var result = line;
      final leftTrimmedLine = line.trimLeft();

      if ((i == 0 || i == lines.length - 1) &&
          leftTrimmedLine.trimRight().isEmpty) {
        // If this is the first or the last line, and it's just whitespace, we
        // want to skip it.
        continue;
      }

      if (leftTrimmedLine.length <= line.length) {
        if (leftTrimmedLine.startsWith(marginPrefix)) {
          result = leftTrimmedLine.replaceFirst(marginPrefix, '');
        }
      }

      // Checking for buffer to handle "trim first line whitespace" case
      if (i > 0 && buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.write(result);
    }

    return buffer.toString();
  }

  // Turns the string into _Line classes that contain the indentation level and
  // unindented contents of each line.
  //
  // This is to avoid having to find the indentation level two times per line:
  // first time in the "find common indentation level" loop, and second time
  // in the loop that applies the indentation.
  Iterable<_Line> _processLines() sync* {
    if (_inputIsBlank()) return;

    for (final line in LineSplitter.split(_input)) {
      final indentationMatch = _whitespace.stringMatch(line);
      final indentationLevel =
          indentationMatch != null && indentationMatch.isNotEmpty
              ? indentationMatch.length
              : 0;

      yield _Line(indentationLevel, line.substring(indentationLevel));
    }
  }

  bool _inputIsBlank() => _input.isEmpty || _input.trim().isEmpty;

  int _findCommonIndentationLevel(Iterable<_Line> lines) {
    int? commonIndentationLevel;

    for (final line in lines) {
      // Empty or blank lines do not have indentation.
      if (line.content.isEmpty) continue;

      if (commonIndentationLevel == null ||
          line.indentationLevel < commonIndentationLevel) {
        // If the common indentation level is not found yet, or if we found a
        // smaller level than the previous one, we update it.
        commonIndentationLevel = line.indentationLevel;
      }
    }

    return commonIndentationLevel ?? 0;
  }

  String _indent(
    Iterable<_Line> lines,
    int currentIndentationLevel,
    int desiredIndentationLevel,
  ) {
    final buffer = StringBuffer();
    final lineLastIndex = lines.length - 1;
    var lineIndex = -1;
    for (final line in lines) {
      lineIndex += 1;

      if (line.content.isEmpty) {
        // Do not indent empty lines.
        buffer.writeln();
        continue;
      }

      final diff = line.indentationLevel - currentIndentationLevel;
      final spaces = _indentation * (desiredIndentationLevel + diff);

      buffer
        ..write(spaces)
        ..write(line.content);

      if (lineIndex != lineLastIndex) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}

// A class that holds information about the indentation level and the trimmed
// contents of one line in a string.
//
// Exists for reusing the indentation level information so that it doesn't have
// to be recalculated twice for each line.
class _Line {
  _Line(this.indentationLevel, this.content);
  final int indentationLevel;
  final String content;
}

const _indentation = ' ';
final _whitespace = RegExp(r'^(\s+)');
