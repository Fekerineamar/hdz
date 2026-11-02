import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

/// Shared HTTP client for both `dzds.dz` and `sso.dzds.dz`.
///
/// A single [CookieJar] is shared so that the WAF (`HWWAFSESID`), the SSO
/// `cookiesession1` and the NextAuth `session-token` all persist across the
/// whole flow — exactly how a browser behaves.
class ApiClient {
  /// Each chat creates its own [ApiClient] (and therefore its own [CookieJar])
  /// so a login in one chat does not leak into another.
  ApiClient() {
    _jar = CookieJar();
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        followRedirects: false,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    _dio.interceptors.add(CookieManager(_jar));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['User-Agent'] = 'DZDS-Agent/1.0 (Android)';
          options.headers['Accept'] = 'application/json, text/plain, */*';
          options.headers['Accept-Language'] = 'ar-DZ,ar;q=0.9';
          return handler.next(options);
        },
      ),
    );
  }
  late final Dio _dio;
  late final CookieJar _jar;

  Dio get dio => _dio;

  /// Reads a stored cookie value (URL-decoded) by name, or null.
  Future<String?> cookie(String name) async {
    final cookies = await _jar.loadForRequest(Uri.parse('https://dzds.dz'));
    for (final c in cookies) {
      if (c.name == name) return c.value;
    }
    return null;
  }

  /// Absolute URL helper.
  String url(String host, String path) => '$host$path';

  Future<Map<String, dynamic>> getJson(
    String host,
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    final res = await _dio.get(
      url(host, path),
      queryParameters: query,
      options: options,
    );
    return _asMap(res);
  }

  Future<Map<String, dynamic>> postJson(
    String host,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    final res = await _dio.post(
      url(host, path),
      data: data,
      queryParameters: query,
      options: options ?? Options(contentType: Headers.jsonContentType),
    );
    return _asMap(res);
  }

  /// Like [postJson], but retries transient gateway errors (502/503/504) a
  /// couple of times with backoff. Used for the SSO steps that intermittently
  /// time out behind the WAF.
  Future<Map<String, dynamic>> postJsonWithRetry(
    String host,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    int retries = 2,
  }) async {
    DioException? last;
    for (var i = 0; i <= retries; i++) {
      try {
        return await postJson(host, path,
            data: data, query: query, options: options);
      } on DioException catch (e) {
        last = e;
        final code = e.response?.statusCode;
        if (code != 502 && code != 503 && code != 504) rethrow;
        print('[HTTP] $path -> $code, retrying ${i + 1}/$retries');
        await Future<void>.delayed(Duration(seconds: 2 * (i + 1)));
      }
    }
    throw last!;
  }

  /// Form-urlencoded POST (used by NextAuth signin and the SSO auth engine).
  Future<Map<String, dynamic>> postForm(
    String host,
    String path, {
    required Map<String, dynamic> data,
    Options? options,
  }) async {
    final res = await _dio.post(
      url(host, path),
      data: data,
      options: options ?? Options(contentType: Headers.formUrlEncodedContentType),
    );
    return _asMap(res);
  }

  /// Returns the raw response (for HTML / PDF / binary).
  Future<Response<dynamic>> getRaw(String host, String path,
      {Map<String, dynamic>? query, Options? options}) {
    return _dio.get(
      url(host, path),
      queryParameters: query,
      options: options ??
          Options(responseType: ResponseType.bytes, followRedirects: false),
    );
  }

  /// Returns the `Location` header of a redirect, or null.
  String? redirectLocation(Response<dynamic> res) {
    final loc = res.headers.value('location') ?? res.headers.value('Location');
    return loc;
  }

  Map<String, dynamic> _asMap(Response<dynamic> res) {
    final body = res.data;
    if (body is Map<String, dynamic>) return body;
    if (body is String) {
      final t = body.trim();
      if (t.isEmpty) return <String, dynamic>{};
      try {
        return Map<String, dynamic>.from(jsonDecode(t) as Map);
      } catch (_) {
        return {'raw': body};
      }
    }
    return {'raw': body};
  }
}

// Re-export Dio types for convenience of consumers.
typedef DioOptions = Options;
