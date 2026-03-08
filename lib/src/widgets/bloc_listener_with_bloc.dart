import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Signature for listening to state changes with access to the resolved bloc.
typedef BlocWidgetListenerWithBloc<B extends BlocBase<S>, S> = void Function(
    BuildContext context, B bloc, S state);

/// A [BlocListenerBase] variant that also passes the resolved bloc instance to
/// the listener callback.
class BlocListenerWithBloc<B extends BlocBase<S>, S>
    extends BlocListenerBase<B, S> {
  /// Creates a listener widget that exposes the bloc and state to [listener].
  BlocListenerWithBloc({
    required BlocWidgetListenerWithBloc<B, S> listener,
    super.key,
    super.bloc,
    super.listenWhen,
    super.child,
  }) : super(
          listener: (context, state) {
            final resolvedBloc = bloc ?? context.read<B>();
            listener(context, resolvedBloc, state);
          },
        );
}
