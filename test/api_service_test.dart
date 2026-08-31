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

    test('supports protected user create detail update and delete', () async {
      final methods = <String>[];
      final paths = <String>[];
      final authHeaders = <String?>[];
      final service = ApiService(
        client: MockClient((request) async {
          methods.add(request.method);
          paths.add(request.url.path);
          authHeaders.add(request.headers['Authorization']);
          return http.Response(
            request.method == 'DELETE'
                ? '{"success":true}'
                : '{"data":{"user_id":"u1","email":"admin@example.com"}}',
            200,
          );
        }),
      );

      await service.protectedCreate(
        token: 'admin-token',
        path: '/users',
        body: {'username': 'admin@example.com'},
      );
      await service.protectedDetail(token: 'admin-token', path: '/users/u1');
      await service.protectedUpdate(
        token: 'admin-token',
        path: '/users/u1',
        body: {'first_name': 'Admin'},
      );
      await service.protectedDelete(token: 'admin-token', path: '/users/u1');

      expect(methods, ['POST', 'GET', 'PATCH', 'DELETE']);
      expect(paths, [
        endsWith('/users'),
        endsWith('/users/u1'),
        endsWith('/users/u1'),
        endsWith('/users/u1'),
      ]);
      expect(authHeaders.toSet(), {'Bearer admin-token'});
    });

    test('supports protected role and permission detail endpoints', () async {
      final methods = <String>[];
      final paths = <String>[];
      final service = ApiService(
        client: MockClient((request) async {
          methods.add(request.method);
          paths.add(request.url.path);
          return http.Response(
            request.method == 'DELETE'
                ? '{"success":true}'
                : '{"data":{"role_id":"r1","permission_id":"p1","name":"Admin"}}',
            200,
          );
        }),
      );

      await service.protectedCreate(
        token: 'admin-token',
        path: '/users/roles',
        body: {'code': 'manager', 'name': 'Manager'},
      );
      await service.protectedDetail(
        token: 'admin-token',
        path: '/users/roles/r1',
      );
      await service.protectedReplace(
        token: 'admin-token',
        path: '/users/roles/r1',
        body: {'code': 'manager', 'name': 'Manager'},
      );
      await service.protectedUpdate(
        token: 'admin-token',
        path: '/users/roles/r1',
        body: {'permission_ids': <String>[]},
      );
      await service.protectedDelete(
        token: 'admin-token',
        path: '/users/roles/r1',
      );
      await service.protectedDetail(
        token: 'admin-token',
        path: '/users/permissions/p1',
      );

      expect(methods, ['POST', 'GET', 'PUT', 'PATCH', 'DELETE', 'GET']);
      expect(paths, [
        endsWith('/users/roles'),
        endsWith('/users/roles/r1'),
        endsWith('/users/roles/r1'),
        endsWith('/users/roles/r1'),
        endsWith('/users/roles/r1'),
        endsWith('/users/permissions/p1'),
      ]);
    });

    test(
      'supports commodity category list detail create update and delete',
      () async {
        final methods = <String>[];
        final paths = <String>[];
        final service = ApiService(
          client: MockClient((request) async {
            methods.add(request.method);
            paths.add(request.url.path);
            return http.Response(
              request.method == 'GET' &&
                      request.url.path.endsWith('/categories')
                  ? '{"data":[{"category_id":"cat1","name":"Grains"}]}'
                  : request.method == 'DELETE'
                  ? '{"success":true}'
                  : '{"data":{"category_id":"cat1","name":"Grains"}}',
              200,
            );
          }),
        );

        await service.publicList('/commodities/categories');
        await service.protectedCreate(
          token: 'admin-token',
          path: '/commodities/categories',
          body: {'name': 'Grains'},
        );
        await service.publicDetail('/commodities/categories/cat1');
        await service.protectedUpdate(
          token: 'admin-token',
          path: '/commodities/categories/cat1',
          body: {'name': 'Cereals'},
        );
        await service.protectedDelete(
          token: 'admin-token',
          path: '/commodities/categories/cat1',
        );

        expect(methods, ['GET', 'POST', 'GET', 'PATCH', 'DELETE']);
        expect(paths, [
          endsWith('/commodities/categories'),
          endsWith('/commodities/categories'),
          endsWith('/commodities/categories/cat1'),
          endsWith('/commodities/categories/cat1'),
          endsWith('/commodities/categories/cat1'),
        ]);
      },
    );

    test('supports commodity unit list detail create update and delete', () async {
      final methods = <String>[];
      final paths = <String>[];
      final service = ApiService(
        client: MockClient((request) async {
          methods.add(request.method);
          paths.add(request.url.path);
          return http.Response(
            request.method == 'GET' && request.url.path.endsWith('/units')
                ? '{"data":[{"unit_id":"unit1","name":"Kilogram","symbol":"kg"}]}'
                : request.method == 'DELETE'
                ? '{"success":true}'
                : '{"data":{"unit_id":"unit1","name":"Kilogram","symbol":"kg"}}',
            200,
          );
        }),
      );

      await service.publicList('/commodities/units');
      await service.protectedCreate(
        token: 'admin-token',
        path: '/commodities/units',
        body: {'name': 'Kilogram', 'symbol': 'kg'},
      );
      await service.publicDetail('/commodities/units/unit1');
      await service.protectedUpdate(
        token: 'admin-token',
        path: '/commodities/units/unit1',
        body: {'name': 'Kilogram', 'symbol': 'kg'},
      );
      await service.protectedDelete(
        token: 'admin-token',
        path: '/commodities/units/unit1',
      );

      expect(methods, ['GET', 'POST', 'GET', 'PATCH', 'DELETE']);
      expect(paths, [
        endsWith('/commodities/units'),
        endsWith('/commodities/units'),
        endsWith('/commodities/units/unit1'),
        endsWith('/commodities/units/unit1'),
        endsWith('/commodities/units/unit1'),
      ]);
    });

    test('supports commodity detail create update and delete', () async {
      final methods = <String>[];
      final paths = <String>[];
      final service = ApiService(
        client: MockClient((request) async {
          methods.add(request.method);
          paths.add(request.url.path);
          return http.Response(
            request.method == 'DELETE'
                ? '{"success":true}'
                : '{"data":{"commodity_id":"com1","name":"Rice","unit":"kg"}}',
            200,
          );
        }),
      );

      await service.protectedCreate(
        token: 'admin-token',
        path: '/commodities',
        body: {
          'name': 'Rice',
          'unit_id': 'unit1',
          'category_ids': ['cat1'],
        },
      );
      await service.publicDetail('/commodities/com1');
      await service.protectedUpdate(
        token: 'admin-token',
        path: '/commodities/com1',
        body: {'name': 'Rice', 'unit_id': 'unit1'},
      );
      await service.protectedDelete(
        token: 'admin-token',
        path: '/commodities/com1',
      );

      expect(methods, ['POST', 'GET', 'PATCH', 'DELETE']);
      expect(paths, [
        endsWith('/commodities'),
        endsWith('/commodities/com1'),
        endsWith('/commodities/com1'),
        endsWith('/commodities/com1'),
      ]);
    });

    test('supports market detail create update and delete', () async {
      final methods = <String>[];
      final paths = <String>[];
      final service = ApiService(
        client: MockClient((request) async {
          methods.add(request.method);
          paths.add(request.url.path);
          return http.Response(
            request.method == 'DELETE'
                ? '{"success":true}'
                : '{"data":{"market_id":"m1","name":"Soko Kuu","status":"active"}}',
            200,
          );
        }),
      );

      await service.protectedCreate(
        token: 'admin-token',
        path: '/markets',
        body: {'name': 'Soko Kuu', 'admin_area_id': 'area1'},
      );
      await service.publicDetail('/markets/m1');
      await service.protectedUpdate(
        token: 'admin-token',
        path: '/markets/m1',
        body: {'name': 'Soko Kuu'},
      );
      await service.protectedDelete(token: 'admin-token', path: '/markets/m1');

      expect(methods, ['POST', 'GET', 'PATCH', 'DELETE']);
      expect(paths, [
        endsWith('/markets'),
        endsWith('/markets/m1'),
        endsWith('/markets/m1'),
        endsWith('/markets/m1'),
      ]);
    });

    test(
      'supports market price detail and market nested price endpoints',
      () async {
        final methods = <String>[];
        final paths = <String>[];
        final service = ApiService(
          client: MockClient((request) async {
            methods.add(request.method);
            paths.add(request.url.path);
            return http.Response(
              request.method == 'DELETE'
                  ? '{"success":true}'
                  : request.url.path.endsWith('/prices') ||
                        request.url.path.endsWith('/latest-prices')
                  ? '{"data":[{"price_id":"p1","price":"2400","currency":"TZS"}]}'
                  : '{"data":{"price_id":"p1","price":"2400","currency":"TZS"}}',
              200,
            );
          }),
        );

        await service.publicDetail('/market-prices/p1');
        await service.protectedUpdate(
          token: 'admin-token',
          path: '/market-prices/p1',
          body: {'price': '2500'},
        );
        await service.protectedDelete(
          token: 'admin-token',
          path: '/market-prices/p1',
        );
        await service.publicList('/markets/m1/prices');
        await service.protectedCreate(
          token: 'admin-token',
          path: '/markets/m1/prices',
          body: {'commodity_id': 'c1', 'price': '2400'},
        );
        await service.publicList('/markets/m1/latest-prices');

        expect(methods, ['GET', 'PATCH', 'DELETE', 'GET', 'POST', 'GET']);
        expect(paths, [
          endsWith('/market-prices/p1'),
          endsWith('/market-prices/p1'),
          endsWith('/market-prices/p1'),
          endsWith('/markets/m1/prices'),
          endsWith('/markets/m1/prices'),
          endsWith('/markets/m1/latest-prices'),
        ]);
      },
    );

    test('supports commodity price view endpoints', () async {
      final paths = <String>[];
      final service = ApiService(
        client: MockClient((request) async {
          paths.add(request.url.path);
          return http.Response(
            '{"data":[{"price_id":"p1","price":"2400","currency":"TZS"}]}',
            200,
          );
        }),
      );

      await service.publicList('/commodities/c1/prices');
      await service.publicList('/commodities/c1/price-history');
      await service.publicList('/commodities/c1/price-comparison');

      expect(paths, [
        endsWith('/commodities/c1/prices'),
        endsWith('/commodities/c1/price-history'),
        endsWith('/commodities/c1/price-comparison'),
      ]);
    });

    test('supports area create bulk detail update and delete', () async {
      final methods = <String>[];
      final paths = <String>[];
      final service = ApiService(
        client: MockClient((request) async {
          methods.add(request.method);
          paths.add(request.url.path);
          return http.Response(
            request.method == 'DELETE'
                ? '{"success":true}'
                : '{"data":{"area_id":"a1","name":"Morogoro","level":"region"}}',
            200,
          );
        }),
      );

      await service.protectedCreate(
        token: 'admin-token',
        path: '/areas',
        body: {'name': 'Morogoro', 'level': 'region'},
      );
      await service.protectedCreate(
        token: 'admin-token',
        path: '/areas/bulk',
        body: {
          'level': 'ward',
          'path': ['Morogoro', 'Morogoro MC', 'Kihonda'],
        },
      );
      await service.publicDetail('/areas/a1');
      await service.protectedUpdate(
        token: 'admin-token',
        path: '/areas/a1',
        body: {'name': 'Morogoro'},
      );
      await service.protectedDelete(token: 'admin-token', path: '/areas/a1');

      expect(methods, ['POST', 'POST', 'GET', 'PATCH', 'DELETE']);
      expect(paths, [
        endsWith('/areas'),
        endsWith('/areas/bulk'),
        endsWith('/areas/a1'),
        endsWith('/areas/a1'),
        endsWith('/areas/a1'),
      ]);
    });

    test('supports listing list create detail update and delete', () async {
      final methods = <String>[];
      final paths = <String>[];
      final service = ApiService(
        client: MockClient((request) async {
          methods.add(request.method);
          paths.add(request.url.path);
          return http.Response(
            request.method == 'GET' && request.url.path.endsWith('/listings')
                ? '{"data":[{"listing_id":"l1","title":"Rice bags"}]}'
                : request.method == 'DELETE'
                ? '{"success":true}'
                : '{"data":{"listing_id":"l1","title":"Rice bags"}}',
            200,
          );
        }),
      );

      await service.publicList('/listings');
      await service.protectedCreate(
        token: 'seller-token',
        path: '/listings',
        body: {
          'commodity_id': 'c1',
          'adm_area_id': 'a1',
          'title': 'Rice bags',
          'price': '50000',
        },
      );
      await service.publicDetail('/listings/l1');
      await service.protectedUpdate(
        token: 'seller-token',
        path: '/listings/l1',
        body: {'title': 'Rice bags'},
      );
      await service.protectedDelete(
        token: 'seller-token',
        path: '/listings/l1',
      );

      expect(methods, ['GET', 'POST', 'GET', 'PATCH', 'DELETE']);
      expect(paths, [
        endsWith('/listings'),
        endsWith('/listings'),
        endsWith('/listings/l1'),
        endsWith('/listings/l1'),
        endsWith('/listings/l1'),
      ]);
    });

    test('supports order create detail and update', () async {
      final methods = <String>[];
      final paths = <String>[];
      final service = ApiService(
        client: MockClient((request) async {
          methods.add(request.method);
          paths.add(request.url.path);
          return http.Response(
            '{"data":{"order_id":"o1","quantity":"2","status":"pending"}}',
            200,
          );
        }),
      );

      await service.protectedCreate(
        token: 'buyer-token',
        path: '/orders',
        body: {'listing_id': 'l1', 'quantity': '2'},
      );
      await service.protectedDetail(token: 'buyer-token', path: '/orders/o1');
      await service.protectedUpdate(
        token: 'buyer-token',
        path: '/orders/o1',
        body: {'status': 'confirmed'},
      );

      expect(methods, ['POST', 'GET', 'PATCH']);
      expect(paths, [
        endsWith('/orders'),
        endsWith('/orders/o1'),
        endsWith('/orders/o1'),
      ]);
    });

    test('supports dedicated marketplace listings and filtering', () async {
      late final Uri requestUri;
      final service = ApiService(
        client: MockClient((request) async {
          requestUri = request.url;
          return http.Response(
            '{"data":[{"listing_id":"l1","title":"Rice","price":"2500"}],"meta":{"pagination":{"page":1,"page_size":9,"total_items":1,"total_pages":1,"has_next":false}}}',
            200,
          );
        }),
      );

      final result = await service.listCommodityListings(
        commodityId: 'c1',
        areaId: 'a1',
        status: 'available',
        minPrice: 1000,
        maxPrice: 5000,
        ordering: 'price',
        search: 'Rice',
        page: 1,
        pageSize: 9,
      );

      expect(result.items.length, 1);
      expect(requestUri.queryParameters['commodity_id'], 'c1');
      expect(requestUri.queryParameters['area_id'], 'a1');
      expect(requestUri.queryParameters['status'], 'available');
      expect(requestUri.queryParameters['min_price'], '1000.0');
      expect(requestUri.queryParameters['max_price'], '5000.0');
      expect(requestUri.queryParameters['ordering'], 'price');
      expect(requestUri.queryParameters['search'], 'Rice');
    });

    test('supports dedicated orders list with scope and status filtering', () async {
      late final Uri requestUri;
      final service = ApiService(
        client: MockClient((request) async {
          requestUri = request.url;
          return http.Response(
            '{"data":[{"order_id":"o1","quantity":"5"}],"meta":{"pagination":{"page":1,"page_size":10,"total_items":1,"total_pages":1,"has_next":false},"counts":{"placed":1,"received":2}}}',
            200,
          );
        }),
      );

      final result = await service.listOrders(
        token: 'user-token',
        scope: 'placed',
        status: 'pending',
        search: 'Rice',
        page: 1,
        pageSize: 10,
      );

      expect(result.items.length, 1);
      expect(result.counts['placed'], 1);
      expect(result.counts['received'], 2);
      expect(requestUri.queryParameters['scope'], 'placed');
      expect(requestUri.queryParameters['status'], 'pending');
      expect(requestUri.queryParameters['search'], 'Rice');
    });

    test('supports initiateOrderPayment and getOrderPaymentStatus', () async {
      final methods = <String>[];
      final paths = <String>[];
      late final String requestBody;

      final service = ApiService(
        client: MockClient((request) async {
          methods.add(request.method);
          paths.add(request.url.path);
          if (request.method == 'POST') {
            requestBody = request.body;
            return http.Response(
              '{"data":{"payment_id":"pay1","status":"pending"},"message":"Payment initiated"}',
              200,
            );
          }
          return http.Response(
            '{"data":{"order_id":"o1","order_status":"paid","payment":{"payment_id":"pay1","status":"success"}}}',
            200,
          );
        }),
      );

      final paymentResponse = await service.initiateOrderPayment(
        token: 'user-token',
        orderId: 'o1',
        phoneNumber: '0712345678',
      );
      final statusResponse = await service.getOrderPaymentStatus(
        token: 'user-token',
        orderId: 'o1',
      );

      expect(methods, ['POST', 'GET']);
      expect(paths, [
        endsWith('/orders/o1/payments'),
        endsWith('/orders/o1/payment-status'),
      ]);
      expect(requestBody, contains('+255712345678'));
      expect(paymentResponse['payment_id'], 'pay1');
      expect(statusResponse['order_status'], 'paid');
    });
  });
}
