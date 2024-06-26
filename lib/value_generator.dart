import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

void generateValueResources({
  required String input,
  required String output,
  String? package,
}) {
  print('Generating value resources...');
  final directory = Directory(input);
  if (!directory.existsSync()) {
    print('values/ folder is not exist. Skipping...');
    return;
  }
  final buffer = StringBuffer(
    """// ignore_for_file: non_constant_identifier_names
part of 'resources.dart';

const _valueResources = (\n""",
  );
  try {
    final files = directory
        .listSync()
        .where(
          (element) => element is File && extension(element.path) == '.json',
        )
        .cast<File>()
        .toList()
      ..sort((a, b) => basename(a.path).compareTo(basename(b.path)));
    for (var file in files) {
      final line = file.readAsStringSync();
      final object = json.decode(line);
      buffer.write('  ${basenameWithoutExtension(file.path)}: ');
      if (object is Map) {
        _genMap(buffer, 4, object.map((key, value) => MapEntry(key, value)));
      }
      buffer.write(',\n');
    }
  } catch (_) {}
  buffer.writeln(');');
  Directory(output).createSync(recursive: true);
  File('$output/value_resources.dart')
    ..createSync()
    ..writeAsStringSync(buffer.toString());
  print('Generated values resources!');
}

String _generateIndent(int length) {
  String result = '';
  for (int i = 0; i < length; i++) {
    result += ' ';
  }
  return result;
}

void _genMap(StringBuffer buffer, int indent, Map<String, dynamic> map) {
  buffer.write('(\n');
  for (final entry in map.entries) {
    buffer.write("${_generateIndent(indent)}${entry.key}: ");
    if (entry.value is List) {
      _genList(buffer, indent + 2, entry.value);
    } else if (entry.value is Map) {
      _genMap(buffer, indent + 2, entry.value);
    } else if (entry.value is String) {
      _genString(buffer, 0, entry.value);
    } else {
      _genElse(buffer, 0, entry.value);
    }
    buffer.write(',\n');
  }
  buffer.write('${_generateIndent(indent - 2)})');
}

void _genList(StringBuffer buffer, int indent, List<dynamic> list) {
  buffer.write('[\n');
  for (final value in list) {
    buffer.write(_generateIndent(indent));
    if (value is Map) {
      _genMap(
        buffer,
        indent + 2,
        value.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    } else if (value is List) {
      _genList(buffer, indent + 2, value);
    } else if (value is String) {
      _genString(buffer, 0, value);
    } else {
      _genElse(buffer, 0, value);
    }
    buffer.write(',\n');
  }
  buffer.write('${_generateIndent(indent - 2)}]');
}

void _genString(StringBuffer buffer, int indent, String string) {
  buffer.write("${_generateIndent(indent)}'$string'");
}

void _genElse(StringBuffer buffer, int indent, dynamic value) {
  buffer.write("${_generateIndent(indent)}$value");
}