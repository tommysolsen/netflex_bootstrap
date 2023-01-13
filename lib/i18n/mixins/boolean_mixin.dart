import 'package:netflex_bootstrap/i18n/delegate.dart';
import 'package:netflex_bootstrap/i18n/factory.dart';

abstract class I18nBooleanMixin implements TextEngine, I18nDelegate {

  @override
  String boolean(bool value) {
    return t('boolean.${value ? "true" : "false"}');
  }

}