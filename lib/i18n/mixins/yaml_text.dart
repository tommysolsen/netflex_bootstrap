import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../delegate.dart';
import '../exceptions.dart';
import '../factory.dart';

abstract class YamlTextEngine implements I18nDelegate, TextEngine {
  @override
  late Map<String, String> localizedStrings;

  @override
  String t(String key, [Map<String, dynamic> replacements = const {}]) {
    if (kDebugMode) {
      if (localizedStrings.containsKey(key) == false) {
        FlutterError.dumpErrorToConsole(
          FlutterErrorDetails(
            exception: InvalidLocalizationKeyException(key),
          ),
        );
      }
    }
    return replacements.entries.fold(
      (localizedStrings[key] ?? key),
      (previousValue, element) => previousValue.replaceAll(
        ":${element.key.toLowerCase()}",
        element.value.toString(),
      ),
    );
  }

  Future<Map<String, String>> loadAndParseTranslations() async {
    return await rootBundle.loadStructuredData(
      "lang/${locale.languageCode.toLowerCase()}.yml",
      i18nParser,
    );
  }

  Future<void> loadTranslations() async {
    localizedStrings = await loadAndParseTranslations();

    var path = await getApplicationDocumentsDirectory();
    var file = File(
      "${path.path}/i18n-${locale.languageCode.toLowerCase()}.json",
    );

    if (await file.exists()) {
      try {
        Map<String, dynamic> keys = jsonDecode(await file.readAsString());

        for (var key in keys.entries) {
          if (key.value is String) {
            localizedStrings[key.key] = key.value;
          }
        }
      } on Exception {
        // ignore: invalid_return_type_for_catch_error
        file.delete().catchError((x) async => null);
      } on Error {
        // ignore: invalid_return_type_for_catch_error
        file.delete().catchError((x) async => null);
      }
    }
  }
}
