import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WorkspaceException implements Exception {
  final String message;
  const WorkspaceException(this.message);
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

  Future<Map<String, dynamic>> _send(String method, String path,
      {Map<String, String>? query, Object? data, Uint8List? photo}) async {
    final request = http.Request(
        method, baseUri.resolve(path).replace(queryParameters: query));
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
        throw WorkspaceException(body['detail'] is String
            ? body['detail']
            : 'The request could not be completed. Please retry.');
      }
      return body;
    } on WorkspaceException {
      rethrow;
    } catch (_) {
      throw const WorkspaceException(
          'Local service could not be reached. Start the Kissan Konnect service, check the connection, and retry.');
    }
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
