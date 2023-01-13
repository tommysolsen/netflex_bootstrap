
import 'dart:async';
import 'dart:io';

import 'package:netflex_bootstrap/netflex_bootstrap.dart';

abstract class TranslatableExceptionMixin implements I18nDelegate {
  @override
  String translateException(Exception e) {
    if (e is TranslatableException) {
      return e.getMessage(this);
    }

    if (e is TimeoutException) {
      return t("errors.timeout_exception");
    }

    if (e is SocketException) {
      return t("errors.socket_exception");
    }

    return t('errors.unexpected');
  }
}