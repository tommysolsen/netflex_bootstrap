import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:netflex_bootstrap/netflex_bootstrap.dart';

class FullScreenApiResourceBuilder<K extends ApiResourceCubit<Y>, Y>
    extends StatelessWidget {
  final Widget Function(BuildContext context, Y data) builder;
  final Widget Function(BuildContext context, ApiResourceFailedState<Y> state)
      exceptionBuilder;
  final Widget Function(BuildContext context, ApiResourceState<Y> state)
      loadingState;
  final bool Function(ApiResourceState<Y>, ApiResourceState<Y>)? buildWhen;

  const FullScreenApiResourceBuilder(
      {
      required this.builder,
      super.key,
      this.buildWhen,
      required this.exceptionBuilder,
      required this.loadingState});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<K, ApiResourceState<Y>>(
        buildWhen: buildWhen ?? (p, c) => p != c,
        builder: (context, state) {
          if (!state.isLoaded && state is! ApiResourceFailedState<Y>) {
            return loadingState(context, state);
          }

          if (state is ApiResourceFailedState<Y>) {
            return exceptionBuilder(context, state);
          }

          return builder(context, state.data);
        });
  }
}
