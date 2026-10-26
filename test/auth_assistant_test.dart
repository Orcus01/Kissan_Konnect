import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kissan_konnect/auth/auth_page.dart';
import 'package:kissan_konnect/core/app_theme.dart';
import 'package:kissan_konnect/services/workspace_api.dart';
import 'package:kissan_konnect/workspace/assistant_page.dart';

class FormApi extends WorkspaceApi {
  String? action;
  Map<String, dynamic>? submitted;
  @override
  Future<Map<String, dynamic>> authenticate(
      String action, Map<String, dynamic> data) async {
    this.action = action;
    submitted = data;
    if (action == 'recover') return {'reset_sent': true};
    throw const WorkspaceException('Check your email and password.');
  }
}

void main() {
  testWidgets('Phone login fits without layout overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FormApi();
    addTearDown(api.close);
    await tester
        .pumpWidget(MaterialApp(theme: appTheme, home: AuthPage(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Signup validates confirmation before contacting account service',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = FormApi();
    addTearDown(api.close);
    await tester
        .pumpWidget(MaterialApp(theme: appTheme, home: AuthPage(api: api)));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Grower');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'test@example.test');
    await tester.enterText(
        find.byType(TextFormField).at(2), 'A long test passphrase');
    await tester.enterText(find.byType(TextFormField).at(3), 'different');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(api.action, isNull);
  });
  testWidgets('Password reset asks only for email and reports request result',
      (tester) async {
    final api = FormApi();
    addTearDown(api.close);
    await tester
        .pumpWidget(MaterialApp(theme: appTheme, home: AuthPage(api: api)));
    await tester.tap(find.text('Forgot your password?'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Password'), findsNothing);
    await tester.enterText(find.widgetWithText(TextFormField, 'Email address'),
        'test@example.test');
    await tester.ensureVisible(find.text('Send reset link'));
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(api.action, 'recover');
    expect(api.submitted?['email'], 'test@example.test');
    expect(find.textContaining('check its inbox'), findsOneWidget);
  });
  testWidgets('Assistant sends question and renders a sourced reply',
      (tester) async {
    String? question;
    final api = WorkspaceApi(
        baseUri: Uri.parse('http://localhost/api/'),
        client: MockClient((request) async {
          if (request.method == 'GET')
            return http.Response('{"messages":[]}', 200);
          question = jsonDecode(request.body)['question'];
          return http.Response(
              jsonEncode({
                'answer': 'Check the soil moisture before watering.',
                'crop': 'Tomato',
                'topic': 'water',
                'engine': 'curated-retrieval-v1',
                'sources': [
                  {
                    'title': 'University plant guide',
                    'url':
                        'https://extension.umn.edu/vegetables/growing-tomatoes'
                  }
                ],
                'suggestions': []
              }),
              200);
        }));
    addTearDown(api.close);
    await tester.pumpWidget(MaterialApp(
        theme: appTheme, home: Scaffold(body: AssistantPage(api: api))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('How should I water tomatoes?'));
    await tester.tap(find.text('How should I water tomatoes?'));
    await tester.pumpAndSettle();
    expect(question, 'How should I water tomatoes?');
    expect(find.textContaining('Check the soil moisture'), findsOneWidget);
    expect(find.text('University plant guide'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
