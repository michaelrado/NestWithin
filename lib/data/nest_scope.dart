import 'package:flutter/widgets.dart';
import 'nest_store.dart';

/// Exposes the [NestStore] to the widget tree and rebuilds dependents when it
/// changes. Lightweight stand-in for a state-management package.
class NestScope extends InheritedNotifier<NestStore> {
  const NestScope({super.key, required NestStore store, required super.child})
    : super(notifier: store);

  static NestStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NestScope>();
    assert(scope != null, 'NestScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Read without subscribing to rebuilds (for one-off actions).
  static NestStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<NestScope>();
    assert(scope != null, 'NestScope not found in widget tree');
    return scope!.notifier!;
  }
}
