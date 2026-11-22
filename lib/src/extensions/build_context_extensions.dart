import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Adds null-safe lookup helpers to [BuildContext].
///
/// They work for blocs and for any other provided type, such as a repository.
extension BlocContextExtension on BuildContext {
  /// Returns the [B] from the nearest provider, or `null` when there is no
  /// provider of [B] above this context.
  ///
  /// Other errors, such as one thrown while the provider creates the bloc, are
  /// rethrown.
  B? readOrNull<B extends Object>() => read<B?>();

  /// Returns the watched [B] from the nearest provider, or `null` when there is
  /// no provider of [B] above this context.
  ///
  /// The widget also rebuilds when a provider of [B] appears later, for
  /// example after the widget moves under one. Other errors are rethrown.
  B? watchOrNull<B extends Object>() => watch<B?>();

  /// Selects a value from the state of the nearest [B], or returns `null` when
  /// there is no provider of [B] above this context.
  ///
  /// The widget rebuilds when the selected value changes after the provider
  /// notifies, which `BlocProvider` does on every state. Errors thrown by
  /// [selector] or while creating the bloc are rethrown.
  T? selectOrNull<B extends StateStreamableSource<S>, S, T>(
    T Function(S state) selector,
  ) {
    return select<B?, T?>(
      (bloc) => bloc == null ? null : selector(bloc.state),
    );
  }

  /// Runs [fn] with the [B] from the nearest provider when present, otherwise
  /// returns `null`.
  ///
  /// Like [readOrNull], it rethrows errors other than a missing provider.
  R? withBloc<B extends Object, R>(R Function(B bloc) fn) {
    final bloc = readOrNull<B>();
    if (bloc == null) return null;
    return fn(bloc);
  }
}
