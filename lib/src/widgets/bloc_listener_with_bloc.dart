import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Signature for listening to state changes with access to the resolved bloc.
typedef BlocWidgetListenerWithBloc<B extends StateStreamable<S>, S> = void
    Function(BuildContext context, B bloc, S state);

/// A [BlocListenerBase] variant that also passes the resolved bloc instance to
/// the listener callback.
///
/// Like `BlocListener`, when [bloc] changes from an instance to `null` it
/// keeps listening to that instance, while the callback receives the provided
/// bloc. Give the widget a new `key` when you switch between an explicit and a
/// provided bloc.
class BlocListenerWithBloc<B extends StateStreamable<S>, S>
    extends BlocListenerBase<B, S> {
  /// Creates a listener widget that exposes the bloc and state to [listener].
  const BlocListenerWithBloc({
    required BlocWidgetListenerWithBloc<B, S> listener,
    super.key,
    super.bloc,
    super.listenWhen,
    super.child,
  })  : _listener = listener,
        super(listener: _unused);

  final BlocWidgetListenerWithBloc<B, S> _listener;

  @override
  BlocWidgetListener<S> get listener =>
      (context, state) => _listener(context, bloc ?? context.read<B>(), state);
}

// Never called: the BlocListenerWithBloc.listener getter replaces it. It only
// lets the constructor pass a constant to the superclass.
void _unused(BuildContext context, Object? state) {} // coverage:ignore-line
