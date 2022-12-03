import 'package:http/http.dart';
import 'http.dart';

class RequestLogger extends HttpClientMiddleware {
  final String? scope;
  final bool verbose;

  RequestLogger(this.scope, [this.verbose = false]);

  @override
  Client wrap(Client client) {
    return _RequestLogger(client, scope, verbose);
  }
}

class _RequestLogger extends BaseClient {
  final String? scope;
  final Client client;
  final bool verbose;

  _RequestLogger(this.client, this.scope, [this.verbose = false]);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    String url = request.url.toString();
    String method = request.method;

    var started = DateTime.now();
    var response = await client.send(request);
    var duration = "${DateTime.now().difference(started).inMilliseconds}ms";
    duration = duration.padLeft(10);

    var locale = response.request?.headers['Accept-Language'] ?? "";

    if (verbose) {
      // ignore: avoid_print
      print(
        "[${scope ?? "req"}/${locale.padLeft(4)}] $duration ${method.padLeft(7)} - ${response.statusCode.toString().padLeft(3)} $url",
      );
    }

    return response;
  }
}
