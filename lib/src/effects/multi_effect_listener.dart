import 'package:flutter/widgets.dart';

import 'effect_listener.dart';

/// Composes multiple [EffectListener] widgets into a single tree level.
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
