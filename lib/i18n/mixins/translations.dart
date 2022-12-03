
import 'package:flutter_bootstrap/i18n/delegate.dart';
import 'package:flutter_bootstrap/i18n/mixins/yaml_text.dart';

import '../exceptions.dart';
import '../factory.dart';

abstract class TranslationsMixin implements I18nDelegate, TextEngine {
  String translateException(Exception e) {
    if (e is TranslatableException) {
      return e.getMessage(this);
    }

    // TODO: Mutate names to be snake_case version of class name here
    var className = e.runtimeType.toString();
    if (localizedStrings.containsKey("errors.$className")) {
      return t("errors.$className");
    }

    return t('errors.unexpected');
  }
}