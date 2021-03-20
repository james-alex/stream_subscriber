import 'dart:math';
import '../helpers/typedefs.dart';
import 'stream_collection.dart';

typedef _Combine<E> = E Function(E value, E element);

typedef _Compare<E> = int Function(E a, E b);

typedef _Expand<T, E> = Iterable<T> Function(E element);

typedef _Fold<T, E> = T Function(T previousValue, E element);

typedef _ForEach<E> = void Function(E element);

typedef _Generator<E> = E Function(int index);

typedef _Mapper<T, E> = T Function(E element);

typedef _OrElse<E> = E Function();

/// [StreamList] wraps a [List] and adds functionality to each relevant method
/// to notify any subscribed listeners of changes made to the list.
class StreamList<E> extends StreamCollection<List<E>, int, E>
    implements List<E> {
  /// [StreamList] wraps a [List] and adds functionality to each relevant method
  /// to notify any subscribed listeners of changes made to the list.
  ///
  /// [value] can be provided to return a [StreamList] that references
  /// [value], if `null` an empty list will be created instead. __Note:__
  /// When modifying the list by referencing [value], the listeners will
  /// not be notified of the changes made. [StreamList]'s methods must be
  /// called directly in order to notify the listeners of the changes made.
  ///
  /// If [length] is not `null`, a fixed-length list will be created.
  /// [length] will be ignored if [value] is provided.
  ///
  /// [onUpdate] is a synchronous event called each time the collection
  /// is modified and receives the entire collection as a parameter.
  ///
  /// [onEvent] is a synchronous event called each time the collection
  /// is modified, and receives a list of all of the affected elements.
  ///
  /// [onChange] is a synchronous event called individually for every
  /// element added, removed, or updated in the collection.
  StreamList({
    List<E>? value,
    OnUpdate<List<E>>? onUpdate,
    OnEvent<CollectionEvent<int, E>>? onEvent,
    OnChange<CollectionChangeEvent<int, E>>? onChange,
  }) : super(
          value ?? <E>[],
          onUpdate: onUpdate,
          onEvent: onEvent,
          onChange: onChange,
        );

  /// Creates a list of the given length with [fill] at each position.
  ///
  /// The [length] must be a non-negative integer.
  ///
  /// Example:
  ///
  /// ```dart
  /// List<int>.filled(3, 0, growable: true); // [0, 0, 0]
  /// ```
  ///
  /// The created list is fixed-length if [growable] is false (the default)
  /// and growable if [growable] is true.
  /// If the list is growable, changing its length will not initialize new
  /// entries with [fill].
  /// After being created and filled, the list is no different from any other
  /// growable or fixed-length list created using [List].
  ///
  /// All elements of the returned list share the same [fill] value.
  ///
  /// ```dart
  /// var shared = List.filled(3, []);
  /// shared[0].add(499);
  /// print(shared);  // => [[499], [499], [499]]
  /// ```
  ///
  /// You can use [List.generate] to create a list with a new object at
  /// each position.
  ///
  /// ```dart
  /// var unique = List.generate(3, (_) => []);
  /// unique[0].add(499);
  /// print(unique); // => [[499], [], []]
  /// ```
  factory StreamList.filled(
    int length,
    E fill, {
    bool growable = false,
    OnUpdate<List<E>>? onUpdate,
    OnEvent<CollectionEvent<int, E>>? onEvent,
    OnChange<CollectionChangeEvent<int, E>>? onChange,
  }) {
    return StreamList(
      value: List<E>.filled(length, fill, growable: growable),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  /// Creates a list containing all [elements].
  ///
  /// The [Iterator] of [elements] provides the order of the elements.
  ///
  /// All the [elements] should be instances of [E].
  /// The `elements` iterable itself may have any element type, so this
  /// constructor can be used to down-cast a `List`, for example as:
  ///
  /// ```dart
  /// List<SuperType> superList = ...;
  /// List<SubType> subList =
  ///     List<SubType>.from(superList.whereType<SubType>());
  /// ```
  ///
  /// This constructor creates a growable list when [growable] is true;
  /// otherwise, it returns a fixed-length list.
  factory StreamList.from(
    Iterable elements, {
    bool growable = true,
    OnUpdate<List<E>>? onUpdate,
    OnEvent<CollectionEvent<int, E>>? onEvent,
    OnChange<CollectionChangeEvent<int, E>>? onChange,
  }) {
    return StreamList(
      value: List<E>.from(elements, growable: growable),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  /// Creates a list from [elements].
  ///
  /// The [Iterator] of [elements] provides the order of the elements.
  ///
  /// This constructor creates a growable list when [growable] is true;
  /// otherwise, it returns a fixed-length list.
  factory StreamList.of(
    Iterable<E> elements, {
    bool growable = true,
    OnUpdate<List<E>>? onUpdate,
    OnEvent<CollectionEvent<int, E>>? onEvent,
    OnChange<CollectionChangeEvent<int, E>>? onChange,
  }) {
    return StreamList(
      value: List<E>.of(elements, growable: growable),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  /// Generates a list of values.
  ///
  /// Creates a list with [length] positions and fills it with values created by
  /// calling [generator] for each index in the range `0` .. `length - 1`
  /// in increasing order.
  ///
  /// ```dart
  /// List<int>.generate(3, (int index) => index/// index); // [0, 1, 4]
  /// ```
  ///
  /// The created list is fixed-length unless [growable] is true.
  factory StreamList.generate(
    int count,
    _Generator<E> generator, {
    bool growable = true,
    OnUpdate<List<E>>? onUpdate,
    OnEvent<CollectionEvent<int, E>>? onEvent,
    OnChange<CollectionChangeEvent<int, E>>? onChange,
  }) {
    return StreamList(
      value: List<E>.generate(count, generator, growable: growable),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  /// Adapts [source] to be a `StreamList<T>`.
  ///
  /// Any time the list would produce an element that is not a [T],
  /// the element access will throw.
  ///
  /// Any time a [T] value is attempted stored into the adapted list,
  /// the store will throw unless the value is also an instance of [S].
  ///
  /// If all accessed elements of [source] are actually instances of [T],
  /// and if all elements stored into the returned list are actually instance
  /// of [S], then the returned list can be used as a `StreamList<T>`.
  ///
  /// [onUpdate] is a synchronous event called each time the collection
  /// is modified and receives the entire collection as a parameter.
  ///
  /// [onEvent] is a synchronous event called each time the collection
  /// is modified, and receives a list of all of the affected elements.
  ///
  /// [onChange] is a synchronous event called individually for every
  /// element added, removed, or updated in the collection.
  static StreamList<T> castFrom<S, T>(
    List<S> source, {
    OnUpdate<List<T>>? onUpdate,
    OnEvent<CollectionEvent<int, T>>? onEvent,
    OnChange<CollectionChangeEvent<int, T>>? onChange,
  }) {
    return StreamList(
      value: List.castFrom<S, T>(source),
      onUpdate: onUpdate,
      onEvent: onEvent,
      onChange: onChange,
    );
  }

  @override
  Iterator<E> get iterator => value.iterator;

  @override
  StreamList<R> cast<R>() => StreamList.castFrom<E, R>(this);

  @override
  Iterable<E> followedBy(Iterable<E> other) => value.followedBy(other);

  @override
  Iterable<T> map<T>(_Mapper<T, E> f) => value.map<T>(f);

  @override
  Iterable<E> where(Test<E> test) => value.where(test);

  @override
  Iterable<T> whereType<T>() => value.whereType<T>();

  @override
  Iterable<T> expand<T>(_Expand<T, E> f) => value.expand<T>(f);

  @override
  bool contains(Object? element) => value.contains(element);

  @override
  void forEach(_ForEach<E> f) => value.forEach(f);

  @override
  E reduce(_Combine<E> combine) => value.reduce(combine);

  @override
  T fold<T>(T initialValue, _Fold<T, E> combine) =>
      value.fold<T>(initialValue, combine);

  @override
  bool every(Test<E> test) => value.every(test);

  @override
  String join([String separator = '']) => value.join(separator);

  @override
  bool any(Test<E> test) => value.any(test);

  @override
  List<E> toList({bool growable = true}) => value.toList(growable: growable);

  @override
  Set<E> toSet() => value.toSet();

  @override
  E operator [](int index) => value[index];

  @override
  void operator []=(int index, E value) {
    this.value[index] = value;
    notifyAllListeners(CollectionEventType.update, index, value);
  }

  @override
  set first(E value) {
    this.value.first = value;
    notifyAllListeners(CollectionEventType.update, 0, value);
  }

  @override
  set last(E value) {
    this.value.last = value;
    notifyAllListeners(
        CollectionEventType.update, this.value.length - 1, value);
  }

  @override
  int get length => value.length;

  @override
  set length(int newLength) {
    if (newLength == value.length) return;

    final originalLength = value.length;

    value.length = newLength;

    final events = <int, E>{};

    void addEvent(int index) {
      events.addAll(<int, E>{index: value[index]});

      notifyChangeListeners(CollectionChangeEvent(
          CollectionEventType.addition, index, value[index]));
    }

    if (newLength > originalLength) {
      for (var i = 0; i < newLength - originalLength; i++) {
        addEvent(originalLength + i);
      }
    } else if (newLength < originalLength) {
      for (var i = originalLength - newLength; i > 0; i++) {
        addEvent(originalLength - i);
      }
    }

    if (events.isNotEmpty) {
      notifyEventListeners(
          CollectionEvent(CollectionEventType.addition, events));
    }

    notifyListeners(value);
  }

  @override
  bool get isEmpty => value.isEmpty;

  @override
  bool get isNotEmpty => value.isNotEmpty;

  @override
  void add(E value, {bool notifyListeners = true}) {
    this.value.add(value);
    if (notifyListeners) {
      notifyAllListeners(
          CollectionEventType.addition, this.value.length - 1, value);
    }
  }

  @override
  void addAll(Iterable<E> iterable, {bool notifyListeners = true}) {
    final startIndex = value.length;
    value.addAll(iterable);
    if (notifyListeners) {
      _notifyEventListeners(CollectionEventType.addition, iterable, startIndex);
      this.notifyListeners(value);
    }
  }

  @override
  Iterable<E> take(int count) => value.take(count);

  @override
  Iterable<E> takeWhile(Test<E> test) => value.takeWhile(test);

  @override
  Iterable<E> skip(int count) => value.skip(count);

  @override
  Iterable<E> skipWhile(Test<E> test) => value.skipWhile(test);

  @override
  E get first => value.first;

  @override
  E get last => value.last;

  @override
  E get single => value.single;

  @override
  E firstWhere(Test<E> test, {_OrElse<E>? orElse}) =>
      value.firstWhere(test, orElse: orElse);

  @override
  E lastWhere(Test<E> test, {_OrElse<E>? orElse}) =>
      value.lastWhere(test, orElse: orElse);

  @override
  E singleWhere(Test<E> test, {_OrElse<E>? orElse}) =>
      value.singleWhere(test, orElse: orElse);

  @override
  E elementAt(int index) => value.elementAt(index);

  @override
  Iterable<E> get reversed => value.reversed;

  /// Reverses the order of the elements in this list.
  void reverse({bool notifyListeners = true}) {
    final elements = notifyListeners ? _toList() : null;
    value = List<E>.from(value.reversed);
    if (notifyListeners) {
      if (elements != null) {
        _notifyEventListeners(CollectionEventType.update, elements);
      }
      this.notifyListeners(value);
    }
  }

  @override
  void sort([_Compare<E>? compare]) {
    final elements = _toList();
    value.sort(compare);
    if (elements != null) {
      _notifyEventListeners(CollectionEventType.update, elements);
    }
    notifyListeners(value);
  }

  /// [sort]s the list without notifying any listeners.
  void silentSort([_Compare<E>? compare]) {
    value.sort(compare);
  }

  @override
  void shuffle([Random? random]) {
    final elements = _toList();
    value.shuffle(random);
    if (elements != null) {
      _notifyEventListeners(CollectionEventType.update, elements);
    }
    notifyListeners(value);
  }

  /// [shuffle]s the list without notifying any listeners.
  void silentShuffle([Random? random]) {
    value.shuffle(random);
  }

  @override
  int indexOf(E element, [int start = 0]) => value.indexOf(element, start);

  @override
  int indexWhere(Test<E> test, [int start = 0]) =>
      value.indexWhere(test, start);

  @override
  int lastIndexWhere(Test<E> test, [int? start]) =>
      value.lastIndexWhere(test, start);

  @override
  int lastIndexOf(E element, [int? start]) => value.lastIndexOf(element, start);

  @override
  void clear({bool notifyListeners = true}) {
    final elements = notifyListeners ? _toList() : null;
    value.clear();
    if (notifyListeners) {
      if (elements != null) {
        _notifyEventListeners(CollectionEventType.removal, elements);
      }
      this.notifyListeners(value);
    }
  }

  @override
  void insert(int index, E element, {bool notifyListeners = true}) {
    assert(index >= 0 && index <= length);
    value.insert(index, element);
    notifyAllListeners(CollectionEventType.addition, index, element);
  }

  @override
  void insertAll(
    int index,
    Iterable<E> iterable, {
    bool notifyListeners = true,
  }) {
    assert(index >= 0 && index <= length);
    value.insertAll(index, iterable);
    if (notifyListeners) {
      _notifyEventListeners(CollectionEventType.addition, iterable, index);
      this.notifyListeners(value);
    }
  }

  @override
  void setAll(int index, Iterable<E> iterable, {bool notifyListeners = true}) {
    assert(index >= 0 && index <= length);
    assert(index + iterable.length <= length);
    final elements = notifyListeners ? _toList() : null;
    value.setAll(index, iterable);
    if (notifyListeners) {
      if (elements != null) {
        _notifyEventListeners(CollectionEventType.update, elements, index);
      }
      this.notifyListeners(value);
    }
  }

  @override
  bool remove(Object? value, {bool notifyListeners = true}) {
    if (value == null && !contains(null)) {
      return false;
    } else if (value != null && value is! E) {
      return false;
    }
    final index = notifyListeners ? this.value.indexOf(value as E) : null;
    final removed = this.value.remove(value);
    if (notifyListeners && removed) {
      notifyAllListeners(CollectionEventType.removal, index, value as E);
    }
    return removed;
  }

  @override
  E removeAt(int index, {bool notifyListeners = true}) {
    assert(index >= 0 && index < length);
    final element = value.removeAt(index);
    if (notifyListeners) {
      notifyAllListeners(CollectionEventType.removal, index, element);
    }
    return element;
  }

  @override
  E removeLast({bool notifyListeners = true}) {
    final element = value.removeLast();
    if (notifyListeners) {
      notifyAllListeners(CollectionEventType.removal, value.length, element);
    }
    return element;
  }

  @override
  void removeWhere(Test<E> test, {bool notifyListeners = true}) {
    if (notifyListeners) {
      _removeOrRetainWhere(true, test);
    } else {
      value.removeWhere(test);
    }
  }

  @override
  void retainWhere(Test<E> test, {bool notifyListeners = true}) {
    if (notifyListeners) {
      _removeOrRetainWhere(false, test);
    } else {
      value.retainWhere(test);
    }
  }

  void _removeOrRetainWhere(bool remove, Test<E> test) {
    final elements = _toList()!;
    final removed = <int, E>{};

    for (var i = 0; i < elements.length; i++) {
      final element = elements[i];
      if (remove ? test(element) : !test(element)) {
        value.remove(element);
        removed.addAll(<int, E>{i: element});
        notifyChangeListeners(CollectionChangeEvent<int, E>(
            CollectionEventType.removal, i, element));
      }
    }

    if (removed.isEmpty) return;

    notifyEventListeners(
        CollectionEvent<int, E>(CollectionEventType.removal, removed));
    notifyListeners(value);
  }

  @override
  StreamList<E> operator +(List<E> other) => StreamList(value: value + other);

  @override
  List<E> sublist(int start, [int? end]) => value.sublist(start, end);

  @override
  Iterable<E> getRange(int start, int end) => value.getRange(start, end);

  @override
  void setRange(
    int start,
    int end,
    Iterable<E> iterable, [
    int skipCount = 0,
    bool notifyListeners = true,
  ]) {
    assert(start >= 0 && start <= length);
    assert(end >= start && end <= length);
    assert(iterable.length - skipCount >= end - start);
    assert(skipCount >= 0);
    final elements =
        notifyListeners ? _toList(start + skipCount, end + skipCount) : null;
    value.setRange(start, end, iterable, skipCount);
    if (notifyListeners) {
      if (elements != null) {
        _notifyEventListeners(
            CollectionEventType.update, elements, start + skipCount);
      }
      this.notifyListeners(value);
    }
  }

  @override
  void removeRange(int start, int end, {bool notifyListeners = true}) {
    assert(start >= 0 && start <= length);
    assert(end >= start && end <= length);
    final elements = notifyListeners ? _toList(start, end) : null;
    value.removeRange(start, end);
    if (notifyListeners) {
      if (elements != null) {
        _notifyEventListeners(CollectionEventType.removal, elements, start);
      }
      this.notifyListeners(value);
    }
  }

  @override
  void fillRange(
    int start,
    int end, [
    E? fillValue,
    bool notifyListeners = true,
  ]) {
    assert(start >= 0 && start <= length);
    assert(end >= start && end <= length);
    final elements = notifyListeners ? _toList(start, end) : null;
    value.fillRange(start, end, fillValue);
    if (notifyListeners) {
      if (elements != null) {
        _notifyEventListeners(CollectionEventType.update, elements, start);
      }
      this.notifyListeners(value);
    }
  }

  /// Removes the objects in the range [start] inclusive to [end] exclusive
  /// and inserts the contents of [replacement] in its place.
  ///
  /// ```dart
  /// List<int> list = [1, 2, 3, 4, 5];
  /// list.replaceRange(1, 4, [6, 7]);
  /// list.join(', '); // '1, 6, 7, 5'
  /// ```
  ///
  /// __Note:__ Because this method removes the original elements then inserts
  /// the [replacement]s, rather than a [CollectionEventType.update] being
  /// triggered, 2 events will be triggered, first a [CollectionEventType.removal]
  /// event, then a [CollectionEventType.addition] event.
  ///
  /// The provided range, given by [start] and [end], must be valid.
  /// A range from [start] to [end] is valid if `0 <= start <= end <= len`, where
  /// `len` is this list's `length`. The range starts at `start` and has length
  /// `end - start`. An empty range (with `end == start`) is valid.
  ///
  /// This method does not work on fixed-length lists, even when [replacement]
  /// has the same number of elements as the replaced range. In that case use
  /// [setRange] instead.
  @override
  void replaceRange(
    int start,
    int end,
    Iterable<E> replacement, {
    bool notifyListeners = true,
  }) {
    assert(start >= 0 && start <= length);
    assert(end >= start && end <= length);
    assert(replacement.length >= end - start);
    final elements = notifyListeners ? _toList(start, end) : null;
    value.replaceRange(start, end, replacement);
    if (notifyListeners) {
      if (elements != null) {
        _notifyEventListeners(CollectionEventType.removal, elements, start);
        _notifyEventListeners(CollectionEventType.addition, replacement, start);
      }
      this.notifyListeners(value);
    }
  }

  @override
  Map<int, E> asMap() => value.asMap();

  /// Copies [value]'s elements from [start] to [end], but returns
  /// `null` if [onEvent] and [onChange] is `null` and there are no
  /// active event or change listeners.
  List<E>? _toList([int? start, int? end]) => hasEvent || hasChangeEvent
      ? value.sublist(start ?? 0, end ?? value.length)
      : null;

  /// Notifies the event and change listeners for each of the modified elements.
  void _notifyEventListeners(
    CollectionEventType eventType,
    Iterable<E> elements, [
    int start = 0,
  ]) {
    if (!hasEvent && !hasChangeEvent) {
      return;
    }

    assert(start >= 0);

    final events = <int, E>{};

    for (var i = 0; i < elements.length; i++) {
      var key = i;
      E value;

      // If a value was added or removed, notify the listeners of the value.
      if (eventType != CollectionEventType.update) {
        key += start;
        value = elements.elementAt(i);
        events.addAll(<int, E>{key: value});
        // If the value was updated, compare it to the original value, and
        // only notify the listeners if it was changed.
      } else if (elements.elementAt(i) != this.value[start + i]) {
        value = this.value[start + i];
        events.addAll(<int, E>{key: value});
      } else {
        continue;
      }

      notifyChangeListeners(
        CollectionChangeEvent(eventType, key, value),
      );
    }

    if (events.isNotEmpty) {
      notifyEventListeners(CollectionEvent(eventType, events));
    }
  }
}
