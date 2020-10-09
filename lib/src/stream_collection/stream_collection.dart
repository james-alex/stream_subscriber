import 'dart:async';
import '../helpers/stream_exception.dart';
import '../helpers/typedefs.dart';
import '../stream_event_provider.dart';

export 'stream_list.dart';
export 'stream_map.dart';
export 'stream_set.dart';

/// The type of event made to a [StreamCollection].
enum CollectionEventType {
  /// Indicates element(s) were added to a collection.
  addition,

  /// Indicates element(s) were removed from a collection.
  removal,

  /// Indicates element(s) were modified in a collection.
  update,
}

/// An event containing changes made to a [StreamCollection], returned
/// by a collection's event listeners and [onEvent] parameter.
class CollectionEvent<K, V> {
  /// An event containing changes made to a [StreamCollection].
  const CollectionEvent(this.type, this.elements)
      : assert(type != null),
        assert(elements != null);

  /// The type of change made to the collection: addition, removal, or update.
  final CollectionEventType type;

  /// The elements that were affected by the event.
  ///
  /// For [StreamList]s and [StreamSet]s the key will be the
  /// index of the elements. In the event of a removal, the
  /// key/index will no longer be present in the collection
  /// when this event is received.
  final Map<K, V> elements;

  /// Returns the keys/indexes of the [elements] affected by the event as a list.
  List<K> get keys => elements.keys.toList();

  /// Returns the values of the [elements] affected by the event as a list.
  List<V> get values => elements.values.toList();
}

/// An event containing a single change made to a [StreamCollection], returned
/// by a collection's change listeners and [onChange] parameter.
class CollectionChangeEvent<K, V> {
  /// An event containing a single change made to a [StreamCollection].
  const CollectionChangeEvent(this.type, this.key, this.value)
      : assert(type != null);

  /// The type of change made to the collection: addition, removal, or update.
  final CollectionEventType type;

  /// The key or index of the affected element.
  final K key;

  /// The value of the affected element.
  final V value;
}

/// The base class for an observable collection of elements (list, map, or set.)
abstract class StreamCollection<C, K, V>
    extends StreamEventProvider<C, CollectionEvent<K, V>> {
  /// The base class for an observable collection of elements
  /// (list, map, or set.)
  ///
  /// [collection] must not be `null`.
  ///
  /// [onUpdate] is a synchronous event called each time the collection
  /// is modified and receives the entire collection as a parameter.
  ///
  /// [onEvent] is a synchronous event called each time the collection
  /// is modified, and receives a list of all of the affected elements.
  ///
  /// [onChange] is a synchronous event called individually for every
  /// element added, removed, or updated in the collection.
  StreamCollection(
    C collection, {
    OnUpdate<C> onUpdate,
    OnEvent<CollectionEvent<K, V>> onEvent,
    this.onChange,
  })  : assert(collection != null),
        super(collection, onUpdate: onUpdate, onEvent: onEvent);

  /// A synchronous event called individually for every element added,
  /// removed, or updated in the collection.
  OnChange<CollectionChangeEvent<K, V>> onChange;

  /// The list of active change listeners.
  final List<StreamSubscription<CollectionChangeEvent<K, V>>>
      _changeSubscriptions =
      <StreamSubscription<CollectionChangeEvent<K, V>>>[];

  /// The active change [StreamController].
  final StreamController<CollectionChangeEvent<K, V>> _changeNotifier =
      StreamController<CollectionChangeEvent<K, V>>.broadcast();

  /// Registers a new [StreamSubscription] that provides a
  /// [CollectionChangeEvent] denoting when an element has been added,
  /// removed, or updated in the collection.
  StreamSubscription<CollectionChangeEvent<K, V>> addChangeListener(
      OnChange<CollectionChangeEvent<K, V>> onChange) {
    _changeSubscriptions.add(
      _changeNotifier.stream.asBroadcastStream().listen(onChange),
    );

    return _changeSubscriptions.last;
  }

  /// Returns `true` if there are any active change listeners
  /// or if [onChange] is set.
  bool get hasChangeEvent =>
      wasDisposed ? false : hasChangeListener || onChange != null;

  /// Returns `true` if there are any active change listeners.
  bool get hasChangeListener => _changeSubscriptions.isNotEmpty;

  /// Returns the number of active change listeners.
  int get numberOfChangeListeners => _changeSubscriptions.length;

  @override
  bool get isObserved =>
      wasDisposed ? false : hasChangeEvent || super.isObserved;

  /// Cancels and removes a change listener.
  void removeChangeListener() {
    _changeSubscriptions.last.cancel();
    _changeSubscriptions.removeLast();
  }

  /// Notifies all subscribed changes listeners of an [event].
  void notifyChangeListeners(CollectionChangeEvent<K, V> event) {
    if (wasDisposed && hasChangeEvent) {
      throw StreamException();
    }

    if (onChange != null) {
      onChange(event);
    }

    if (hasChangeListener) {
      _changeNotifier.sink.add(event);
    }
  }

  /// Notifies every active update, event, and change listener, as well as
  /// the [onUpdate], [onEvent], and [onChange] parameters of an event
  /// affecting a single element.
  void notifyAllListeners(CollectionEventType type, K key, V value) {
    if (hasChangeEvent) {
      notifyChangeListeners(
        CollectionChangeEvent(type, key, value),
      );
    }

    if (hasEvent) {
      notifyEventListeners(CollectionEvent(type, <K, V>{key: value}));
    }

    if (hasUpdate) {
      notifyListeners(this.value);
    }
  }

  @override
  void dispose() {
    for (var subscription in _changeSubscriptions) {
      subscription.cancel();
    }

    _changeSubscriptions.clear();
    _changeNotifier.close();

    super.dispose();
  }
}
