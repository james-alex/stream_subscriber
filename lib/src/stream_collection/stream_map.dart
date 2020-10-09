import '../helpers/typedefs.dart';
import 'stream_collection.dart';

typedef _Compute<K> = K Function(dynamic value);

typedef _ForEach<K, V> = void Function(K key, V value);

typedef _Mapper<K, K2, V, V2> = MapEntry<K2, V2> Function(K key, V value);

typedef _IfAbsent<V> = V Function();

typedef _Predicate<K, V> = bool Function(K key, V value);

typedef _Update<V> = V Function(V value);

typedef _Updater<K, V> = V Function(K key, V value);

/// [StreamMap] wraps a [Map] and adds functionality to each relevant method
/// to notify any subscribed listeners of changes made to the map.
class StreamMap<K, V> extends StreamCollection<Map<K, V>, K, V>
    implements Map<K, V> {
  /// [StreamMap] wraps a [Map] and adds functionality to each relevant method
  /// to notify any subscribed listeners of changes made to the map.
  ///
  /// [value] can be provided to return a [StreamMap] that references
  /// [value], if `null` an empty list will be created instead. __Note:__
  /// Modifications made to the map by referencing [value] will not notify
  /// the listeners of the changes made to it.
  ///
  /// [onUpdate] is a synchronous event called each time the collection
  /// is modified and receives the entire collection as a parameter.
  ///
  /// [onEvent] is a synchronous event called each time the collection
  /// is modified, and receives a list of all of the affected elements.
  ///
  /// [onChange] is a synchronous event called individually for every
  /// element added, removed, or updated in the collection.
  StreamMap({
    Map<K, V> value,
    OnUpdate<Map<K, V>> onUpdate,
    OnEvent<CollectionEvent<K, V>> onEvent,
    OnChange<CollectionChangeEvent<K, V>> onChange,
  }) : super(value ?? <K, V>{},
            onUpdate: onUpdate, onEvent: onEvent, onChange: onChange);

  /// Creates a [StreamMap] wrapped around a [LinkedHashMap] instance
  /// that contains all key/value pairs of [other].
  ///
  /// The keys must all be instances of [K] and the values of [V].
  /// The [other] map itself can have any type.
  ///
  /// A `LinkedHashMap` requires the keys to implement compatible
  /// `operator==` and `hashCode`, and it allows `null` as a key.
  /// It iterates in key insertion order.
  factory StreamMap.from(
    Map<K, V> other, {
    OnUpdate<Map<K, V>> onUpdate,
    OnEvent<CollectionEvent<K, V>> onEvent,
    OnChange<CollectionChangeEvent<K, V>> onChange,
  }) {
    assert(other != null);

    return StreamMap<K, V>(
      value: Map<K, V>.from(other),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  /// Creates a [StreamMap] wrapped around a [LinkedHashMap] with the
  /// same keys and values as [other].
  ///
  /// A `LinkedHashMap` requires the keys to implement compatible
  /// `operator==` and `hashCode`, and it allows `null` as a key.
  /// It iterates in key insertion order.
  factory StreamMap.of(
    Map<K, V> other, {
    OnUpdate<Map<K, V>> onUpdate,
    OnEvent<CollectionEvent<K, V>> onEvent,
    OnChange<CollectionChangeEvent<K, V>> onChange,
  }) {
    assert(other != null);

    return StreamMap<K, V>(
      value: Map<K, V>.of(other),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  /// Creates a [StreamMap] that wraps an identity map with the default
  /// implementation, [LinkedHashMap].
  ///
  /// An identity map uses [identical] for equality and [identityHashCode]
  /// for hash codes of keys instead of the intrinsic [Object.==] and
  /// [Object.hashCode] of the keys.
  ///
  /// The returned map allows `null` as a key.
  /// It iterates in key insertion order.
  factory StreamMap.identity({
    OnUpdate<Map<K, V>> onUpdate,
    OnEvent<CollectionEvent<K, V>> onEvent,
    OnChange<CollectionChangeEvent<K, V>> onChange,
  }) =>
      StreamMap<K, V>(
        value: Map<K, V>.identity(),
        onUpdate: onUpdate,
        onEvent: onEvent,
        onChange: onChange,
      );

  /// Creates a [StreamMap] in which the keys and values are computed from the
  /// [iterable].
  ///
  /// The created map is a [LinkedHashMap].
  /// A `LinkedHashMap` requires the keys to implement compatible
  /// `operator==` and `hashCode`, and it allows null as a key.
  /// It iterates in key insertion order.
  ///
  /// For each element of the [iterable] this constructor computes a key/value
  /// pair, by applying [key] and [value] respectively.
  ///
  /// The example below creates a new Map from a List. The keys of `map` are
  /// `list` values converted to strings, and the values of the `map` are the
  /// squares of the `list` values:
  ///
  /// ```dart
  /// List<int> list = [1, 2, 3];
  /// Map<String, int> map = Map.fromIterable(list,
  ///     key: (item) => item.toString(),
  ///     value: (item) => item/// item);
  ///
  /// map['1'] + map['2']; // 1 + 4
  /// map['3'] - map['2']; // 9 - 4
  /// ```
  ///
  /// If no values are specified for [key] and [value] the default is the
  /// identity function.
  ///
  /// In the following example, the keys and corresponding values of `map`
  /// are `list` values:
  ///
  /// ```dart
  /// map = Map.fromIterable(list);
  /// map[1] + map[2]; // 1 + 2
  /// map[3] - map[2]; // 3 - 2
  /// ```
  ///
  /// The keys computed by the source [iterable] do not need to be unique. The
  /// last occurrence of a key will simply overwrite any previous value.
  factory StreamMap.fromIterable(
    Iterable iterable, {
    _Compute<K> key,
    _Compute<V> value,
    OnUpdate<Map<K, V>> onUpdate,
    OnEvent<CollectionEvent<K, V>> onEvent,
    OnChange<CollectionChangeEvent<K, V>> onChange,
  }) {
    assert(iterable != null);

    return StreamMap<K, V>(
      value: Map.fromIterable(iterable, key: key, value: value),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  /// Creates a [StreamMap] that wraps a [Map] instance associating the
  /// given [keys] to [values].
  ///
  /// The created map is a [LinkedHashMap].
  /// A `LinkedHashMap` requires the keys to implement compatible
  /// `operator==` and `hashCode`, and it allows null as a key.
  /// It iterates in key insertion order.
  ///
  /// This constructor iterates over [keys] and [values] and maps each
  /// element of [keys] to the corresponding element of [values].
  ///
  /// ```dart
  /// List<String> letters = ['b', 'c'];
  /// List<String> words = ['bad', 'cat'];
  /// Map<String, String> map = Map.fromIterables(letters, words);
  /// map['b'] + map['c'];  // badcat
  /// ```
  ///
  /// If [keys] contains the same object multiple times, the last occurrence
  /// overwrites the previous value.
  ///
  /// The two [Iterable]s must have the same length.
  factory StreamMap.fromIterables(
    Iterable<K> keys,
    Iterable<V> values, {
    OnUpdate<Map<K, V>> onUpdate,
    OnEvent<CollectionEvent<K, V>> onEvent,
    OnChange<CollectionChangeEvent<K, V>> onChange,
  }) {
    assert(keys != null);
    assert(values != null);

    return StreamMap<K, V>(
      value: Map<K, V>.fromIterables(keys, values),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  /// Adapts [source] to be a `StreamMap<K2, V2>`.
  ///
  /// Any time the set would produce a key or value that is not a [K2] or [V2],
  /// the access will throw.
  ///
  /// Any time [K2] key or [V2] value is attempted added into the adapted map,
  /// the store will throw unless the key is also an instance of [K] and
  /// the value is also an instance of [V].
  ///
  /// If all accessed entries of [source] are have [K2] keys and [V2] values
  /// and if all entries added to the returned map have [K] keys and [V]]
  /// values, then the returned map can be used as a `Map<K2, V2>`.
  static StreamMap<K2, V2> castFrom<K, V, K2, V2>(
    Map<K, V> source, {
    OnUpdate<Map<K2, V2>> onUpdate,
    OnEvent<CollectionEvent<K2, V2>> onEvent,
    OnChange<CollectionChangeEvent<K2, V2>> onChange,
  }) {
    assert(source != null);

    return StreamMap<K2, V2>(
      value: Map.castFrom(source),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  /// Creates a new [StreamMap] where all entries of [entries]
  /// have been added in iteration order.
  ///
  /// If multiple [entries] have the same key,
  /// later occurrences overwrite the earlier ones.
  factory StreamMap.fromEntries(
    Iterable<MapEntry<K, V>> entries, {
    OnUpdate<Map<K, V>> onUpdate,
    OnEvent<CollectionEvent<K, V>> onEvent,
    OnChange<CollectionChangeEvent<K, V>> onChange,
  }) {
    assert(entries != null);

    return StreamMap<K, V>(
      value: Map.fromEntries(entries),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  @override
  Map<RK, RV> cast<RK, RV>() => value.cast<RK, RV>();

  @override
  bool containsValue(Object value) => this.value.containsValue(value);

  @override
  bool containsKey(Object key) => value.containsKey(key);

  @override
  V operator [](Object key) => value[key];

  @override
  void operator []=(K key, V value) {
    this.value[key] = value;
    notifyAllListeners(CollectionEventType.update, key, value);
  }

  @override
  Iterable<MapEntry<K, V>> get entries => value.entries;

  @override
  Map<K2, V2> map<K2, V2>(_Mapper<K, K2, V, V2> f) {
    assert(f != null);

    return value.map<K2, V2>(f);
  }

  @override
  void addEntries(
    Iterable<MapEntry<K, V>> newEntries, [
    bool notifyListeners = true,
  ]) {
    assert(newEntries != null);
    assert(notifyListeners != null);

    value.addEntries(newEntries);

    if (notifyListeners) {
      if (hasEvent || hasChangeEvent) {
        final events = <K, V>{};

        for (var entry in newEntries) {
          events.addAll(<K, V>{entry.key: entry.value});

          notifyChangeListeners(
            CollectionChangeEvent(
                CollectionEventType.addition, entry.key, entry.value),
          );
        }

        if (events.isNotEmpty) {
          notifyEventListeners(
            CollectionEvent<K, V>(CollectionEventType.addition, events),
          );
        }
      }

      this.notifyListeners(value);
    }
  }

  @override
  V update(
    K key,
    _Update<V> update, {
    _IfAbsent<V> ifAbsent,
    bool notifyListeners = true,
  }) {
    assert(update != null);
    assert(notifyListeners != null);

    final isAbsent = value.containsKey(key);

    assert(isAbsent || ifAbsent != null);

    final updated = value.update(key, update, ifAbsent: ifAbsent);

    if (notifyListeners) {
      final eventType =
          isAbsent ? CollectionEventType.addition : CollectionEventType.update;
      notifyAllListeners(eventType, key, updated);
    }

    return updated;
  }

  @override
  void updateAll(_Updater<K, V> update, {bool notifyListeners = true}) {
    assert(update != null);
    assert(notifyListeners != null);

    if (notifyListeners) {
      final events = <K, V>{};

      value.forEach((key, value) {
        final newValue = update(key, value);

        if (value != newValue) {
          this.value[key] = newValue;

          events.addAll(<K, V>{key: newValue});

          notifyChangeListeners(
            CollectionChangeEvent(CollectionEventType.update, key, newValue),
          );
        }
      });

      if (events.isNotEmpty) {
        notifyEventListeners(
          CollectionEvent<K, V>(CollectionEventType.update, events),
        );

        this.notifyListeners(value);
      }
    } else {
      value.updateAll(update);
    }
  }

  @override
  void removeWhere(_Predicate<K, V> predicate, {bool notifyListeners = true}) {
    assert(predicate != null);
    assert(notifyListeners != null);

    final map = notifyListeners ? _toMap() : null;

    if (notifyListeners) {
      final events = <K, V>{};

      map.forEach((key, value) {
        if (predicate(key, value)) {
          events.addAll(<K, V>{key: value});

          this.value.remove(key);

          notifyChangeListeners(
            CollectionChangeEvent(CollectionEventType.removal, key, value),
          );
        }
      });

      if (events.isNotEmpty) {
        notifyEventListeners(
          CollectionEvent<K, V>(CollectionEventType.removal, events),
        );
      }
    } else {
      value.removeWhere(predicate);
    }

    if (notifyListeners && value.length != map.length) {
      this.notifyListeners(value);
    }
  }

  @override
  V putIfAbsent(K key, _IfAbsent<V> ifAbsent, {bool notifyListeners = true}) {
    assert(ifAbsent != null);
    assert(notifyListeners != null);

    if (!value.containsKey(key)) {
      value.putIfAbsent(key, ifAbsent);
      if (notifyListeners) {
        notifyAllListeners(CollectionEventType.addition, key, value[key]);
      }
    }

    return value[key];
  }

  @override
  void addAll(Map<K, V> other, {bool notifyListeners = true}) {
    assert(other != null);
    assert(notifyListeners != null);

    value.addAll(other);

    if (notifyListeners) {
      if (hasEvent || hasChangeEvent) {
        final events = <K, V>{};

        other.forEach((key, value) {
          events.addAll(<K, V>{key: value});

          notifyChangeListeners(
            CollectionChangeEvent(CollectionEventType.addition, key, value),
          );
        });

        if (events.isNotEmpty) {
          notifyEventListeners(
            CollectionEvent<K, V>(CollectionEventType.addition, events),
          );
        }
      }

      this.notifyListeners(value);
    }
  }

  @override
  V remove(Object key, {bool notifyListeners = true}) {
    assert(notifyListeners != null);

    final value = this.value.remove(key);

    if (notifyListeners) {
      notifyAllListeners(CollectionEventType.removal, key, value);
    }

    return value;
  }

  @override
  void clear({bool notifyListeners = true}) {
    assert(notifyListeners != null);

    final map = notifyListeners ? _toMap() : null;

    value.clear();

    if (notifyListeners) {
      if (hasEvent || hasChangeEvent) {
        final events = <K, V>{};

        map.forEach((key, value) {
          events.addAll(<K, V>{key: value});

          notifyChangeListeners(
            CollectionChangeEvent(CollectionEventType.removal, key, value),
          );
        });

        if (events.isNotEmpty) {
          notifyEventListeners(
            CollectionEvent<K, V>(CollectionEventType.removal, events),
          );
        }
      }

      if (value.length != map.length) {
        this.notifyListeners(value);
      }
    }
  }

  @override
  void forEach(_ForEach<K, V> f) {
    assert(f != null);

    value.forEach(f);
  }

  @override
  Iterable<K> get keys => value.keys;

  @override
  Iterable<V> get values => value.values;

  @override
  int get length => value.length;

  @override
  bool get isEmpty => value.isEmpty;

  @override
  bool get isNotEmpty => value.isNotEmpty;

  /// Copies [value] into a new map, but returns `null` if [onEvent]
  /// is `null` and there are no active event listeners.
  Map<K, V> _toMap() => Map<K, V>.from(this);
}
