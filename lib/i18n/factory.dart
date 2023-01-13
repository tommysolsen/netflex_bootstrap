import 'dart:ui';

import 'package:netflex_bootstrap/i18n/delegate.dart';

abstract class I18nDelegateFactory<T extends I18nDelegate> {
  T makeMember(Locale locale);
}
abstract class TextEngine {
  late Map<String, String> localizedStrings;

  String t(String key, [Map<String, dynamic> replacements = const {}]);
}