import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'public_api_models.dart';

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
    final response = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return _extractData(response);
  }

  Future<Map<String, dynamic>> me({required String token}) async {
    final response = await _get('/auth/me', token: token);
    return _extractData(response);
  }

  Future<PublicDashboardData> publicDashboard() async {
    final results = await Future.wait([
      _get('/markets?page_size=100'),
      _get('/market-prices?page_size=100'),
      _get('/commodities?page_size=100'),
    ]);

    return PublicDashboardData(
      markets: _readList(results[0])
          .map(MarketRecord.fromJson)
          .where((market) => market.id.isNotEmpty)
          .toList(),
      prices: _readList(results[1])
          .map(MarketPriceRecord.fromJson)
          .where((price) => price.priceId.isNotEmpty)
          .toList(),
      commodities: _readList(results[2])
          .map(CommodityRecord.fromJson)
          .where((commodity) => commodity.id.isNotEmpty)
          .toList(),
    );
  }

  Future<List<MarketPriceRecord>> marketPrices({
    String? marketId,
    String? commodityId,
  }) async {
    final query = <String, String>{'page_size': '100'};
    if (marketId != null && marketId.isNotEmpty) {
      query['market_id'] = marketId;
    }
    if (commodityId != null && commodityId.isNotEmpty) {
      query['commodity_id'] = commodityId;
    }
    final response = await _get(_pathWithQuery('/market-prices', query));
    return _readList(response).map(MarketPriceRecord.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> protectedList({
    required String token,
    required String path,
  }) async {
    if (token.isEmpty) {
      throw ApiException('Ingia tena ili kufungua ukurasa huu.');
    }
    final response = await _get(
      _pathWithQuery(path, {'page_size': '100'}),
      token: token,
    );
    return _readList(response);
  }

  Future<Map<String, dynamic>> protectedDetail({
    required String token,
    required String path,
  }) async {
    if (token.isEmpty) {
      throw ApiException('Ingia tena ili kufungua ukurasa huu.');
    }
    final response = await _get(path, token: token);
    return _extractData(response);
  }

  Future<Map<String, dynamic>> protectedCreate({
    required String token,
    required String path,
    required Map<String, dynamic> body,
  }) async {
    if (token.isEmpty) {
      throw ApiException('Ingia tena ili kufanya kitendo hiki.');
    }
    final response = await _post(path, body, token: token);
    return _extractData(response);
  }

  Future<Map<String, dynamic>> protectedUpdate({
    required String token,
    required String path,
    required Map<String, dynamic> body,
  }) async {
    if (token.isEmpty) {
      throw ApiException('Ingia tena ili kufanya kitendo hiki.');
    }
    final response = await _patch(path, body, token: token);
    return _extractData(response);
  }

  Future<Map<String, dynamic>> protectedReplace({
    required String token,
    required String path,
    required Map<String, dynamic> body,
  }) async {
    if (token.isEmpty) {
      throw ApiException('Ingia tena ili kufanya kitendo hiki.');
    }
    final response = await _put(path, body, token: token);
    return _extractData(response);
  }

  Future<void> protectedDelete({
    required String token,
    required String path,
  }) async {
    if (token.isEmpty) {
      throw ApiException('Ingia tena ili kufanya kitendo hiki.');
    }
    await _delete(path, token: token);
  }

  Future<List<Map<String, dynamic>>> publicList(String path) async {
    final response = await _get(_pathWithQuery(path, {'page_size': '100'}));
    return _readList(response);
  }

  Future<PaginatedListResponse> paginatedList({
    required String path,
    int page = 1,
    int pageSize = 9,
    String? token,
  }) async {
    final response = await _get(
      _pathWithQuery(path, {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      }),
      token: token,
    );
    return PaginatedListResponse.fromPayload(response);
  }

  Future<PaginatedListResponse> listCommodityListings({
    String? commodityId,
    String? areaId,
    String? status,
    double? minPrice,
    double? maxPrice,
    String? ordering,
    String? search,
    int page = 1,
    int pageSize = 9,
    String? token,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (commodityId != null && commodityId.isNotEmpty) {
      query['commodity_id'] = commodityId;
    }
    if (areaId != null && areaId.isNotEmpty) {
      query['area_id'] = areaId;
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (minPrice != null) {
      query['min_price'] = minPrice.toString();
    }
    if (maxPrice != null) {
      query['max_price'] = maxPrice.toString();
    }
    if (ordering != null && ordering.isNotEmpty) {
      query['ordering'] = ordering;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final response = await _get(
      _pathWithQuery('/listings', query),
      token: token,
    );
    return PaginatedListResponse.fromPayload(response);
  }

  Future<Map<String, dynamic>> getCommodityListing(
    String listingId, {
    String? token,
  }) async {
    final response = await _get('/listings/$listingId', token: token);
    return _extractData(response);
  }

  Future<Map<String, dynamic>> createCommodityListing({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    return protectedCreate(token: token, path: '/listings', body: body);
  }

  Future<Map<String, dynamic>> updateCommodityListing({
    required String token,
    required String listingId,
    required Map<String, dynamic> body,
  }) async {
    return protectedUpdate(
      token: token,
      path: '/listings/$listingId',
      body: body,
    );
  }

  Future<void> deleteCommodityListing({
    required String token,
    required String listingId,
  }) async {
    await protectedDelete(token: token, path: '/listings/$listingId');
  }

  Future<PaginatedListResponse> listOrders({
    String? scope,
    String? status,
    String? search,
    int page = 1,
    int pageSize = 10,
    required String token,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (scope != null && scope.isNotEmpty) {
      query['scope'] = scope;
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    final response = await _get(
      _pathWithQuery('/orders', query),
      token: token,
    );
    return PaginatedListResponse.fromPayload(response);
  }

  Future<Map<String, dynamic>> getOrderDetail({
    required String token,
    required String orderId,
  }) async {
    return protectedDetail(token: token, path: '/orders/$orderId');
  }

  Future<Map<String, dynamic>> createOrder({
    required String token,
    required String listingId,
    required String quantity,
  }) async {
    return protectedCreate(
      token: token,
      path: '/orders',
      body: {'listing_id': listingId, 'quantity': quantity},
    );
  }

  Future<Map<String, dynamic>> updateOrderStatus({
    required String token,
    required String orderId,
    required String status,
  }) async {
    return protectedUpdate(
      token: token,
      path: '/orders/$orderId',
      body: {'status': status},
    );
  }

  Future<Map<String, dynamic>> initiateOrderPayment({
    required String token,
    required String orderId,
    required String phoneNumber,
  }) async {
    final response = await _post(
      '/orders/$orderId/payments',
      {'phone_number': _normalizePhoneNumber(phoneNumber)},
      token: token,
    );
    return _extractData(response);
  }

  Future<Map<String, dynamic>> getOrderPaymentStatus({
    required String token,
    required String orderId,
  }) async {
    final response = await _get(
      '/orders/$orderId/payment-status',
      token: token,
    );
    return _extractData(response);
  }

  Future<Map<String, dynamic>> publicDetail(String path) async {
    final response = await _get(path);
    return _extractData(response);
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _post('/auth/register', {
      'username': email,
      'full_name': fullName,
      'phone_number': _normalizePhoneNumber(phoneNumber),
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    return _extractData(response);
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _post('/auth/email/verify', {
      'email': email.trim(),
      'code': code.trim(),
    });
    return _extractData(response);
  }

  Future<Map<String, dynamic>> resendEmailVerification({
    required String email,
  }) async {
    final response = await _post('/auth/email/resend', {'email': email.trim()});
    return _extractData(response);
  }

  Future<MarketPriceRecord> createMarketPrice({
    required String token,
    required String marketId,
    required String commodityId,
    required String price,
    required String priceDate,
    String? minPrice,
    String? maxPrice,
    String currency = 'TZS',
  }) async {
    final response = await _post('/market-prices', {
      'market_id': marketId,
      'commodity_id': commodityId,
      'price': price,
      if (minPrice != null && minPrice.trim().isNotEmpty)
        'min_price': minPrice.trim(),
      if (maxPrice != null && maxPrice.trim().isNotEmpty)
        'max_price': maxPrice.trim(),
      'currency': currency,
      'price_date': priceDate,
    }, token: token);
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return MarketPriceRecord.fromJson(data);
    }
    throw ApiException('Seva imerudisha majibu yasiyo sahihi. Jaribu tena.');
  }

  String _normalizePhoneNumber(String phoneNumber) {
    final normalized = phoneNumber.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.startsWith('0') && normalized.length == 10) {
      return '+255${normalized.substring(1)}';
    }
    return normalized;
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String identifier,
  }) async {
    final response = await _post('/auth/password/reset/request', {
      'identifier': identifier,
    });
    return _extractData(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    late final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on http.ClientException {
      throw ApiException(
        'Imeshindikana kuunganisha na seva. Hakikisha backend inaendeshwa kwenye ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw ApiException('Ombi limechukua muda mrefu. Jaribu tena.');
    }

    final jsonBody = _decodeResponseBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    throw ApiException(_readError(jsonBody));
  }

  Future<Map<String, dynamic>> _get(String path, {String? token}) async {
    late final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
    } on http.ClientException {
      throw ApiException(
        'Imeshindikana kuunganisha na seva. Hakikisha backend inaendeshwa kwenye ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw ApiException('Ombi limechukua muda mrefu. Jaribu tena.');
    }

    final jsonBody = _decodeResponseBody(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }

    throw ApiException(_readError(jsonBody));
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    late final http.Response response;
    try {
      response = await _client
          .patch(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on http.ClientException {
      throw ApiException(
        'Imeshindikana kuunganisha na seva. Hakikisha backend inaendeshwa kwenye ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw ApiException('Ombi limechukua muda mrefu. Jaribu tena.');
    }

    final jsonBody = _decodeResponseBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }
    throw ApiException(_readError(jsonBody));
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    late final http.Response response;
    try {
      response = await _client
          .put(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on http.ClientException {
      throw ApiException(
        'Imeshindikana kuunganisha na seva. Hakikisha backend inaendeshwa kwenye ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw ApiException('Ombi limechukua muda mrefu. Jaribu tena.');
    }

    final jsonBody = _decodeResponseBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }
    throw ApiException(_readError(jsonBody));
  }

  Future<Map<String, dynamic>> _delete(String path, {String? token}) async {
    late final http.Response response;
    try {
      response = await _client
          .delete(
            Uri.parse('${ApiConfig.baseUrl}$path'),
            headers: {
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));
    } on http.ClientException {
      throw ApiException(
        'Imeshindikana kuunganisha na seva. Hakikisha backend inaendeshwa kwenye ${ApiConfig.baseUrl}.',
      );
    } on TimeoutException {
      throw ApiException('Ombi limechukua muda mrefu. Jaribu tena.');
    }

    final jsonBody = _decodeResponseBody(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonBody;
    }
    throw ApiException(_readError(jsonBody));
  }

  List<Map<String, dynamic>> _readList(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return const <Map<String, dynamic>>[];
  }

  String _pathWithQuery(String path, Map<String, String> query) {
    if (query.isEmpty) {
      return path;
    }
    final encoded = Uri(queryParameters: query).query;
    return '$path?$encoded';
  }

  Map<String, dynamic> _decodeResponseBody(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      throw ApiException('Seva imerudisha majibu yasiyo sahihi. Jaribu tena.');
    }

    throw ApiException('Seva imerudisha majibu yasiyo sahihi. Jaribu tena.');
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

class PaginatedListResponse {
  const PaginatedListResponse({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.hasNext,
    this.totalItems = 0,
    this.counts = const <String, int>{},
  });

  final List<Map<String, dynamic>> items;
  final int page;
  final int totalPages;
  final bool hasNext;
  final int totalItems;
  final Map<String, int> counts;

  factory PaginatedListResponse.fromPayload(Map<String, dynamic> payload) {
    final data = payload['data'];
    final meta = payload['meta'];
    final pagination = meta is Map<String, dynamic> ? meta['pagination'] : null;
    final countsMap = meta is Map<String, dynamic> ? meta['counts'] : null;

    final counts = <String, int>{};
    if (countsMap is Map<String, dynamic>) {
      countsMap.forEach((key, val) {
        if (val is int) {
          counts[key] = val;
        } else if (val != null) {
          counts[key] = int.tryParse(val.toString()) ?? 0;
        }
      });
    }

    return PaginatedListResponse(
      items: data is List
          ? data.whereType<Map<String, dynamic>>().toList()
          : const <Map<String, dynamic>>[],
      page: _readInt(pagination, 'page', fallback: 1),
      totalPages: _readInt(pagination, 'total_pages', fallback: 1),
      hasNext: _readBool(pagination, 'has_next'),
      totalItems: _readInt(pagination, 'total_items', fallback: 0),
      counts: counts,
    );
  }

  static int _readInt(dynamic source, String key, {required int fallback}) {
    if (source is! Map<String, dynamic>) {
      return fallback;
    }
    final value = source[key];
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _readBool(dynamic source, String key) {
    if (source is! Map<String, dynamic>) {
      return false;
    }
    final value = source[key];
    if (value is bool) {
      return value;
    }
    return value?.toString().toLowerCase() == 'true';
  }
}
