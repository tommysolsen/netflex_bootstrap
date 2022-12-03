import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bootstrap/exceptions/exceptions.dart';
import 'package:flutter_bootstrap/i18n/i18n.dart';

/// The ExceptionProvider interface describes if a class contains an exception
/// that we want to display to a user.
abstract class ExceptionProvider {
  Exception get exception;
}

/// The ExceptionBuilder will check the state of matching block in the context
/// and will run the render method with the error message if the state is an
/// [ExceptionProvider].
///
/// In the case there are no exceptions to render, the exception message will be
/// null.
///
/// The idea is that you make any error reporting state that you want to
/// show to the user implement the exception provider. Then use this exception builder
/// in your code to render the message when it is called for.
abstract class BaseExceptionBuilder<S extends StateStreamable<T>, T>
    extends BlocBuilderBase<S, T> {
  /// Optional direct reference to the [I18nDelegate]. This is primarilly
  /// to decrease the need to run [I18n.of] multiple times in the same view
  final I18nDelegate? delegate;

  /// A builder function that is meant to render the exception message from
  /// the exception provider.
  Widget Function(BuildContext context, String? message) get builder;

  BaseExceptionBuilder({this.delegate, super.key});

  @override
  BlocBuilderCondition<T>? get buildWhen => (p, c) =>
      (p is ExceptionProvider != c is ExceptionProvider) ||
      (p is ExceptionProvider &&
          c is ExceptionProvider &&
          p.exception != c.exception);

  @override
  Widget build(BuildContext context, T state) {
    if (state is ExceptionProvider) {
      I18nDelegate i = delegate ?? I18n.of(context);
      return builder(context, i.translateException(state.exception));
    }
    return builder(context, null);
  }
}

/// ExceptionBuilder is the base implementation of the function that takes a
/// builder function to render messages.
///
/// If you have custom requirements for your styling, it might be beneficial for
/// you to extend the base class and implement the layout there instead of
/// having to pass the builder function around all the time.
///
class ExceptionBuilder<B extends StateStreamable<S>, S>
    extends BaseExceptionBuilder<B, S> {
  @override
  final Widget Function(BuildContext context, String? message) builder;

  ExceptionBuilder({
    super.delegate,
    required this.builder,
    super.key,
  });
}

/// Joins all errors into one large string
///
String joinErrors(BuildContext context, List<String> reasons) => reasons.join(", ");

/// Picks first exception and shows that
///
String onlyFirst(BuildContext context, List<String> reasons) => reasons.first;

/// The [ValidationExceptionBuilder] is a variation of the normal [ExceptionBuilder]
/// that only shows validation exceptions for individual fields that may or may not have
/// validation errors.
///
/// This is mostly for form validation on a field to field basis.
class ValidationExceptionBuilder<S extends StateStreamable<T>, T>
    extends ExceptionBuilder<S, T> {
  /// The [field] describes which key submitted to the server you want to
  /// get validation errors for.
  final String field;

  /// Describes how you want to present validation errors for.
  /// The main idea of this widget is to show only one line of message (for example under a text box)
  ///
  /// If no value is set here [onlyFirst] is used.
  final String Function(BuildContext context, List<String> reasons) formatter;

  ValidationExceptionBuilder(
    this.field, {
    this.formatter = onlyFirst,
    super.delegate,
    super.key,
    required super.builder,
  });

  @override
  BlocBuilderCondition<T>? get buildWhen => _stateIsDifferent(field);

  @override
  Widget build(BuildContext context, T state) {
    if (state is ExceptionProvider) {

      // Get list of errors for field or in case of null use empty array
      var reasons = _getUnprocessableEntry(state.exception)
              ?.validationErrorsForField(field) ??
          [];

      if (reasons.isNotEmpty) {
        return builder(context, formatter(context, reasons));
      }
    }

    return builder(context, null);
  }
}

bool _stateIsValidationException(dynamic a) =>
    a is ExceptionProvider && a.exception is UnprocessableEntryException;

UnprocessableEntryException? _getUnprocessableEntry(dynamic e) =>
    (_stateIsValidationException(e)
        ? (e as ExceptionProvider).exception as UnprocessableEntryException
        : null);

bool Function(dynamic, dynamic) _stateIsDifferent(String field) => (a, b) {
      // If this fact has changed we need to change state
      if (_stateIsValidationException(a) != _stateIsValidationException(b)) {
        return true;
      }

      var aE = _getUnprocessableEntry(a);
      var bE = _getUnprocessableEntry(b);

      return aE?.validationErrorsForField(a) != bE?.validationErrorsForField(b);
    };
