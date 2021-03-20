import 'dart:async';
import 'helpers/stream_exception.dart';
import 'helpers/typedefs.dart';
import 'stream_value.dart';

/// Base class implemented by classes that provide an event listener.
abstract class StreamEventProvider<T, E> extends StreamValue<T> {
  /// Base constructor implemented by classes that provide an event listener.
  StreamEventProvider(T value, {OnUpdate<T>? onUpdate, this.onEvent})
      : super(value, onUpdate: onUpdate);

  /// Called when an element is added, removed, or updated in the
  /// list/map before [onUpdate] is called and before the listeners
  /// are notified of the new value.
  OnEvent<E>? onEvent;

  /// The list of active event listeners.
  final List<StreamSubscription<E>> _eventSubscriptions =
      <StreamSubscription<E>>[];

  /// The active event [StreamController].
  final StreamController<E> _eventNotifier = StreamController<E>.broadcast();

  /// Registers a new [StreamSubscription] that provides a
  /// [CollectionEvent] denoting when any elements have been added,
  /// removed, or updated in the collection.
  StreamSubscription<E> addEventListener(OnEvent<E> onEvent) {
    _eventSubscriptions.add(
      _eventNotifier.stream.asBroadcastStream().listen(onEvent),
    );

    return _eventSubscriptions.last;
  }

  /// Returns `true` if there are any active update listeners
  /// or if [onUpdate] is set.
  bool get hasUpdate => wasDisposed ? false : hasListener || onUpdate != null;

  /// Returns `true` if there are any active event listeners
  /// or if [onEvent] is set.
  bool get hasEvent =>
      wasDisposed ? false : hasEventListener || onEvent != null;

  /// Returns `true` if there are any active event listeners.
  bool get hasEventListener => _eventSubscriptions.isNotEmpty;

  /// Returns the number of active event listeners.
  int get numberOfEventListeners => _eventSubscriptions.length;

  @override
  bool get isObserved => wasDisposed ? false : hasEvent || super.isObserved;

  /// Cancels and removes an event listener.
  void removeEventListener() {
    _eventSubscriptions.last.cancel();
    _eventSubscriptions.removeLast();
  }

  /// Notifies all subscribed event listeners of an [event].
  void notifyEventListeners(E event) {
    if (wasDisposed && hasEvent) throw StreamException();
    if (onEvent != null) onEvent!(event);
    if (hasEventListener) _eventNotifier.sink.add(event);
  }

  @override
  void dispose() {
    for (var subscription in _eventSubscriptions) {
      subscription.cancel();
    }
    _eventSubscriptions.clear();
    _eventNotifier.close();
    super.dispose();
  }
}
