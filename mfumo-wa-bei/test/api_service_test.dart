import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfumo_wa_bei/services/api_service.dart';

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
  });
}
