import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:netflex_bootstrap/netflex_bootstrap.dart';
import 'package:netflex_bootstrap/i18n/factory.dart';
import 'package:netflex_bootstrap/i18n/mixins/boolean_mixin.dart';
import 'package:netflex_bootstrap/i18n/mixins/default_dates.dart';
import 'package:netflex_bootstrap/i18n/mixins/translatable_exceptions.dart';
import 'package:netflex_bootstrap/i18n/mixins/translations.dart';
import 'package:netflex_bootstrap/i18n/mixins/yaml_text.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:yaml/yaml.dart';

/// A translation function takes a translation key and returns the translation
/// of the key. This can be [I18nDelegate.t] for example.
///
/// However this can also be a function that has a prefix applied, for example
/// [I18nDelegate.prefix] returns a [TranslationFunction]
typedef TranslationFunction = String Function(String key,
    [Map<String, dynamic> replacements]);

class I18n {
  I18n._();

  /// Finds the [I18nDelegate] of your app. This will return a generic
  /// instance which you can either typeconvert yourself, or you can use the
  /// [I18n.ofType] function with a generic type to convert it on the fly.
  ///
  /// It is only expected that you have one delegate for your entire app.
  /// And by default the implementation will be of the [BaseI18nDelegate]
  /// class which only implements the functions listed in the [I18nDelegate]
  /// interface.
  ///
  /// If you want to add your own i18n functions you can either e
  static I18nDelegate of(BuildContext context) =>
      (Localizations.of<I18nDelegate>(context, I18nDelegate)!);

  /// Finds the [I18nDelegate] of your
  static I18nDelegate ofType<T extends I18nDelegate>(BuildContext context) =>
      (Localizations.of<I18nDelegate>(context, I18nDelegate)!) as T;
}

abstract class DateIntervalProvider {
  DateTime? get start;

  DateTime? get end;
}

abstract class I18nDelegate {
  final Locale locale;

  I18nDelegate(this.locale);

  Future<bool> load();

  // Translation
  /// Translates a given key and retuns it as a simple [Text] element using the [t] function
  Widget txt(String key, [Map<String, dynamic> replacements = const {}]);

  /// Grabs a translation for the given key you provided, replacements will be
  /// replaced in such a manner where the text `:key` is replaced with the value of the corresponding key
  /// when it occurs in the translated value
  String t(String key, [Map<String, dynamic> replacements = const {}]);

  /// Returns a function that operates entirely like the [t] function. But it will
  /// prefix parts of a key, in order to repeat yourself less if you want to access
  /// the same "namespace" multiple times in the same translation.
  ///
  /// For example if you put all translations for the same component in the same
  /// "folder":
  ///
  /// ```yaml
  /// components:
  ///   player_status:
  ///     is_playing: Is playing
  ///     not_playing: Not playing
  /// ```
  ///
  /// Using `var pst = prefix("components.player_status")` can give you easy access
  /// to `is_playing` or `not_playing` through the `pst("is_playing")` call.
  TranslationFunction prefix(String prefix);

  /// Translates a boolean into a localized yes or no value
  String boolean(bool value);

  String dateLongFullMonth(DateTime time);

  String dateLong(DateTime time);

  String dateShort(DateTime time);

  String timeFormat(DateTime time);

  String dayOfWeekFormat(DateTime time);

  String translateException(Exception e);

  // Creates a new LocalizationDelegate
  static LocalizationsDelegate<I18nDelegate> makeDelegate(
          I18nDelegateFactory? factory) =>
      _I18nDelegate(
        factory ?? BaseI18DelegateFactory(),
      );
}

class BaseI18nDelegate extends I18nDelegate
    with
        YamlTextEngine,
        DefaultI18nDatesMixin,
        TranslationsMixin,
        I18nBooleanMixin,
        TranslatableExceptionMixin {
  BaseI18nDelegate(super.locale) {
    initializeDates(locale);
  }

  @override
  Widget txt(String key, [Map<String, dynamic> replacements = const {}]) =>
      Text(t(key, replacements));

  @override
  TranslationFunction prefix(String prefix) =>
      (String key, [Map<String, dynamic> replacements = const {}]) => t(
            "$prefix.$key",
            replacements,
          );

  @override
  Future<bool> load() async {
    await loadTranslations();
    Intl.defaultLocale = locale.toString();
    return true;
  }
}

class BaseI18DelegateFactory extends I18nDelegateFactory<BaseI18nDelegate> {
  @override
  BaseI18nDelegate makeMember(Locale locale) {
    return BaseI18nDelegate(locale);
  }
}

/// Creates a LocalizationDelegate for the given [I18nDelegate]
/// This is to
class _I18nDelegate<T extends I18nDelegateFactory>
    extends LocalizationsDelegate<I18nDelegate> {
  final T delegateFactory;

  const _I18nDelegate(this.delegateFactory);

  @override
  bool isSupported(Locale locale) {
    return ['en', 'nb'].contains(locale.languageCode);
  }

  @override
  Future<I18nDelegate> load(Locale locale) async {
    Intl.defaultLocale = locale.languageCode;
    await initializeDateFormatting(locale.languageCode);
    I18nDelegate localizations = delegateFactory.makeMember(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(LocalizationsDelegate<I18nDelegate> old) {
    return kDebugMode;
  }
}

Future<Map<String, String>> i18nParser(String data) async {
  return _parsei18nJsonData(loadYaml(data), []);
}

/// Parses yaml data structures in to a format where the nested key value structure
/// of for example
///
/// ```yaml
/// key:
///  key2:
///   key3:
///     a: Foo
///     b: Barr
/// ```
///
/// is converted into two key value pairs stored like this
///
/// ```
///   key.key2.key3.a => Foo
///   key.key2.key3.b => Barr
/// ```
Map<String, String> _parsei18nJsonData(YamlMap data, List<String> segments) {
  return data.entries.fold(<String, String>{}, (previousValue, element) {
    if (element.value is YamlMap) {
      previousValue.addAll(_parsei18nJsonData(
          element.value as YamlMap, [...segments, element.key]));
    } else {
      previousValue[[...segments, element.key].join(".")] =
          element.value.toString();
    }
    return previousValue;
  });
}
