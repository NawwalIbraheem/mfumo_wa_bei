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
            '{"data":{"access":"jwt-access-token","refresh":"jwt-refresh-token","user":{"full_name":"Amina"}}}',
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
      expect(data['access'], 'jwt-access-token');
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

    test('loads public dashboard data from documented public endpoints', () async {
      final requestedPaths = <String>[];
      final service = ApiService(
        client: MockClient((request) async {
          requestedPaths.add(request.url.path);
          if (request.url.path.endsWith('/markets')) {
            return http.Response(
              '{"data":[{"market_id":"m1","name":"Soko Kuu","status":"active","admin_area":{"area_id":"a1","name":"Morogoro","level":"region","parent":null}}]}',
              200,
            );
          }
          if (request.url.path.endsWith('/market-prices')) {
            return http.Response(
              '{"data":[{"price_id":"p1","price":"2400.00","currency":"TZS","price_date":"2026-07-27","market":{"market_id":"m1","name":"Soko Kuu","status":"active"},"commodity":{"commodity_id":"c1","name":"Mchele","unit":"kg"}}]}',
              200,
            );
          }
          if (request.url.path.endsWith('/commodities')) {
            return http.Response(
              '{"data":[{"commodity_id":"c1","name":"Mchele","unit":"kg"}]}',
              200,
            );
          }
          return http.Response('{"message":"Not found"}', 404);
        }),
      );

      final dashboard = await service.publicDashboard();

      expect(requestedPaths, contains(endsWith('/markets')));
      expect(requestedPaths, contains(endsWith('/market-prices')));
      expect(requestedPaths, contains(endsWith('/commodities')));
      expect(dashboard.marketCards.first['name'], 'Soko Kuu');
      expect(dashboard.latestCommodityPrices.first.commodityName, 'Mchele');
    });

    test('sends bearer token when loading protected lists', () async {
      late final String? authorizationHeader;
      late final Uri requestUrl;
      final service = ApiService(
        client: MockClient((request) async {
          authorizationHeader = request.headers['Authorization'];
          requestUrl = request.url;
          return http.Response('{"data":[]}', 200);
        }),
      );

      await service.protectedList(token: 'admin-token', path: '/users');

      expect(authorizationHeader, 'Bearer admin-token');
      expect(requestUrl.path, endsWith('/users'));
      expect(requestUrl.queryParameters['page_size'], '100');
    });
  });
}
