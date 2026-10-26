import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/firebase_setup.dart';

class WorkspaceException implements Exception {
  final String message;
  final int? statusCode;
  const WorkspaceException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class WorkspaceApi {
  WorkspaceApi({http.Client? client, Uri? baseUri})
      : _client = client ?? http.Client(),
        baseUri = baseUri ??
            (kIsWeb
                ? Uri.base.resolve('/api/')
                : Uri.parse(
                    '${const String.fromEnvironment('KISSAN_SERVICE_URL', defaultValue: 'http://127.0.0.1:8765')}/api/'));
  final http.Client _client;
  final Uri baseUri;
  final ValueNotifier<Map<String, dynamic>?> user = ValueNotifier(null);
  String? _token;
  Map<String, String>? get imageHeaders =>
      _token == null ? null : {'Authorization': 'Bearer $_token'};

  Future<Map<String, dynamic>> _send(String method, String path,
      {Map<String, String>? query, Object? data, Uint8List? photo}) async {
    final request = http.Request(
        method, baseUri.resolve(path).replace(queryParameters: query));
    request.headers['X-Kissan-Client'] = kIsWeb ? 'web' : 'native';
    if (FirebaseSetup.ready && FirebaseAuth.instance.currentUser != null) {
      final previousToken = _token;
      _token = await FirebaseAuth.instance.currentUser!.getIdToken();
      if (kIsWeb && _token != previousToken && path != 'auth/session') {
        await _send('POST', 'auth/session', data: {'id_token': _token});
      }
    }
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    if (photo != null) {
      request.headers['Content-Type'] = 'application/octet-stream';
      request.bodyBytes = photo;
    } else if (data != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(data);
    }
    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 45));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) throw const FormatException();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401 && user.value != null) user.value = null;
        throw WorkspaceException(
            body['detail'] is String
                ? body['detail']
                : 'The request could not be completed. Please retry.',
            statusCode: response.statusCode);
      }
      return body;
    } on WorkspaceException {
      rethrow;
    } catch (_) {
      throw const WorkspaceException(
          'Local service could not be reached. Start the Kissan Konnect service, check the connection, and retry.');
    }
  }

  Future<void> restoreSession() async {
    if (!FirebaseSetup.ready) {
      user.value = null;
      return;
    }
    final account = await FirebaseAuth.instance.authStateChanges().first;
    if (account == null) {
      user.value = null;
      return;
    }
    await _exchange();
  }

  Future<Map<String, dynamic>> _exchange() async {
    _token = await FirebaseAuth.instance.currentUser!.getIdToken(true);
    final response =
        await _send('POST', 'auth/session', data: {'id_token': _token});
    user.value = Map<String, dynamic>.from(response['user']);
    return response;
  }

  Future<Map<String, dynamic>> authenticate(
      String action, Map<String, dynamic> data) async {
    if (!FirebaseSetup.ready) {
      throw const WorkspaceException(
          'Firebase accounts need the dedicated Kissan Konnect project configuration.');
    }
    try {
      final auth = FirebaseAuth.instance;
      if (action == 'recover') {
        await auth.sendPasswordResetEmail(email: data['email']);
        return {'reset_sent': true};
      }
      if (action == 'signup') {
        final credential = await auth.createUserWithEmailAndPassword(
            email: data['email'], password: data['password']);
        await credential.user!.updateDisplayName(data['name']);
      } else {
        await auth.signInWithEmailAndPassword(
            email: data['email'], password: data['password']);
      }
      return await _exchange();
    } on FirebaseAuthException catch (e) {
      throw WorkspaceException(switch (e.code) {
        'email-already-in-use' =>
          'This email already has an account. Sign in instead.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Check your email and password.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'operation-not-allowed' =>
          'Email and password accounts must be enabled in the personal Firebase project.',
        'weak-password' => 'Choose a stronger password.',
        _ => e.message ?? 'Sign in could not be completed.'
      });
    }
  }

  void acceptUser(Map<String, dynamic> account) => user.value = account;
  Future<void> signOut() async {
    try {
      await _send('POST', 'auth/logout');
    } finally {
      if (FirebaseSetup.ready) await FirebaseAuth.instance.signOut();
      _token = null;
      user.value = null;
    }
  }

  Future<void> updateName(String name) async {
    await FirebaseAuth.instance.currentUser!.updateDisplayName(name);
    await _exchange();
  }

  Future<Map<String, dynamic>> stats() => _send('GET', 'stats');
  Future<List<Map<String, dynamic>>> messages() async =>
      List<Map<String, dynamic>>.from((await _send('GET', 'chat'))['messages']);
  Future<Map<String, dynamic>> ask(String question, {String? crop}) =>
      _send('POST', 'chat', data: {'question': question, 'crop': crop});
  Future<void> clearChat() async {
    await _send('DELETE', 'chat');
  }

  Future<Map<String, dynamic>> model() => _send('GET', 'model');
  Future<Map<String, dynamic>> predict(Uint8List photo, String crop) =>
      _send('POST', 'predict', query: {'crop': crop}, photo: photo);
  Future<List<Map<String, dynamic>>> scans() async =>
      List<Map<String, dynamic>>.from((await _send('GET', 'scans'))['scans']);
  Future<void> save(String id, String notes) async {
    await _send('POST', 'scans', data: {'prediction_id': id, 'notes': notes});
  }

  Future<void> update(String id, String notes) async {
    await _send('PATCH', 'scans/$id', data: {'notes': notes});
  }

  Future<void> delete(String id) async {
    await _send('DELETE', 'scans/$id');
  }

  Future<Map<String, dynamic>> locations(String city) =>
      _send('GET', 'weather', query: {'city': city});
  Future<Map<String, dynamic>> forecast(num lat, num lon) =>
      _send('GET', 'forecast',
          query: {'latitude': '$lat', 'longitude': '$lon'});
  String imageUrl(String path) => baseUri.resolve(path).toString();
  void close() => _client.close();
}

final workspaceApi = WorkspaceApi();
