import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfumo_wa_bei/core/network/api_service.dart';

void main() {
  group('ApiService', () {
    test('returns nested data for successful login', () async {
      final service = ApiService(
        client: MockClient((request) async {
          return http.Response(
            '{"data":{"user":{"full_name":"Amina"}}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final data = await service.login(
        email: 'amina@example.com',
        password: 'password123',
      );

      expect(data['user'], {'full_name': 'Amina'});
    });

    test('throws ApiException with server message', () async {
      final service = ApiService(
        client: MockClient((request) async {
          return http.Response('{"message":"Email already exists"}', 400);
        }),
      );

      expect(
        service.register(
          fullName: 'Amina Hassan',
          phoneNumber: '0712345678',
          email: 'amina@example.com',
          password: 'password123',
          passwordConfirmation: 'password123',
        ),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Email already exists',
          ),
        ),
      );
    });

    test('sends bearer token when requesting current user', () async {
      late final String? authorizationHeader;
      final service = ApiService(
        client: MockClient((request) async {
          authorizationHeader = request.headers['Authorization'];
          return http.Response(
            '{"data":{"user_id":"WZr2JsT5Kn","permissions":["auth.me"]}}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      final data = await service.me(token: 'sample-token');

      expect(authorizationHeader, 'Bearer sample-token');
      expect(data['user_id'], 'WZr2JsT5Kn');
      expect(data['permissions'], ['auth.me']);
    });

    test('sends username and international phone number on register', () async {
      late final Map<String, dynamic> requestBody;
      final service = ApiService(
        client: MockClient((request) async {
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{"data":{"id":1}}', 201);
        }),
      );

      await service.register(
        fullName: 'Amina Hassan',
        phoneNumber: '0712345678',
        email: 'amina@example.com',
        password: 'StrongPass123',
        passwordConfirmation: 'StrongPass123',
      );

      expect(requestBody['username'], 'amina@example.com');
      expect(requestBody['phone_number'], '+255712345678');
    });

    test('wraps connection failures in ApiException', () async {
      final service = ApiService(
        client: MockClient((request) {
          throw http.ClientException('Failed to fetch', request.url);
        }),
      );

      expect(
        service.requestPasswordReset(identifier: 'amina@example.com'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('Imeshindikana kuunganisha na seva'),
          ),
        ),
      );
    });

    test('requests password reset using documented endpoint', () async {
      late final Uri requestUrl;
      final service = ApiService(
        client: MockClient((request) async {
          requestUrl = request.url;
          return http.Response('{"data":{"ok":true}}', 200);
        }),
      );

      await service.requestPasswordReset(identifier: 'amina@example.com');

      expect(requestUrl.path, endsWith('/auth/password/reset/request'));
    });
  });
}
