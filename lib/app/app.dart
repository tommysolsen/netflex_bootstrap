import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflex_bootstrap/app/app_hooks.dart';
import 'package:netflex_bootstrap/app/app_module.dart';
import 'package:netflex_bootstrap/app/app_options.dart';
import 'package:netflex_bootstrap/http/http.dart';
import 'package:netflex_bootstrap/i18n/app_locale_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'app_hooks.dart';
export 'app_module.dart';

typedef Wrapper = Widget Function(Widget child);
typedef EntrypointBuilder = Widget Function();
typedef AppClientBuilder = AppHttpClient Function();
typedef LocaleCubitBuilder = BlocProvider<AppLocaleCubit> Function(
    AppOptionsProvider);

Widget Function(Widget, Wrapper) _wrapChild = (child, wrap) => wrap(child);

extension _WrapChild on List<Wrapper> {
  Widget wrap(Widget child) => reversed.fold(child, _wrapChild);
}

/// App is a simple abstraction flutter in order to more easily segregate
/// "module" code by abstracting the boot process.
///
/// Our approach has us initialize a whole bunch of repositories and such at
/// different times during the boot process.
///
/// We boot the app in the following order
///
/// 1. Locale Independent modules
/// 2. Initialize locale
/// 3. Locale dependent but authentication independent modules
/// 4. Initialize authentication
/// 5. Locale and authentication dependent modules
/// 6. runApp
///
class App {
  List<Wrapper> providers = [];
  List<AppMiddleware> _middlewares = [];

  EntrypointBuilder? _entrypoint;
  AppClientBuilder? _appClientBuilder;
  AppOptionsProvider? _optionsProvider;

  Locale? _locale;
  List<Locale> _supportedLocales;

  App({
    Widget? child,
    AppHttpClient? apiClient,
    Locale? locale,
    List<Locale>? supportedLocales,
  })  : _entrypoint = child != null ? (() => child) : null,
        _appClientBuilder = apiClient != null ? (() => apiClient) : null,
        _locale = locale,
        _supportedLocales =
            supportedLocales ?? (locale != null ? [locale] : []);

  App.builder(this._entrypoint)
      : _locale = null,
        _supportedLocales = [];

  App.child(Widget child)
      : _locale = null,
        _supportedLocales = [] {
    _entrypoint = () => child;
  }

  void setLocale(Locale? locale) => _locale = locale;

  void setSupportedLocales(List<Locale> supportedLocales) =>
      _supportedLocales = supportedLocales;

  void optionsProvider(AppOptionsProvider optionsProvider) =>
      _optionsProvider = optionsProvider;

  /// [entrypointInstance] sets the entrypoint to an instance of a widget
  void entrypointInstance(Widget child) => _entrypoint = () => child;

  /// [entrypointBuilder] sets the builder function that makes the entrypoint
  /// builder
  void entrypointBuilder(EntrypointBuilder builder) => _entrypoint = builder;

  /// [provide] is a shorthand to create a [RepositoryProvider] for your application
  void provide<T>(T value) => providers
    ..add((child) => RepositoryProvider<T>.value(value: value, child: child));

  void add(AppMiddleware middleware) => _middlewares.add(middleware);

  void use(AppModule module) {
    module.install(this);
  }

  void run() {
    assert(_entrypoint != null && _appClientBuilder != null);
    assert(_supportedLocales.isNotEmpty &&
        (_locale == null || _supportedLocales.contains(_locale)));

    var appClient = _appClientBuilder!();

    appClient = _middlewares
        .whereType<LocaleIndependentAppClientMiddleware>()
        .wrap(appClient);

    var child = <Widget Function(Widget)>[
      /// Wrap providers first
      (child) => RepositoryProvider<AppHttpClient>.value(
            value: appClient,
            child: child,
          ),
      (child) => providers.wrap(child),

      /// Then wrap options if it exists
      (child) => _optionsProvider != null
          ? RepositoryProvider<AppOptionsProvider>.value(
              value: _optionsProvider!,
              child: child,
            )
          : child,

      /// Wrap all locale independent middlewares
      (child) =>
          _middlewares.whereType<LocaleIndependentMiddleware>().wrap(child),

      /// Wrap locale dependent builder
      (child) {
        var localeCubit = AppLocaleCubit(_locale, _supportedLocales);
        return BlocProvider.value(
          value: localeCubit,
          child: BlocBuilder<AppLocaleCubit, AppLocaleState>(
            bloc: localeCubit,
            builder: (context, state) {
              return <Widget Function(Widget)>[
                /// Wrap in locale dependent middlewares
                (child) => _middlewares
                    .whereType<LocaleDependentMiddleware>()
                    .wrap(child, state.locale),

                /// Wrap and provide app http client
                (child) => RepositoryProvider<AppHttpClient>.value(
                      value: _middlewares
                          .whereType<LocaleDependentAppClientMiddleware>()
                          .wrap(appClient, state.locale),
                      child: child,
                    ),
              ].fold(child, (child, wrap) => wrap(child));
            },
          ),
        );
      }
    ].reversed.fold(_entrypoint!(), (child, wrap) => wrap(child));

    runApp(child);
  }
}
