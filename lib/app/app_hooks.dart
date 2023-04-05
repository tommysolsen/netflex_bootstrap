import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:netflex_bootstrap/exceptions/async.dart';
import 'package:netflex_bootstrap/netflex_bootstrap.dart';

/// AppMiddlewares are run during the bootstrapping process in several steps.
/// The steps are completed in order.
///
/// Order is:
/// 1. [LocaleIndependentAppClientMiddleware]
/// 2. [LocaleIndependentMiddleware]
/// 3. [LocaleDependent
abstract class AppMiddleware {}

abstract class LocaleIndependentAppClientMiddleware extends AppMiddleware {
  AppHttpClient preLocAppHandler(AppHttpClient client);

  static AppHttpClient wrap(
    AppHttpClient client,
    Iterable<AppMiddleware> middlewares,
  ) {
    return middlewares
        .whereType<LocaleIndependentAppClientMiddleware>()
        .fold(client, (cl, element) => element.preLocAppHandler(cl));
  }
}

extension LocaleIndependentAppClientMiddlewareWrapper
    on Iterable<LocaleIndependentAppClientMiddleware> {
  AppHttpClient wrap(AppHttpClient client) =>
      fold(client, (cl, element) => element.preLocAppHandler(cl));
}

abstract class LocaleDependentAppClientMiddleware extends AppMiddleware {
  AppHttpClient postLocAppHandler(AppHttpClient client, Locale locale);

  static AppHttpClient wrap(AppHttpClient client, Locale locale,
      Iterable<AppMiddleware> middlewares) {
    return middlewares.whereType<LocaleDependentAppClientMiddleware>().fold(
          client,
          (cl, e) => e.postLocAppHandler(cl, locale),
        );
  }
}

extension LocaleDependentAppClientMiddlewareWrapper
    on Iterable<LocaleDependentAppClientMiddleware> {
  AppHttpClient wrap(AppHttpClient client, Locale locale) =>
      fold(client, (cl, element) => element.postLocAppHandler(cl, locale));
}

abstract class LocaleIndependentMiddleware extends AppMiddleware {
  Future<Widget> preLocaleHandler(Widget widget);

  static Future<Widget> wrap(
      Widget child, Iterable<AppMiddleware> middlewares) {
    return middlewares
        .whereType<LocaleIndependentMiddleware>()
        .foldAsync(child, (cl, e) => e.preLocaleHandler(cl));
  }
}

extension LocaleIndependentMiddlewareWrapper
    on Iterable<LocaleIndependentMiddleware> {
  Future<Widget> wrap(Widget child) =>
      foldAsync(child, (cl, element) => element.preLocaleHandler(cl));
}

abstract class LocaleDependentMiddleware extends AppMiddleware {
  Future<Widget> postLocaleHandler(Widget widget, Locale locale);

  static Future<Widget> wrap(
      Widget child, Locale locale, Iterable<AppMiddleware> middlewares) {
    return middlewares
        .whereType<LocaleDependentMiddleware>()
        .foldAsync(child, (cl, e) => e.postLocaleHandler(cl, locale));
  }
}

extension LocaleDependentMiddlewareWrapper
    on Iterable<LocaleDependentMiddleware> {
  Future<Widget> wrap(Widget client, Locale locale) =>
      foldAsync(client, (cl, element) => element.postLocaleHandler(cl, locale));
}

abstract class AppClientDependentMiddleware extends AppMiddleware {
  Widget postLocaleWithAppClientHandler(
      Widget widget, Locale locale, AppHttpClient client);

  static Widget wrap(Widget child, Locale locale, AppHttpClient client,
      Iterable<AppMiddleware> middlewares) {
    return middlewares.whereType<AppClientDependentMiddleware>().fold(
          child,
          (cl, e) => e.postLocaleWithAppClientHandler(cl, locale, client),
        );
  }
}

extension AppClientDependentMiddlewareWrapper
    on Iterable<AppClientDependentMiddleware> {
  Widget wrap(Widget child, Locale locale, AppHttpClient client) => fold(
        child,
        (cl, element) =>
            element.postLocaleWithAppClientHandler(cl, locale, client),
      );
}
