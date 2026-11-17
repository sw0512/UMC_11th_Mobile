import 'dart:io';
import 'dart:convert';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory(
    Platform.environment['WEEK8_EVIDENCE_DIR'] ?? 'artifacts/week8',
  );
  await output.create(recursive: true);
  await integrationDriver(
    writeResponseOnFailure: true,
    onScreenshot: (name, bytes, [args]) async {
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      if (data != null) {
        await File('${output.path}/native-report.json').writeAsString(
          const JsonEncoder.withIndent('  ').convert(data['evidence']),
        );
      }
    },
  );
}
