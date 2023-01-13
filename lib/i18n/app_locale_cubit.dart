import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflex_bootstrap/app/app_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleCubit extends Cubit<AppLocaleState> {
  AppLocaleCubit(Locale? locale, List<Locale> supportedLocales)
      : super(
          AppLocaleState.determine(
            locale,
            supportedLocales,
          ),
        );
}

abstract class AppLocaleState extends Equatable {
  /// Contains a list of all supported locales of the application
  List<Locale> get supportedLocales;

  /// Get the current locale
  Locale get locale;

  const AppLocaleState();

  /// [AppLocaleState.determine] determines which locale to load and which state
  /// the app in based on two simple criteria.
  ///
  /// If the [locale] key is not null, then this indicates the user has decided
  /// itself which locale to used (for example through a settings page
  ///
  /// If [locale] is null, then we pick the first valid locale from the list of
  /// locales as indicated by the device. (Both iOS and Android can rank locales)
  ///
  /// In either case, if the selected locale is not(or no longer) among the list of
  /// supportedLocales, or the device does not list any supported locales
  /// then we pick the first available locale in the [supportedLocales] list
  /// as our locale
  factory AppLocaleState.determine(
    Locale? locale,
    List<Locale> supportedLocales,
  ) =>
      _maybeResolveLocale(locale, supportedLocales) ??
      AutomaticLocale(supportedLocales);

  @override
  List<Object> get props => [locale];

  static Locale _resolveLocales(
      Iterable<Locale> locales, Iterable<Locale> supportedLocales) {
    if (locales.isEmpty) {
      return supportedLocales.first;
    }

    for (var locale in locales) {
      for (var supportedLocale in supportedLocales) {
        if (locale.languageCode == supportedLocale.languageCode) {
          return supportedLocale;
        }
      }
    }
    return supportedLocales.first;
  }

  static Locale _resolveLocale(
      Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) {
      return supportedLocales.first;
    }
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }
    return supportedLocales.first;
  }

  static ManuallySelectedLocale? _maybeResolveLocale(
      Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null || locale.languageCode == "") return null;
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode &&
          supportedLocale.countryCode == locale.countryCode) {
        return ManuallySelectedLocale(
            locale, supportedLocales.toList(growable: false));
      }
    }
    return null;
  }
}

class LocaleInitial extends AppLocaleState {
  final List<Locale> systemLocales;

  @override
  final List<Locale> supportedLocales;

  const LocaleInitial(this.systemLocales, this.supportedLocales) : super();

  @override
  Locale get locale => systemLocales.firstWhere(
      (element) =>
          AppLocaleState._maybeResolveLocale(element, supportedLocales) != null,
      orElse: () => supportedLocales.first);
}

class AutomaticLocale extends AppLocaleState {
  @override
  final List<Locale> supportedLocales;

  AutomaticLocale(this.supportedLocales);

  @override
  Locale get locale =>
      AppLocaleState._resolveLocales(window.locales, supportedLocales);
}

class ManuallySelectedLocale extends AppLocaleState {
  @override
  final List<Locale> supportedLocales;
  final Locale _locale;

  const ManuallySelectedLocale(this._locale, this.supportedLocales);

  @override
  Locale get locale => AppLocaleState._resolveLocale(_locale, supportedLocales);
}
