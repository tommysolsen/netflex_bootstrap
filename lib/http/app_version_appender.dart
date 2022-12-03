import 'package:flutter_bootstrap/http/http.dart';
import 'package:http/http.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:platform_info/platform_info.dart';

class AppVersionAppender extends HttpClientMiddleware {
  final Platform platform;
  final PackageInfo packageInfo;

  AppVersionAppender(this.platform, this.packageInfo);

  @override
  Client wrap(Client client) {
    return _AppVersionAppender(
      client,
      platformVersion: platform.version,
      os: platform.operatingSystem.toString(),
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }
}

class _AppVersionAppender extends BaseClient {
  final Client client;

  final String platformVersion;
  final String os;
  final String appVersion;
  final String buildNumber;

  _AppVersionAppender(
      this.client, {
        required this.platformVersion,
        required this.os,
        required this.appVersion,
        required this.buildNumber,
      });

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    request.headers['X-Platform-Version'] = platformVersion;
    request.headers['X-OS'] = os;
    request.headers['X-App-Version'] = appVersion;
    request.headers['X-Build-Number'] = buildNumber;

    return await client.send(request);
  }
}
