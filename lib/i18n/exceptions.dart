import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:netflex_bootstrap/netflex_bootstrap.dart';
import 'package:http/http.dart';
import 'delegate.dart';

/// The TranslatableException is an Exception that an exception type that can
/// be translated by the [I18nDelegate] into a translated error message for the
/// user. It has access to the i18n delegate in order to generate the translated
/// message.
abstract class TranslatableException implements Exception {
  /// THe get message function will be run by a [I18nDelegate] in order to
  String getMessage(I18nDelegate i18n);
}

class EntryField {
  final String field;
  final String reason;

  EntryField(this.field, this.reason);
}

class ServerTranslatedException implements TranslatableException {
  final String message;

  ServerTranslatedException(this.message);

  ServerTranslatedException.fromErrorPayload(Map<String, dynamic> data)
      : message = data["message"] ?? "Unknown error";

  @override
  String getMessage(I18nDelegate i18n) {
    return message;
  }
}

abstract class LocallyTranslatedException implements TranslatableException {
  String get key;

  Map<String, dynamic> get replacements => {};

  @override
  String getMessage(I18nDelegate i18n) => i18n.t(key, replacements);
}

class UnexpectedError implements TranslatableException {
  final Error? error;

  UnexpectedError([this.error]);

  @override
  String getMessage(I18nDelegate i18n) {
    if(error != null && kDebugMode) {
      return error.toString();
    }
    return i18n.t("errors.unexpected");
  }

}
class UnexpectedException implements TranslatableException {
  final Exception? exception;

  UnexpectedException([this.exception]);

  @override
  String getMessage(I18nDelegate i18n) {
    if(exception != null && kDebugMode) {
      return exception!.toString();
    }
    return i18n.t("errors.unexpected");
  }
}

class InvalidLinkException implements TranslatableException {
  final String url;

  InvalidLinkException(this.url);

  @override
  String getMessage(I18nDelegate i18n) {
    return i18n.t('errors.invalid_link', {'url': url});
  }
}

class InvalidPagePayload implements TranslatableException {
  final Type type;
  final Type expected;

  const InvalidPagePayload(this.expected, this.type);

  @override
  String getMessage(I18nDelegate i18n) {
    return i18n.t('errors.invalid_type',
        {'type': type.toString(), 'expected': type.toString()});
  }
}

class InvalidLocalizationKeyException implements Exception {
  final String key;

  InvalidLocalizationKeyException(this.key);

  @override
  String toString() => "The localization key [$key] does not exist";
}
