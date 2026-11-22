// The deprecated widgets refer to each other until their removal in 1.0.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/widgets.dart';

import 'effect_listener.dart';

/// Composes multiple [EffectListener] widgets into a single tree level.
@Deprecated(
  'Use MultiBlocListener with BlocEffectListener<B, E> listeners. '
  'Will be removed in 1.0.',
)
class MultiEffectListener extends StatelessWidget {
  /// Creates a widget that nests [listeners] around [child].
  const MultiEffectListener({
    required this.listeners,
    required this.child,
    super.key,
  });

  /// The effect listeners to compose around [child].
  final List<SingleChildEffectListener> listeners;

  /// The widget subtree wrapped by all [listeners].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return listeners.reversed.fold<Widget>(
      child,
      (currentChild, listener) => listener.withChild(currentChild),
    );
  }
}
