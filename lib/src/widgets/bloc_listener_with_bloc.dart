import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

typedef BlocWidgetListenerWithBloc<B extends BlocBase<S>, S> = void Function(
    BuildContext context, B bloc, S state);

class BlocListenerWithBloc<B extends BlocBase<S>, S>
    extends BlocListenerBase<B, S> {
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
