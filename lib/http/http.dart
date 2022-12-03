import 'dart:convert';

import 'package:http/http.dart';

export 'app_version_appender.dart';
export 'auth_token.dart';
export 'locale.dart';
export 'request_logger.dart';

abstract class HttpClientMiddleware {
  Client wrap(Client client);
}

typedef QueryParameters = Map<String, String>;
typedef Headers = Map<String, String>;

class AppHttpClient {
  Client client;

  final String basePath;

  AppHttpClient(this.basePath, [Client? client]) : client = client ?? Client();

  AppHttpClient.defaultPath(this.basePath, [Client? client])
      : client = client ?? Client();

  AppHttpClient withMiddlewares(List<HttpClientMiddleware> middleware) {
    var cl = middleware.fold(client, (cl, mw) => mw.wrap(cl));
    return AppHttpClient(basePath, cl);
  }

  /// Performs a [get] request against the given endpoint
  /// The client will prepend the host and a slash.
  ///
  /// This request can not send a body
  Future<Response> get(
    String url, {
    QueryParameters? queryParameters,
    Headers? headers,
  }) async {
    return await client.get(_parseUrl(url, queryParameters), headers: headers);
  }

  /// Performs a [post] request against the given endpoint
  /// The client will prepend a host and a slash to the url
  ///
  /// This request can send a body. If the body is a Map, it will be json
  /// encoded and a **Content-Type** header will be appended.
  Future<Response> post(
    String url, {
    dynamic body,
    QueryParameters? queryParameters,
    Headers? headers,
  }) async {
    headers = headers ?? {};
    if (body is Map) {
      headers = (headers)..['Content-Type'] = 'application/json';
      body = jsonEncode(body);
    }

    headers.putIfAbsent('Accept', () => 'application/json');

    return await client.post(_parseUrl(url, queryParameters),
        headers: headers, body: body);
  }

  /// Performs a [put] request against the given endpoint
  /// The client will prepend a host and a slash to the url
  ///
  /// This request can send a body. If the body is a Map, it will be json
  /// encoded and a **Content-Type** header will be appended.
  Future<Response> put(
    String url, {
    dynamic body,
    QueryParameters? queryParameters,
    Headers? headers,
  }) async {
    if (body is Map) {
      headers = (headers ?? {})..['Content-Type'] = 'application/json';
      body = jsonEncode(body);
    }

    return await client.put(_parseUrl(url, queryParameters),
        headers: headers, body: body);
  }

  /// Performs a [patch] request against the given endpoint
  /// The client will prepend a host and a slash to the url
  ///
  /// This request can send a body. If the body is a Map, it will be json
  /// encoded and a **Content-Type** header will be appended.
  Future<Response> patch(
    String url, {
    dynamic body,
    QueryParameters? queryParameters,
    Headers? headers,
  }) async {
    if (body is Map) {
      headers = (headers ?? const {})..['Content-Type'] = 'application/json';
      body = jsonEncode(body);
    }

    return await client.patch(_parseUrl(url, queryParameters),
        headers: headers, body: body);
  }

  /// Performs a [delete] request against the given endpoint
  /// The client will prepend a host and a slash to the url
  ///
  /// This request can send a body. If the body is a Map, it will be json
  /// encoded and a **Content-Type** header will be appended.
  Future<Response> delete(
    String url, {
    dynamic body,
    QueryParameters? queryParameters,
    Headers? headers,
  }) async {
    if (body is Map) {
      headers = (headers ?? const {})..['Content-Type'] = 'application/json';
      body = jsonEncode(body);
    }

    return await client.delete(_parseUrl(url, queryParameters),
        headers: headers, body: body);
  }

  Uri _parseUrl(String url, QueryParameters? queryParameters) {
    url = url.substring(0, 1) == "/" ? url.substring(1) : url;
    return Uri.parse("$basePath/$url")
        .replace(queryParameters: queryParameters);
  }
}
