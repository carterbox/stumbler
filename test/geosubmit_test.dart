import 'package:flutter_test/flutter_test.dart';

import 'package:stumbler/geosubmit.dart';

void main() {
  test('Convert Reports to Json and back.', () async {
    final report = Report.fromMock();
    print(report);
    final reportJson = report.toJson();
    print(reportJson);
    final reportRecoverd = Report.fromJson(reportJson);
    print(reportRecoverd);
    expect(report, reportRecoverd);
  });
}
