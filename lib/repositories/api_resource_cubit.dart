import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflex_bootstrap/exceptions/builders.dart';
import 'package:netflex_bootstrap/netflex_bootstrap.dart';


/// [ApiResourceCubit] is a cubit that queries and refreshes data in an
/// [BasicApiResourceRepository].
///
/// Initiating the cubit will refresh the internal data in two cases.
///
/// 1. When the [refresh] flag is set when constructing the object
/// 2. When the [BasicApiResourceRepository] has not been initialized yet.
///
abstract class ApiResourceCubit<K> extends Cubit<ApiResourceState<K>> {

  /// Any [BasicApiResourceRepository] whose type matches that of the block
  final BasicApiResourceRepository<K> repository;

  /// Internal reference to the repository data stream, will be disposed of
  /// when this widget is disposed of
  late StreamSubscription _streamSubscription;

  ApiResourceCubit({
    /// Describes the repository the cubit is controlled by.
    required this.repository,

    /// Describes the initial state of the application
    required K init,

    /// Describes whether or not the initial state is to be considered an initialized
    /// one. Could be set to true if you have hardcoded data in your application
    /// that should be shown prior to data being loaded from the Repository.
    bool initialized = false,

    /// Should we force the [BasicApiResourceRepository] to refresh its data
    /// immediately?
    bool refresh = false
  }) : super(ApiResourceInitialState(initialized, init)) {
    repository.stream.listen((event) {
      emit(ApiResourceLoadedState(event));
    });

    if (refresh || !repository.initialized) {
      refreshData();
    }
  }

  /// Runs the [refresh] method on the [repository]. In the case of an exception
  /// an [ApiResourceFailedState] will be emitted.
  /// On success an [ApiResourceLoadedState] will be emitted
  Future<void> refreshData() async {
    try {
      await repository.refresh();
    } on Exception catch (exception) {
      emit(ApiResourceFailedState(state.isLoaded, state.data, exception));
    }
  }

  @override
  Future<void> close() {
    _streamSubscription.cancel();
    return super.close();
  }

}

/// Represents the state of the application and returns the information stored
/// in the repository, as well as metadata about the information.
abstract class ApiResourceState<K> extends Equatable {

  /// [isLoaded] describes if the state isLoaded or not. The data needs to have
  /// been loaded at least once.
  /// If this is the case, even if loading data fails later, the isLoaded flag
  /// will return true.
  bool get isLoaded;

  /// [data] holds the data returned from the [BasicApiResourceRepository].
  /// We use equatable in order to determine if the data has changed. If
  /// data is of a type that normally is hard to [==] then it needs to implement
  /// [Equatable] in order to work properly.
  K get data;

  @override
  List<Object?> get props => [ isLoaded, data ];
}


/// Represents a state where the cubit was able to load its data successfully
/// without any issues.
class ApiResourceLoadedState<K> extends ApiResourceState<K> {
  @override
  bool get isLoaded => true;

  @override
  final K data;

  ApiResourceLoadedState(this.data);
}


/// Represents the initial state of the application. Data has not been loaded
/// yet.
class ApiResourceInitialState<K> extends ApiResourceState<K> {
  @override
  final bool isLoaded;
  @override
  final K data;

  ApiResourceInitialState(this.isLoaded, this.data);
}

/// Represents a state where updating the state of the application failed.
/// The exception will be available for introspection.
///
/// This state class also implements [ExceptionProvider] for easy translated
/// exceptions that can be built in your app.
class ApiResourceFailedState<K> extends ApiResourceState<K> implements ExceptionProvider {
  @override
  final bool isLoaded;

  @override
  final K data;

  @override
  final Exception exception;

  ApiResourceFailedState(this.isLoaded, this.data, this.exception);
}
