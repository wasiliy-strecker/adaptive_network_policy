import 'dart:io';

const _generatedNativeFiles = <String>[
  'android/src/main/kotlin/dev/wasiliy/adaptive_network_policy/'
      'NetworkConditionsApi.g.kt',
  'darwin/adaptive_network_policy/Sources/adaptive_network_policy/'
      'NetworkConditionsApi.g.swift',
];

void main() {
  for (final path in _generatedNativeFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('Missing generated file: $path');
      exitCode = 1;
      continue;
    }

    final lines = file.readAsStringSync().split('\n');
    while (lines.isNotEmpty && lines.last.trim().isEmpty) {
      lines.removeLast();
    }
    file.writeAsStringSync(
      '${lines.map((line) => line.trimRight()).join('\n')}\n',
    );
  }
}
