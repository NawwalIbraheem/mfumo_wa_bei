import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      '/auth/login/',
      {
        'email': email,
        'password': password,
      },
    );
    return _extractData(response);
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _post(
      '/auth/register/',
      {
        'full_name': fullName,
        'phone_number': phoneNumber,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    return _extractData(response);
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String identifier,
  }) async {
    final response = await _post(
      '/auth/password-reset-request/',
      {
        'identifier': identifier,
      },
    );
    return _extractData(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    final jsonBody = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    throw ApiException(_readError(jsonBody));
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return payload;
  }

  String _readError(Map<String, dynamic> payload) {
    final message = payload['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    for (final value in payload.values) {
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      if (value is String && value.isNotEmpty) {
        return value;
      }
      if (value is Map<String, dynamic>) {
        for (final nested in value.values) {
          if (nested is List && nested.isNotEmpty) {
            return nested.first.toString();
          }
          if (nested is String && nested.isNotEmpty) {
            return nested;
          }
        }
      }
    }

    return 'Kuna hitilafu imetokea. Jaribu tena.';
  }
}
