import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflex_bootstrap/app/app_hooks.dart';
import 'package:netflex_bootstrap/app/app_module.dart';
import 'package:netflex_bootstrap/app/app_options.dart';
import 'package:netflex_bootstrap/exceptions/async.dart';
import 'package:netflex_bootstrap/http/http.dart';
import 'package:netflex_bootstrap/i18n/app_locale_cubit.dart';

export 'app_hooks.dart';
export 'app_module.dart';

typedef Wrapper = Widget Function(Widget child);
typedef EntrypointBuilder = Widget Function();
typedef SplashBuilder = Widget Function(BuildContext context);
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
  SplashBuilder? splashBuilder;

  App({
    Widget? child,
    AppHttpClient? apiClient,
    Locale? locale,
    List<Locale>? supportedLocales,
    this.splashBuilder,
  })
      : _entrypoint = child != null ? (() => child) : null,
        _appClientBuilder = apiClient != null ? (() => apiClient) : null,
        _locale = locale,
        _supportedLocales =
            supportedLocales ?? (locale != null ? [locale] : []);

  App.builder(this._entrypoint, {
    Locale? locale,
    List<Locale> supportedLocales = const [],
    AppClientBuilder? appClient,
    this.splashBuilder,
  })
      : _locale = locale,
        _appClientBuilder = appClient,
        _supportedLocales = [
          if (locale != null && !supportedLocales.contains(locale)) locale,
          ...supportedLocales
        ];

  App.child(Widget child, {this.splashBuilder})
      : _locale = null,
        _supportedLocales = [] {
    _entrypoint = () => child;
  }

  void setLocale(Locale? locale) {
    _locale = locale;

    if (locale != null && !_supportedLocales.contains(locale)) {
      _supportedLocales.add(locale);
    }
  }

  void setSplashBuilder(SplashBuilder splash) =>
      splashBuilder = splash;

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
  void provide<T>(T value) =>
      providers
        ..add((child) =>
        RepositoryProvider<T>.value(value: value, child: child));

  void add(AppMiddleware middleware) => _middlewares.add(middleware);

  void use(AppModule module) {
    module.install(this);
  }

  Widget _buildFuture(BuildContext context, AsyncSnapshot<Widget> state) {
    if (state.hasError) {
      return Container(child: Text(state.error!.toString()));
    }

    if (state.hasData) {
      return state.data!;
    }

    return splashBuilder != null ? splashBuilder!(context) : Container();
  }

  Future<Widget> get bootstrappedClient async {
    var appClient = _appClientBuilder!();

    appClient = _middlewares
        .whereType<LocaleIndependentAppClientMiddleware>()
        .wrap(appClient);

    var child = await <Future<Widget> Function(Widget)>[

      /// Wrap providers first
          (child) async =>
      RepositoryProvider<AppHttpClient>.value(
        value: appClient,
        child: child,
      ),
          (child) async => providers.wrap(child),

      /// Then wrap options if it exists
          (child) async =>
      _optionsProvider != null
          ? RepositoryProvider<AppOptionsProvider>.value(
        value: _optionsProvider!,
        child: child,
      )
          : child,

      /// Wrap all locale independent middlewares
          (child) =>
          _middlewares.whereType<LocaleIndependentMiddleware>().wrap(child),

      /// Wrap locale dependent builder
          (child) async {
        var localeCubit = AppLocaleCubit(_locale, _supportedLocales);
        return BlocProvider.value(
          value: localeCubit,
          child: BlocBuilder<AppLocaleCubit, AppLocaleState>(
            bloc: localeCubit,
            builder: (context, state) {
              var future = <Future<Widget> Function(Widget)>[

                /// Wrap in locale dependent middlewares
                    (child) async =>
                    _middlewares
                        .whereType<LocaleDependentMiddleware>()
                        .wrap(child, state.locale),

                /// Wrap and provide app http client
                    (child) async =>
                RepositoryProvider<AppHttpClient>.value(
                  value: _middlewares
                      .whereType<LocaleDependentAppClientMiddleware>()
                      .wrap(
                      appClient.withMiddlewares(
                          [LocaleSetter(state.locale)]),
                      state.locale),
                  child: child,
                ),
              ].foldAsync(child, (child, wrap) => wrap(child));

              return FutureBuilder(
                future: future,
                builder: _buildFuture,
              );
            },
          ),
        );
      }
    ].reversed.foldAsync(_entrypoint!(), (child, wrap) => wrap(child));

    return child;
  }

  void run() {
    assert(_entrypoint != null && _appClientBuilder != null);
    assert(
    _supportedLocales.isNotEmpty &&
        (_locale == null || _supportedLocales.contains(_locale)),
    );

    runApp(
      FutureBuilder(
        future: bootstrappedClient,
        builder: _buildFuture,
      ),
    );
  }
}
