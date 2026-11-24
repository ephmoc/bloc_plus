import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';

/// Signature for listening to state changes with access to the resolved bloc.
typedef BlocWidgetListenerWithBloc<B extends StateStreamable<S>, S> = void
    Function(BuildContext context, B bloc, S state);

/// A `BlocListener` whose [listener] also receives the resolved bloc.
///
/// The bloc is resolved once per build, so the state and the bloc that
/// [listener] receives come from one instance. The widget follows the
/// provided bloc right after [bloc] changes from an instance to `null`, and
/// when a different instance is provided. It composes inside
/// `MultiBlocListener`.
class BlocListenerWithBloc<B extends StateStreamable<S>, S>
    extends SingleChildStatelessWidget {
  /// Creates a listener widget that exposes the bloc and state to [listener].
  const BlocListenerWithBloc({
    required this.listener,
    super.key,
    this.bloc,
    this.listenWhen,
    this.child,
  }) : super(child: child);

  /// The bloc to listen to.
  ///
  /// When omitted, the widget reads the bloc from the nearest provider and
  /// throws a `ProviderNotFoundException` if there is none.
  final B? bloc;

  /// Optional predicate that controls whether [listener] runs for a state
  /// change.
  final BlocListenerCondition<S>? listenWhen;

  /// Called in response to state changes with the resolved bloc instance.
  final BlocWidgetListenerWithBloc<B, S> listener;

  /// The subtree below the listener; `MultiBlocListener` supplies it when the
  /// listener is one of its `listeners`. Outside `MultiBlocListener` it is
  /// required, and a missing child fails an assertion in debug builds.
  final Widget? child;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    // Names this widget; the BlocListener below would name itself.
    assert(
      child != null,
      '$runtimeType used outside of MultiBlocListener must specify a child',
    );
    // Rebuilds only when a different instance is provided.
    final resolvedBloc = bloc ?? context.select<B, B>((bloc) => bloc);
    return BlocListener<B, S>(
      bloc: resolvedBloc,
      listenWhen: listenWhen,
      listener: (context, state) => listener(context, resolvedBloc, state),
      child: child,
    );
  }
}
