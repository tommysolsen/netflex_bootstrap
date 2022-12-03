import 'dart:convert';

import 'package:flutter_bootstrap/i18n/i18n.dart';
import 'package:http/http.dart';

/// LaravelJSONException is a [TranslatableException] that instead of
/// getting its error message from hard coded strings in the framework
/// gets its messages from a standard error json response in laravel.
///
/// Most messages are well enough served by the fact that a human readable string
/// is available in the [message] field in the exception payload. Therefore
/// we do not really need to care much about what status code the response is
///
/// However we do treat 422 UnprocessableEntry differently because it contains
/// validation errors. Therefore we try to deserialize them so they can be
/// displayed to the user
class LaravelJSONException extends TranslatableException {
  final String message;

  LaravelJSONException._(this.message);

  factory LaravelJSONException.message(Response response) {
    try {
      var data = jsonDecode(response.body);

      if (response.statusCode == 422 && data is Map<String, dynamic>) {
        return UnprocessableEntryException(
            data['message'], data['errors'] ?? []);
      } else if (data is Map<String, dynamic> && data.containsKey('message')) {
        return LaravelJSONException._(data['message']);
      }

      return _UnexpectedException();
    } on Exception {
      return _UnexpectedException();
    } on Error {
      return _UnexpectedException();
    }
  }

  @override
  String getMessage(I18nDelegate i18n) {
    return message;
  }
}

class _UnexpectedException extends UnexpectedException
    implements LaravelJSONException {
  @override
  String get message => "";

  @override
  String getMessage(I18nDelegate i18n) {
    return super.getMessage(i18n);
  }
}

class UnprocessableEntryException extends LaravelJSONException {
  final Map<String, List<String>> fields;

  UnprocessableEntryException(String message, Map<String, dynamic> data)
      : fields = _parseFields(data),
        super._(message);

  List<String> validationErrorsForField(String field) => fields[field] ?? [];
}

Map<String, List<String>> _parseFieldList(List<dynamic> data, String field) =>
    data
        .whereType<String>()
        .map((e) => EntryField(field, e))
        .toList(growable: false)
        .fold({}, (map, element) {
      if (map.containsKey(element.field) == false) {
        map[element.field] = [];
      }
      map[element.field]!.add(element.reason);
      return map;
    });

Map<String, List<String>> _parseFields(Map<String, dynamic> data) =>
    data.entries
        .map((entry) => _parseFieldList(entry.value, entry.key)).fold(
        <String, List<String>>{},
            (previousValue, element) =>
        previousValue..addAll(element)
    );
