import 'dart:io';

import 'package:path/path.dart';

void generateFontResources({
  required String input,
  required String output,
  String? package,
}) {
  print('Generating font resources...');
  final directory = Directory(input);
  if (!directory.existsSync()) {
    print('fonts/ folder is not exist. Skipping...');
    return;
  }
  final buffer = StringBuffer("""
// ignore_for_file: non_constant_identifier_names
part of 'resources.dart';

const _fontResources = (
""");
  final files = directory
      .listSync()
      .map((e) {
        if (e is File) {
          if ([
            '.ttf',
            '.otf',
          ].contains(extension(e.path))) {
            return e;
          }
        }
      })
      .whereType<File>()
      .toList()
    ..sort((a, b) => basename(a.path).compareTo(basename(b.path)));
  for (final file in files) {
    buffer.writeln(
      "  ${basenameWithoutExtension(file.path)}: '${package == null ? '' : '$package/'}assets/fonts/${basename(file.path)}',",
    );
  }
  buffer.writeln(');');
  Directory(output).createSync(recursive: true);
  File('$output/font_resources.dart')
    ..createSync()
    ..writeAsStringSync(buffer.toString());
  print('Generated font resources!');
}
