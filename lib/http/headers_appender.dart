
import 'package:http/src/client.dart';
import 'package:netflex_bootstrap/http/http.dart';
import 'package:http/http.dart';

class HeadersAppender extends HttpClientMiddleware {
  final Map<String, String> headers;

  HeadersAppender(this.headers);


  @override
  Client wrap(Client client) {
    return _HeadersAppender(client, headers);
  }
}

class _HeadersAppender extends BaseClient {
  final Client client;
  final Map<String, String> headers;

  _HeadersAppender(this.client, this.headers);

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    request.headers.addAll(headers);
    return client.send(request);
  }


}
