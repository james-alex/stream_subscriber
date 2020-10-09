import 'dart:async';
import 'helpers/typedefs.dart';

/// A minimal set of methods to add and manage [StreamSubscription]s on
/// any class.
///
/// Once mixed into a class, listeners can be created and removed with
/// the [addListener] and [removeListener] methods respectively.
///
/// Call [notifyListeners] to notify all listeners of any of an event
/// and optionally pass [event] data down the [StreamSink].
///
/// The [StreamController] is created once on initialization as
/// [updateNotifier]. Once closed, it cannot be reopened.
///
/// Any class that mixes in [StreamSubscriber] should call [closeStream] or
/// [dispose] when it is no longer needed. If the implementing class overrides
/// [dispose], [closeStream] should be called by the overridden [dispose] method
/// unless its called elsewhere.
mixin StreamSubscriber<T> {
  /// The list of active listeners.
  final List<StreamSubscription<T>> _subscriptions = <StreamSubscription<T>>[];

  /// A broadcast stream [StreamController].
  final StreamController<T> _updateNotifier = StreamController<T>.broadcast();

  /// Creates, stores and returns a listener.
  StreamSubscription<T> addListener(OnUpdate<T> onUpdate) {
    _subscriptions.add(
      _updateNotifier.stream.asBroadcastStream().listen(onUpdate),
    );

    return _subscriptions.last;
  }

  /// Returns `true` if there are any active listeners.
  bool get hasListener => _subscriptions.isNotEmpty;

  /// Returns the number of active listeners.
  int get numberOfListeners => _subscriptions.length;

  /// Cancels and removes a [StreamSubscription].
  void removeListener() {
    _subscriptions.last.cancel();
    _subscriptions.removeLast();
  }

  /// Notifies all subscribed listeners of an event.
  void notifyListeners(T event) {
    if (hasListener) {
      _updateNotifier.sink.add(event);
    }
  }

  /// Cancels any active listeners and closes the stream.
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }

    _subscriptions.clear();
    _updateNotifier.close();
  }
}
