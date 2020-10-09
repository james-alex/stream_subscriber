# stream_subscriber

[![pub package](https://img.shields.io/pub/v/stream_subscriber.svg)](https://pub.dartlang.org/packages/stream_subscriber)

At its core stream_subscriber is a mixin that adds methods for easily managing
stream subscriptions (listeners & notifiers) to any class it's mixed into.

The library also includes several observable classes that utilize [StreamSubscriber]:
[StreamValue], [StreamList], [StreamMap], and [StreamSet]. [StreamValue] contains a
single observable value, while [StreamList], [StreamMap], and [StreamSet] implement
Dart's [List], [Map], and [Set] classes respectively.

# Usage

Classes that mixin [StreamSubscriber] contain a private broadcast (multi-stream)
[StreamController] that's created on construction. To get started, just add some
listeners, notify them of any events, and dispose of the class when it's no
longer needed.

## Implementation

The [StreamSubscriber] mixin exposes 4 methods for managing [StreamSubscription]s
of a specified subtype: [addListener], [removeListener], [notifyListeners], and
[dispose], as well as the [hasListener] and [numberOfListeners] getters.

```dart
/// A class that contains an [int] and notifies its listeners
/// of the new value each time it's modified.
class ObservableClass with StreamSubscriber<int> {
  ObservableClass(int value) : _value = value;

  int _value;

  int get value => _value;

  set value(int value) {
    _value = value;
    notifyListeners(_value);
  }
}
```

__Note:__ The [notifyListeners] method can be called anywhere and doesn't
necessarily have to provide a specific value to the listeners. It's accepted
value does however have to be of the same type as [StreamSubscriber]'s subtype,
if no subtype is provided, then any object can be provided, regardless of type.

### Subscribing Listeners

[ObservableClass]'s [value] can now be listened to for any changes.

```dart
/// Instance of a new [ObservableClass].
final observable = ObservableClass(0);

// Add a listener
observable.addListener((value) {
  print('Value was changed to $value.');
});

observable.value = 3;

// The listener will asynchronously print: Value was changed to 3.

observable.notifyListeners(5);

// The listener will asynchronously print: Value was changed to 5.

// However, because [notifyListeners] was called directly, the value
// wasn't actually updated to 5.

print(observable); // 3

// Remove the listener
observable.removeListener();

observable.value = 5;

// Because the listener was removed, nothing will be printed this time.

// [dispose] cancels and removes any active listeners and closes the notifier.
observable.dispose();

// After calling [dispose], [observable] will no longer be able to create
// or notify any listeners and its used resources will be freed up.
```

## Observable Values

The [StreamValue] class is implemented in the same way [ObservableClass] is
in the example above, but can be provided a subtype which is passed on to
[StreamSubscriber].

```dart
final observable = StreamValue<int>(0);

observable.addListener((value) {
  print(value);
});

observable.value++;

// The listener will asynchronously print: 1

observable.value = 5;

// The listener will asynchronously print: 5

observable.value--;

// The listener will asynchronously print: 4

observable.dispose();
```

[StreamValue] also has an additional optional parameter, [onUpdate], which is
called every time the [value] is changed, before the listeners are notified.

### Setting the Value Without Notifying the Listeners

To set the value without notifying the listeners, the [setValue] method
can be used.

```dart
// [value] will be set to `0`, but listener won't be notified.
observable.setValue(0);

// [value] will be set to `0` and the listener will be notified.
observable.value = 0;
```

### The [onUpdate] Notifier

[onUpdate] is a synchronously executed event, as such it can be used to further
modify the value before it is sent to the listeners. However, updating the [value]
directly from within [onUpdate] will cause [onUpdate] to be called in an infinite
loop, triggering a stack overflow, instead the [setValue] method must be used to
update the [value] without notifying the listeners or triggering [onUpdate].

__Note:__ In the case of the [StreamCollection]s described below, any of their
methods with a [notifyListeners] parameter can be set to `false`, and can be used
to update the collection without notifying their listeners.

```dart
var observable = StreamValue<int>(0);

observable.onUpdate = (value) {
  // The [setValue] method should be used to update the value without notifying the
  // listeners. Setting the value directly here would cause a stack overflow.
  observable.setValue(value + 1);
  print(observable.value);
};

observable.value++;

// The listener will synchronously print: 2

observable.value = 5;

// The listener will synchronously print: 6

observable.value -= 2;

// The listener will synchronously print: 5

observable.dispose();
```

If you don't need to reference [observable] within [onUpdate], you can also
provide [onUpdate] as an optional parameter when constructing the [StreamValue].

```dart
var observable = StreamValue<int>(0, (value) {
  print(value);
});

observable.value++;

// The listener will synchronously print: 1

observable.value = 5;

// The listener will synchronously print: 5

observable.value -= 2;

// The listener will synchronously print: 3
```

## Observable Collections

[StreamList], [StreamMap], and [StreamSet] are implementations of the [List],
[Map], and [Set] classes respectively. They extends a shared base class,
[StreamCollection] which extends the [StreamValue] class.

Each of these classes have 3 types of listeners, update listeners, event listeners,
and change listeners.

### Update Listeners

The update listener, which is inherited from [StreamValue], returns the entire
collection anytime the collection is modified or overwritten.

```dart
final list = StreamList<int>.of([0, 1, 2, 3, 4, 5]);

list.addListener((list) {
  print(list);
});

list.add(6);

// The listener will asynchronously print: [0, 1, 2, 3, 4, 5, 6]

list.removeAll();

// The listener will asynchronously print: []

list.addAll(<int>[2, 4, 6, 8]);

// The listener will asynchronously print: [2, 4, 6, 8]

list.dispose();
```

### Event Listeners

Event listeners, which are inherited from [StreamCollection]'s parent class,
[StreamEventProvider], returns an event containing the type of modification
made, and a map of the keys/indexes and the values of the element(s) modified.

```dart
final list = StreamList<int>.of([0, 1, 2, 3, 4, 5]);

list.addEventListener(event) {
  print('${event.type} ${event.elements}');
});

list.add(10);

// The listener will asynchronously print: CollectionEventType.addition {4: 10}

list.addAll(<int>[13, 16, 17]);

// The listener will asynchronously print: CollectionEventType.addition {5: 13, 6: 16, 7: 17}

list.removeWhere((value) => value.isOdd);

// The listener will asynchronously print: CollectionEventType.removal {5: 13, 7: 17}

list[0] = 5;

// The listener will asynchronously print: CollectionEventType.update {0: 5}
```

__Note:__ `event.values` could be called instead of `event.elements` to get just
the values of the affected elements without the keys/indexes.

__Note:__ In order to notify the listeners of the changes made to a collection,
the top-level methods within [StreamList], [StreamMap], and [StreamSet] must be
used. Any changes made to the underlying collection, referenced by the [value]
getter, will not notify the listeners.

```dart
// The value of the element at index 0 will be set to 5 and the listeners
// will be notified.
list[0] = 5;

// The value of the element at index 0 will be set to 2, but the listeners
// won't be notified.
list.value[0] = 2;
```

### Change Listeners

Change listeners, which are inherited from [StreamCollection], are notified
individually for every element changed within the underlying collection. They
receive an event containing the type of modification made, the [key]/index and
the [value] of the affected element.

```dart
final list = StreamList<int>[2, 4, 6, 8];

list.addChangeListener((event) {
  print('${event.type} [${event.key}, ${event.value}]');
});

list.add(10);

// The listener will asynchronously print: CollectionEventType.addition [4: 10]

list.addAll(<int>[13, 16, 17]);

// The listener will asynchronously print: CollectionEventType.addition [5: 13]
// The listener will asynchronously print: CollectionEventType.addition [6: 16]
// The listener will asynchronously print: CollectionEventType.addition [7: 17]

list.removeWhere((value) => value.isOdd);

// The listener will asynchronously print: CollectionEventType.removal [5: 13]
// The listener will asynchronously print: CollectionEventType.removal [7: 17]

list[0] = 5;

// The listener will asynchronously print: CollectionEventType.update [0: 5]
```

__Note:__ As all notifications are triggered synchronously but broadcast
asynchronously, update and event notifications will be broadcast after the
first change notification is broadcast, even if more change notifications
are queued. As such, it's better to handle individual changes from the
event notification, rather than using both an event listener and a change
listener.

### The [onEvent] and [onChange] Notifiers

The [onEvent] and [onChange] notifiers, like the [onUpdate] notifier, are
synchronously executed events triggered just before the event and change
listeners are notified.

```dart
final list = StreamList<int>.of([0, 1, 2, 3, 4, 5]);

list.onEvent = (event) {
  print('${event.type} ${event.values}');
};

list.addAll([6, 7, 8, 9]);

// [onEvent] will synchronously print: CollectionEventType.addition [6, 7, 8, 9]

list.onChange = (event) {
  print('${event.type} [${event.value}]');
};

list.removeAll([6, 7, 8, 9]);

// [onChange] will synchronously print: CollectionEventType.removal [6]
// [onChange] will synchronously print: CollectionEventType.removal [7]
// [onChange] will synchronously print: CollectionEventType.removal [8]
// [onChange] will synchronously print: CollectionEventType.removal [9]

// [onEvent] will synchronously print: CollectionEventType.removal [6, 7, 8, 9]
```

__Note:__ As described in [onUpdate]'s section above, modifying the collection
from within [onEvent] or [onChange] will cause them be called in an infinite
loop, triggering a stack overflow. To prevent this, the collections must be
updated using any of the collection's methods that have a [notifyListeners]
parameter, and setting it to `false`.
