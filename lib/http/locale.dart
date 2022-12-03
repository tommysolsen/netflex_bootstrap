import 'dart:ui';

import 'package:http/http.dart';

import 'http.dart';

/// Appends an [Accept-Language] header to the request
///
/// Accepts either a [Locale] or [languageCode]/[countryCode] in string format
class LocaleSetter extends HttpClientMiddleware {
  final Locale locale;

  LocaleSetter(this.locale);

  LocaleSetter.fromString(String languageCode, [String? countryCode])
      : locale = Locale(languageCode, countryCode);

  @override
  Client wrap(Client client) {
    return _LocaleSetter(client, locale.languageCode);
  }
}

class _LocaleSetter extends BaseClient {
  final String locale;
  final Client client;

  _LocaleSetter(this.client, this.locale);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    request.headers['Accept-Language'] = locale;
    return await client.send(request);
  }
}
