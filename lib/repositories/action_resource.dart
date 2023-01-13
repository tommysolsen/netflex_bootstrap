import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflex_bootstrap/exceptions/builders.dart';

abstract class ActionResourceCubit<S> extends Cubit<ActionResourceState<S>> {
  ActionResourceCubit() : super(InitialActionResourceState());

  Future<void> perform(Future<S> Function() action) async {
    try {
      emit(PerformingAction());
      var payload = await action();
      emit(PerformingActionSucceeded(payload));
    } on Exception catch (e) {
      emit(PerformingActionFailed(e));
    }
  }
}

abstract class ActionResourceState<T> extends Equatable {}

class InitialActionResourceState<T> extends ActionResourceState<T> {
  InitialActionResourceState();

  @override
  List<Object?> get props => [];
}

class PerformingAction<T> extends ActionResourceState<T> {
  final DateTime when;

  PerformingAction() : when = DateTime.now();

  @override
  List<Object?> get props => [when];
}

class PerformingActionSucceeded<T> extends ActionResourceState<T> {
  final T payload;

  PerformingActionSucceeded(this.payload);

  @override
  List<Object?> get props =>
      [
        if (payload is List) List.from(payload as List),
        if (payload is Map) Map.from(payload as Map),
        if (payload is! List && payload is! Map) payload
      ];
}

class PerformingActionFailed<T> extends ActionResourceState<T>
    implements ExceptionProvider {
  @override
  final Exception exception;

  PerformingActionFailed(this.exception);

  @override
  List<Object?> get props => [exception];
}

class ActionResourceOverlayBuilder<S extends StateStreamable<T>,
T extends ActionResourceState<V>, V> extends StatelessWidget {
  final Widget Function(BuildContext) overlayBuilder;
  final Widget child;

  const ActionResourceOverlayBuilder(
      {super.key, required this.overlayBuilder, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<S, T>(
      buildWhen: (p, c) => p.runtimeType != c.runtimeType,
      builder: (context, state) =>
          ActionInProgressOverlay(
              inAction: state is PerformingAction<V>,
              overlayBuilder: overlayBuilder,
              child: child),
    );
  }
}

class ActionResourceSucceededListener<S extends StateStreamable<T>,
T extends ActionResourceState<V>, V> extends StatelessWidget {
  final void Function(BuildContext, V) listener;
  final Widget child;

  const ActionResourceSucceededListener(
      {super.key, required this.listener, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<S, T>(
      listenWhen: (p, c) =>
      (p is PerformingActionSucceeded<V>) !=
          (c is PerformingActionSucceeded<V>),
      listener: (context, state) {
        if (state is PerformingActionSucceeded<V>) {
          listener(context, state.payload);
        }
      },
      child: child,
    );
  }
}

class ActionInProgressOverlay extends StatelessWidget {
  final bool inAction;
  final Widget child;
  final Widget Function(BuildContext) overlayBuilder;

  const ActionInProgressOverlay({
    Key? key,
    required this.inAction,
    required this.child,
    required this.overlayBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if(inAction)
          Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              left: 0,
              child: _Overlay(
                child: overlayBuilder(context),
              ))
      ],
    );
  }
}

class _Overlay extends StatelessWidget {
  final Widget child;

  const _Overlay({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: child,
      ),
    );
  }
}
