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

  Future<List<Map<String, dynamic>>> publicList(String path) async {
    final response = await _get(_pathWithQuery(path, {'page_size': '100'}));
    return _readList(response);
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

  Future<MarketPriceRecord> createMarketPrice({
    required String token,
    required String marketId,
    required String commodityId,
    required String price,
    required String priceDate,
    String currency = 'TZS',
  }) async {
    final response = await _post('/market-prices', {
      'market_id': marketId,
      'commodity_id': commodityId,
      'price': price,
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
