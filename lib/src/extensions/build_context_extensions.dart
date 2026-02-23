import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension BlocContextExtension on BuildContext {
  B? readOrNull<B extends BlocBase<Object?>>() {
    try {
      return read<B>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  B? watchOrNull<B extends BlocBase<Object?>>() {
    try {
      return watch<B>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  T? selectOrNull<B extends BlocBase<S>, S, T>(T Function(S state) selector) {
    try {
      return select<B, T>((bloc) => selector(bloc.state));
    } on ProviderNotFoundException {
      return null;
    }
  }

  R? withBloc<B extends BlocBase<Object?>, R>(R Function(B bloc) fn) {
    final bloc = readOrNull<B>();
    if (bloc == null) return null;
    return fn(bloc);
  }
}
