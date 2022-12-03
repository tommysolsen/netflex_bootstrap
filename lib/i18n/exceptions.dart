import 'dart:convert';

import 'package:http/http.dart';
import 'delegate.dart';


abstract class TranslatableException implements Exception {
  factory TranslatableException.message(Response response) {
    try {
      var data = jsonDecode(response.body);

      if (response.statusCode == 422) {
        return UnprocessableEntryException(
            data['message'], data['errors'] ?? []);
      }

      return UnexpectedException();
    } on Exception {
      return UnexpectedException();
    } on Error {
      return UnexpectedException();
    }
  }

  String getMessage(I18nDelegate i18n);
}

class EntryField {
  final String field;
  final String reason;

  EntryField(this.field, this.reason);
}

List<EntryField> _parseFieldList(List<dynamic> data, String field) => data
    .whereType<String>()
    .map((e) => EntryField(field, e))
    .toList(growable: false);

List<EntryField> _parseFields(Map<String, dynamic> data) =>
    data.entries.map((entry) => _parseFieldList(entry.value, entry.key)).fold(
      <EntryField>[],
          (List<EntryField> previousValue, element) =>
      previousValue..addAll(element),
    ).toList(growable: false);

class UnprocessableEntryException extends ServerTranslatedException {
  final List<EntryField> fields;

  UnprocessableEntryException(super.message, Map<String, dynamic> data)
      : fields = _parseFields(data);
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

class UnexpectedException implements TranslatableException {
  @override
  String getMessage(I18nDelegate i18n) {
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

class UnauthenticatedException implements TranslatableException {
  @override
  String getMessage(I18nDelegate i18n) {
    return i18n.t("errors.unauthenticated");
  }
}

class InvalidLocalizationKeyException implements Exception {
  final String key;

  InvalidLocalizationKeyException(this.key);

  @override
  String toString() => "The localization key [$key] does not exist";
}