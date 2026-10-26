import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kissan_konnect/core/app_theme.dart';
import 'package:kissan_konnect/page/output_page.dart';
import 'package:kissan_konnect/services/workspace_api.dart';
import 'package:kissan_konnect/workspace/workspace_page.dart';

final result = <String, dynamic>{
  'id': 'test-scan',
  'status': 'candidate',
  'selected_crop': 'Potato',
  'created_at': '2026-10-25T12:00:00Z',
  'elapsed_ms': 20,
  'model_name': 'Test model',
  'model_version': 'd76fe187be1c4c3a',
  'model_source': 'https://example.test/model',
  'candidates': [
    {'crop': 'Potato', 'condition': 'Early blight', 'score': .9},
    {'crop': 'Tomato', 'condition': 'Healthy', 'score': .06},
    {'crop': 'Bell pepper', 'condition': 'Healthy', 'score': .02},
  ],
};

WorkspaceApi mockApi([Future<http.Response> Function(http.Request)? handler]) =>
    WorkspaceApi(
      baseUri: Uri.parse('http://localhost/api/'),
      client: MockClient(handler ??
          (request) async {
            if (request.url.path == '/api/model')
              return http.Response(
                  jsonEncode({
                    'ready': true,
                    'name': 'Test model',
                    'version': 'test',
                    'license': 'MIT',
                    'classes': []
                  }),
                  200);
            if (request.url.path.endsWith('stats')) return http.Response('{"saved_scans":0,"crops":[]}',200);
            if (request.url.path.endsWith('chat')) return http.Response('{"messages":[]}',200);
            return http.Response('{"scans":[]}', 200);
          }),
    );

void main() {
  testWidgets('Workspace runs without Firebase and has working navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = mockApi();
    addTearDown(api.close);
    await tester.pumpWidget(
        MaterialApp(theme: appTheme, home: WorkspacePage(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Model ready'), findsOneWidget);
    await tester.tap(find.text('Scan').first);
    await tester.pumpAndSettle();
    expect(find.text('Try a sample leaf'), findsOneWidget);
    await tester.tap(find.text('Notebook'));
    await tester.pumpAndSettle();
    expect(find.text('No saved scans yet.'), findsOneWidget);
    await tester.tap(find.text('Crop guide'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'pepper');
    await tester.pumpAndSettle();
    expect(find.text('Bacterial spot'), findsOneWidget);
    expect(find.text('Early blight'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile layout fits and offers all navigation destinations',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = mockApi();
    addTearDown(api.close);
    await tester.pumpWidget(
        MaterialApp(theme: appTheme, home: WorkspacePage(api: api)));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weather'));
    await tester.pumpAndSettle();
    expect(find.text('Start with a city.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unavailable service never shows model ready', (tester) async {
    final api = mockApi(
        (_) async => http.Response('{"detail":"Service offline"}', 503));
    addTearDown(api.close);
    await tester.pumpWidget(
        MaterialApp(theme: appTheme, home: WorkspacePage(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Model ready'), findsNothing);
    expect(find.text('Service offline'), findsOneWidget);
  });

  testWidgets(
      'Review runs only on request and saves the returned prediction with notes',
      (tester) async {
    var predictions = 0;
    var saves = 0;
    final api = mockApi((request) async {
      if (request.url.path.endsWith('predict')) {
        predictions++;
        expect(request.url.queryParameters['crop'], 'Potato');
        expect(request.bodyBytes.length, greaterThan(100));
        return http.Response(jsonEncode(result), 200);
      }
      saves++;
      expect(jsonDecode(request.body),
          {'prediction_id': 'test-scan', 'notes': 'Lower leaves, plot A'});
      return http.Response('{"saved":true}', 200);
    });
    addTearDown(api.close);
    final bytes =
        (await rootBundle.load('assets/samples/potato_early_blight.jpg'))
            .buffer
            .asUint8List();
    await tester.pumpWidget(MaterialApp(
        theme: appTheme,
        home: OutputPage(imageBytes: bytes, crop: 'Potato', api: api)));
    await tester.pumpAndSettle();
    expect(predictions, 0);
    expect(find.text('Top model matches'), findsNothing);
    await tester.scrollUntilVisible(find.text('Run leaf screening'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Run leaf screening'));
    await tester.pumpAndSettle();
    expect(predictions, 1);
    expect(saves, 0);
    expect(find.text('Potato · Early blight'), findsWidgets);
    await tester.scrollUntilVisible(find.byType(TextField), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField), 'Lower leaves, plot A');
    await tester.scrollUntilVisible(find.text('Save photo and notes'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save photo and notes'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(find.text('Saved to notebook'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
