import '../helpers/typedefs.dart';
import 'stream_collection.dart';

/// [StreamSet] wraps a [Set] and adds functionality to each relevant method
/// to notify any subscribed listeners of changes made to the set.
class StreamSet<E> extends StreamCollection<Set<E>, int, E> implements Set<E> {
  /// [StreamSet] wraps a [Set] and adds functionality to each relevant method
  /// to notify any subscribed listeners of changes made to the set.
  ///
  /// [value] can be provided to return a [StreamSet] that references
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
  StreamSet({
    Set<E>? value,
    OnUpdate<Set<E>>? onUpdate,
    OnEvent<CollectionEvent<int, E>>? onEvent,
    OnChange<CollectionChangeEvent<int, E>>? onChange,
  }) : super(
          value ?? <E>{},
          onUpdate: onUpdate,
          onEvent: onEvent,
          onChange: onChange,
        );

  /// Creates a [StreamSet] that wraps an empty identity [Set].
  ///
  /// The created [Set] is a [LinkedHashSet] that uses identity as equality
  /// relation.
  ///
  /// The set is equivalent to one created by `new LinkedHashSet<E>.identity()`.
  factory StreamSet.identity({
    OnUpdate<Set<E>>? onUpdate,
    OnEvent<CollectionEvent<int, E>>? onEvent,
    OnChange<CollectionChangeEvent<int, E>>? onChange,
  }) {
    return StreamSet<E>(
      value: Set<E>.identity(),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  /// Creates a [StreamSet] that contains all [elements].
  ///
  /// All the [elements] should be instances of [E].
  /// The `elements` iterable itself can have any type,
  /// so this constructor can be used to down-cast a `Set`, for example as:
  ///
  /// ```dart
  /// Set<SuperType> superSet = ...;
  /// Set<SubType> subSet =
  ///     Set<SubType>.from(superSet.where((e) => e is SubType));
  /// ```
  ///
  /// The created [Set] is a [LinkedHashSet]. As such, it considers elements
  /// that are equal (using [operator ==]) to be indistinguishable, and
  /// requires them to have a compatible [Object.hashCode] implementation.
  ///
  /// The set is equivalent to one created by
  /// `LinkedHashSet<E>.from(elements)`.
  factory StreamSet.from(
    Iterable elements, {
    OnUpdate<Set<E>>? onUpdate,
    OnEvent<CollectionEvent<int, E>>? onEvent,
    OnChange<CollectionChangeEvent<int, E>>? onChange,
  }) {
    return StreamSet<E>(
      value: Set.from(elements),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  /// Creates a [StreamSet] from [elements].
  ///
  /// The created [Set] is a [LinkedHashSet]. As such, it considers elements
  /// that are equal (using [operator ==]) to be indistinguishable, and
  /// requires them to have a compatible [Object.hashCode] implementation.
  ///
  /// The set is equivalent to one created by
  /// `LinkedHashSet<E>.of(elements)`.
  factory StreamSet.of(
    Iterable<E> elements, {
    OnUpdate<Set<E>>? onUpdate,
    OnEvent<CollectionEvent<int, E>>? onEvent,
    OnChange<CollectionChangeEvent<int, E>>? onChange,
  }) {
    return StreamSet<E>(
      value: Set<E>.of(elements),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  /// Adapts [source] to be a `StreamSet<T>`.
  ///
  /// If [newSet] is provided, it is used to create the new sets returned
  /// by [toSet], [union], and is also used for [intersection] and [difference].
  /// If [newSet] is omitted, it defaults to creating a new set using the
  /// default [Set] constructor, and [intersection] and [difference]
  /// returns an adapted version of calling the same method on the source.
  ///
  /// Any time the set would produce an element that is not a [T],
  /// the element access will throw.
  ///
  /// Any time a [T] value is attempted added into the adapted set,
  /// the store will throw unless the value is also an instance of [S].
  ///
  /// If all accessed elements of [source] are actually instances of [T],
  /// and if all elements added to the returned set are actually instance
  /// of [S],
  /// then the returned set can be used as a `Set<T>`.
  static StreamSet<T> castFrom<S, T>(
    Set<S> source, {
    Set<R> Function<R>()? newSet,
    OnUpdate<Set<T>>? onUpdate,
    OnEvent<CollectionEvent<int, T>>? onEvent,
    OnChange<CollectionChangeEvent<int, T>>? onChange,
  }) {
    return StreamSet<T>(
      value: Set.castFrom<S, T>(source, newSet: newSet),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  @override
  Iterator<E> get iterator => value.iterator;

  @override
  Set<R> cast<R>() => value.cast<R>();

  @override
  Iterable<E> followedBy(Iterable<E> other) => value.followedBy(other);

  @override
  Iterable<T> map<T>(T Function(E) f) => value.map(f);

  @override
  Iterable<E> where(bool Function(E) test) => value.where(test);

  @override
  Iterable<T> whereType<T>() => value.whereType<T>();

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E) f) => value.expand(f);

  @override
  bool contains(Object? value) => this.value.contains(value);

  @override
  void forEach(void Function(E) f) {
    value.forEach(f);
  }

  @override
  E reduce(E Function(E, E) combine) => value.reduce(combine);

  @override
  T fold<T>(T initialValue, T Function(T, E) combine) =>
      value.fold(initialValue, combine);

  @override
  bool every(bool Function(E element) test) => value.every(test);

  @override
  String join([String separator = '']) => value.join(separator);

  @override
  bool any(bool Function(E element) test) => value.any(test);

  @override
  bool add(E value, {bool notifyListeners = true}) {
    final valueWasAdded = this.value.add(value);
    if (notifyListeners && valueWasAdded) {
      notifyAllListeners(
          CollectionEventType.addition, this.value.length - 1, value);
    }
    return valueWasAdded;
  }

  @override
  void addAll(Iterable<E> elements, {bool notifyListeners = true}) {
    final originalLength = value.length;
    value.addAll(elements);

    if (notifyListeners) {
      if (isObserved && value.length > originalLength) {
        if (hasEvent || hasChangeEvent) {
          final events = <int, E>{};
          for (var i = originalLength; i < value.length; i++) {
            final value = elements.elementAt(i - originalLength);
            events.addAll(<int, E>{i: value});
            notifyChangeListeners(
                CollectionChangeEvent(CollectionEventType.addition, i, value));
          }

          if (events.isNotEmpty) {
            notifyEventListeners(
                CollectionEvent<int, E>(CollectionEventType.addition, events));
          }
        }

        this.notifyListeners(value);
      }
    }
  }

  @override
  bool remove(Object? value, {bool notifyListeners = true}) {
    int? index;
    if (notifyListeners && isObserved) {
      for (var i = 0; i < this.value.length; i++) {
        if (this.value.elementAt(i) == value) {
          index = i;
        }
      }
    }
    final valueWasRemoved = this.value.remove(value);
    if (notifyListeners && isObserved && valueWasRemoved) {
      notifyAllListeners(CollectionEventType.removal, index, value as E);
    }
    return valueWasRemoved;
  }

  @override
  E? lookup(Object? object) => value.lookup(object);

  @override
  void removeAll(Iterable<Object?> elements, {bool notifyListeners = true}) {
    if (notifyListeners && (hasEvent || hasChangeEvent)) {
      final events = <int, E>{};
      final values = toList(growable: false);
      for (var i = 0; i < values.length; i++) {
        for (var element in elements) {
          if (values[i] == element) {
            value.remove(element);
            final key = i;
            events.addAll(<int, E>{key: element as E});
            notifyChangeListeners(CollectionChangeEvent(
                CollectionEventType.removal, key, element));
          }
        }
      }
      if (events.isNotEmpty) {
        notifyEventListeners(
            CollectionEvent<int, E>(CollectionEventType.removal, events));
      }
    } else {
      value.removeAll(elements);
    }

    if (notifyListeners) this.notifyListeners(value);
  }

  @override
  void retainAll(Iterable<Object?> elements, {bool notifyListeners = true}) {
    if (notifyListeners) {
      final elementsToRemove = <E>{};
      for (var element in value) {
        if (!elements.contains(element)) {
          elementsToRemove.add(element);
        }
      }
      removeAll(elementsToRemove);
    } else {
      value.retainAll(elements);
    }
  }

  @override
  void removeWhere(Test<E> test, {bool notifyListeners = true}) {
    if (notifyListeners) {
      final elementsToRemove = <E>{};
      for (var element in value) {
        if (test(element)) {
          elementsToRemove.add(element);
        }
      }
      removeAll(elementsToRemove);
    } else {
      value.removeWhere(test);
    }
  }

  @override
  void retainWhere(Test<E> test, {bool notifyListeners = true}) {
    if (notifyListeners) {
      final elementsToRemove = <E>{};
      for (var element in value) {
        if (!test(element)) {
          elementsToRemove.add(element);
        }
      }
      removeAll(elementsToRemove);
    } else {
      value.retainWhere(test);
    }
  }

  @override
  bool containsAll(Iterable<Object?> other) => value.containsAll(other);

  @override
  Set<E> intersection(Set<Object?> other) => value.intersection(other);

  @override
  Set<E> union(Set<E> other) => value.union(other);

  @override
  Set<E> difference(Set<Object?> other) => value.difference(other);

  @override
  void clear({bool notifyListeners = true}) {
    final elements = notifyListeners ? List<E>.from(value) : null;
    value.clear();

    if (notifyListeners) {
      if (hasEvent || hasChangeEvent) {
        final events = <int, E>{};

        for (var i = 0; i < elements!.length; i++) {
          final value = elements[i];
          events.addAll(<int, E>{i: value});
          notifyChangeListeners(
              CollectionChangeEvent(CollectionEventType.removal, i, value));
        }

        if (events.isNotEmpty) {
          notifyEventListeners(
              CollectionEvent<int, E>(CollectionEventType.removal, events));
        }
      }

      this.notifyListeners(value);
    }
  }

  @override
  List<E> toList({bool growable = true}) => value.toList(growable: growable);

  @override
  Set<E> toSet() => value.toSet();

  @override
  int get length => value.length;

  @override
  bool get isEmpty => value.isEmpty;

  @override
  bool get isNotEmpty => value.isNotEmpty;

  @override
  Iterable<E> take(int count) {
    assert(count >= 0);
    return value.take(count);
  }

  @override
  Iterable<E> takeWhile(bool Function(E value) test) {
    return value.takeWhile(test);
  }

  @override
  Iterable<E> skip(int count) {
    assert(count >= 0);
    return value.skip(count);
  }

  @override
  Iterable<E> skipWhile(bool Function(E value) test) => value.skipWhile(test);

  @override
  E get first => value.first;

  @override
  E get last => value.last;

  @override
  E get single => value.single;

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      value.firstWhere(test, orElse: orElse);

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      value.lastWhere(test, orElse: orElse);

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      value.singleWhere(test, orElse: orElse);

  @override
  E elementAt(int index) {
    assert(index >= 0 && index < length);
    return value.elementAt(index);
  }
}
