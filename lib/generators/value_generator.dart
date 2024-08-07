import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:resources_generator/util/extensions/file_ext.dart';
import 'package:resources_generator/util/filename_util.dart';
import 'package:resources_generator/util/logger.dart';
import 'package:resources_generator/util/sort_algorithm.dart';

void generateValueResources({
  required String input,
  required String output,
  String? package,
  String? flavor,
}) {
  Logger.verboseLog('Generating value resources...');
  final directory = Directory(input);
  if (!directory.existsSync()) {
    Logger.verboseLog('values/ folder is not exist. Skipping...');
    return;
  }
  final buffer = StringBuffer(
    """
// ignore_for_file: non_constant_identifier_names, constant_identifier_names
part of '${flavor == null ? '' : '../'}resources.dart';

const _${flavor == null ? '' : '${flavor}_'}value_resources = (\n""",
  );
  try {
    final files = directory
        .listSync()
        .where(
          (element) =>
              element is File &&
              extension(element.unixPath) == '.json' &&
              !element.isHidden,
        )
        .cast<File>()
        .toList()
      ..sort(sortFilesByName);
    for (final file in files) {
      final line = file.readAsStringSync();
      final object = json.decode(line);
      buffer.write('  ${safeName(basenameWithoutExtension(file.unixPath))}: ');
      if (object is Map) {
        _genMap(buffer, 4, object.map((key, value) => MapEntry(key, value)));
      }
      buffer.write(',\n');
    }
  } catch (_) {}
  buffer.writeln(');');
  Directory(join(output, flavor)).createSync(recursive: true);
  File(joinAll([output, flavor, 'value_resources.dart'].whereType<String>()))
    ..createSync()
    ..writeAsStringSync(buffer.toString());
  Logger.verboseLog('Generated values resources!');
}

String _generateIndent(int length) {
  final result = StringBuffer();
  for (int i = 0; i < length; i++) {
    result.write(' ');
  }
  return result.toString();
}

void _genMap(StringBuffer buffer, int indent, Map<String, dynamic> map) {
  buffer.write('(\n');
  for (final entry in map.entries) {
    buffer.write('${_generateIndent(indent)}${safeName(entry.key)}: ');
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
  buffer.write('${_generateIndent(indent)}$value');
}
