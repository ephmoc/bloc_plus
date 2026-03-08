import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Adds null-safe bloc lookup helpers to [BuildContext].
extension BlocContextExtension on BuildContext {
  /// Returns the bloc from the nearest provider, or `null` when no provider is
  /// found.
  B? readOrNull<B extends BlocBase<Object?>>() {
    try {
      return read<B>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// Returns the watched bloc from the nearest provider, or `null` when no
  /// provider is found.
  B? watchOrNull<B extends BlocBase<Object?>>() {
    try {
      return watch<B>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// Selects a value from the nearest bloc state, or returns `null` when no
  /// provider is found.
  T? selectOrNull<B extends BlocBase<S>, S, T>(T Function(S state) selector) {
    try {
      return select<B, T>((bloc) => selector(bloc.state));
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// Runs [fn] with the nearest bloc when present, otherwise returns `null`.
  R? withBloc<B extends BlocBase<Object?>, R>(R Function(B bloc) fn) {
    final bloc = readOrNull<B>();
    if (bloc == null) return null;
    return fn(bloc);
  }
}
