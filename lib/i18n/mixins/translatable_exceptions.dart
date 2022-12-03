
import 'dart:async';
import 'dart:io';

import 'package:flutter_bootstrap/flutter_bootstrap.dart';

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