import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Adds null-safe bloc lookup helpers to [BuildContext].
extension BlocContextExtension on BuildContext {
  /// Returns the bloc from the nearest provider, or `null` when there is no
  /// provider of [B] above this context.
  ///
  /// Other errors, such as one thrown while the provider creates the bloc, are
  /// rethrown.
  B? readOrNull<B extends BlocBase<Object?>>() => read<B?>();

  /// Returns the watched bloc from the nearest provider, or `null` when there
  /// is no provider of [B] above this context.
  ///
  /// The widget also rebuilds when a provider of [B] appears later, for
  /// example after the widget moves under one. Other errors are rethrown.
  B? watchOrNull<B extends BlocBase<Object?>>() => watch<B?>();

  /// Selects a value from the nearest bloc state, or returns `null` when there
  /// is no provider of [B] above this context.
  ///
  /// Errors thrown by [selector] or while creating the bloc are rethrown.
  T? selectOrNull<B extends BlocBase<S>, S, T>(T Function(S state) selector) {
    return select<B?, T?>(
      (bloc) => bloc == null ? null : selector(bloc.state),
    );
  }

  /// Runs [fn] with the nearest bloc when present, otherwise returns `null`.
  ///
  /// Like [readOrNull], it rethrows errors other than a missing provider.
  R? withBloc<B extends BlocBase<Object?>, R>(R Function(B bloc) fn) {
    final bloc = readOrNull<B>();
    if (bloc == null) return null;
    return fn(bloc);
  }
}
