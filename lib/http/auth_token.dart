
import 'package:http/http.dart';

import 'http.dart';

/// Automatically performs a token based authentication. Token type is
/// bearer by default, but can be replaced with any prefix you want.
/// If prefix is explicitly set to null no prefix will be added
///
class TokenAuthenticator extends HttpClientMiddleware {
  final String authToken;
  final String? tokenType;

  TokenAuthenticator(this.authToken, [this.tokenType = "Bearer"]);
  @override
  Client wrap(Client client) {
    return _BearerTokenAuthenticator(client, tokenType, authToken);
  }

}


class _BearerTokenAuthenticator extends BaseClient {
  final Client client;
  final String authToken;
  final String? tokenType;

  _BearerTokenAuthenticator(this.client, this.tokenType, this.authToken);
  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers['Authorization'] = (tokenType != null ? "$tokenType " : "") + authToken;
    return client.send(request);
  }

}