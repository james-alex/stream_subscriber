import 'dart:async';
import 'package:test/test.dart';
import 'package:stream_subscriber/stream_subscriber.dart';

void main() {
  test('StreamValue', () async {
    final streamValue = StreamValue<int>(null);

    expect(streamValue.isObserved, equals(false));

    var updated = 0;
    var onUpdateValue = 0;

    streamValue.onUpdate = (value) {
      updated++;
      onUpdateValue = value;
    };

    expect(streamValue.isObserved, equals(true));

    streamValue.value = 0;

    expect(updated, equals(1));

    expect(streamValue.hasListener, equals(false));

    Completer<void> completer;
    Future<void> onComplete;

    var listened = 0;
    var onListenValue = 0;

    streamValue.addListener((value) {
      listened++;
      onListenValue = value;
      completer.complete();
    });

    expect(streamValue.hasListener, equals(true));

    for (var i = 1; i < 1000; i++) {
      completer = Completer<void>();
      onComplete = completer.future;

      streamValue.value = i;

      await onComplete;

      expect(updated, equals(i + 1));
      expect(onUpdateValue, equals(i));
      expect(listened, equals(i));
      expect(onListenValue, equals(i));
    }

    expect(streamValue.numberOfListeners, equals(1));

    streamValue.addListener((value) {
      listened += 2;
    });

    expect(streamValue.numberOfListeners, equals(2));

    for (var i = 0; i < 1000; i++) {
      completer = Completer<void>();
      onComplete = completer.future;

      streamValue.value = i;

      await onComplete;

      expect(updated, equals(i + 1001));
      expect(onUpdateValue, equals(i));
      expect(listened, equals((i * 3) + 1002));
      expect(onListenValue, equals(i));
    }

    streamValue.removeListener();

    expect(streamValue.numberOfListeners, equals(1));

    for (var i = 0; i < 1000; i++) {
      completer = Completer<void>();
      onComplete = completer.future;

      streamValue.value = i;

      await onComplete;

      expect(updated, equals(i + 2001));
      expect(onUpdateValue, equals(i));
      expect(listened, equals(i + 4000));
      expect(onListenValue, equals(i));
    }

    expect(streamValue.isObserved, equals(true));

    streamValue.dispose();

    expect(streamValue.isObserved, equals(false));
    expect(streamValue.hasListener, equals(false));
  });

  group('StreamList', () {
    test('Single-Event', () async {
      final streamList = StreamList<int>();

      Completer<void> completer;
      Future<void> onComplete;

      expect(streamList.isObserved, equals(false));
      expect(streamList.hasEvent, equals(false));
      expect(streamList.isEmpty, equals(true));

      // Test [onUpdate].
      var updated = 0;
      List<int> onUpdateValue;

      streamList.onUpdate = (value) {
        updated++;
        onUpdateValue = List<int>.from(value);
      };

      expect(streamList.isObserved, equals(true));

      streamList.add(0);

      expect(updated, equals(1));
      expect(streamList.isNotEmpty, equals(true));
      expect(streamList, equals(onUpdateValue));

      // Test update listeners.
      expect(streamList.hasListener, equals(false));

      var listened = 0;
      var lastListenedValue = 0;

      streamList.addListener((value) {
        listened++;
        lastListenedValue = value.isNotEmpty ? value.last : null;
        completer.complete();
      });

      expect(streamList.hasListener, equals(true));

      for (var i = 1; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList.add(i);

        expect(updated, equals(i + 1));

        await onComplete;

        expect(listened, equals(i));
        expect(lastListenedValue, equals(i));

        expect(streamList, equals(onUpdateValue));
      }

      expect(streamList.numberOfListeners, equals(1));

      streamList.addListener((value) {
        listened += 2;
        if (streamList.numberOfListeners == 1) {
          lastListenedValue = value.last;
          completer.complete();
        }
      });

      expect(streamList.numberOfListeners, equals(2));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList.remove(i);

        expect(updated, equals(2000 - i));

        await onComplete;

        expect(listened, equals((((1000 - i) * 3) - 1) + 1000));
        expect(lastListenedValue, equals(i - 1));

        expect(streamList, equals(onUpdateValue));
      }

      // Test [onEvent].
      expect(streamList.hasEvent, equals(false));

      var events = 0;
      int eventValue;

      streamList.onEvent = (event) {
        events++;
        eventValue = event.values.first;
      };

      expect(streamList.hasEvent, equals(true));

      completer = Completer<void>();
      onComplete = completer.future;

      streamList.removeAt(0);

      expect(updated, equals(2000));
      expect(events, equals(1));
      expect(eventValue, equals(0));

      expect(streamList.isEmpty, equals(true));

      await onComplete;

      expect(lastListenedValue, equals(null));

      streamList.removeListener();

      expect(streamList.numberOfListeners, equals(1));

      // Test event listeners.
      expect(streamList.hasEventListener, equals(false));

      var listenedEvents = 0;

      int lastValueAdded;
      int lastValueRemoved;
      int lastValueUpdated;

      streamList.addEventListener((event) {
        listenedEvents++;

        final value = event.values.first;

        switch (event.type) {
          case CollectionEventType.addition:
            lastValueAdded = value;
            break;
          case CollectionEventType.removal:
            lastValueRemoved = value;
            break;
          case CollectionEventType.update:
            lastValueUpdated = value;
            break;
        }
      });

      expect(streamList.hasEventListener, equals(true));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList.add(i);

        expect(updated, equals((i + 1) + 2000));
        expect(events, equals(i + 2));

        await onComplete;

        expect(listened, equals(i + 4000));
        expect(lastListenedValue, equals(i));

        expect(listenedEvents, equals(i + 1));
        expect(lastValueAdded, equals(i));
        expect(lastValueRemoved, equals(null));
        expect(lastValueUpdated, equals(null));

        expect(streamList, equals(onUpdateValue));
      }

      expect(streamList.numberOfEventListeners, equals(1));

      streamList.addEventListener((event) {
        listenedEvents += 2;
      });

      expect(streamList.numberOfEventListeners, equals(2));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList[i] = 999 - i;

        expect(updated, equals((i + 1) + 3000));
        expect(events, equals((i + 2) + 1000));

        await onComplete;

        expect(listened, equals(i + 5000));
        expect(lastListenedValue, equals(streamList.last));

        expect(listenedEvents, equals(((i + 1) * 3) + 1000));
        expect(lastValueAdded, equals(999));
        expect(lastValueRemoved, equals(null));
        expect(lastValueUpdated, equals(999 - i));

        expect(streamList, equals(onUpdateValue));
      }

      streamList.removeEventListener();

      expect(streamList.numberOfEventListeners, equals(1));

      completer = Completer<void>();
      onComplete = completer.future;

      streamList.reverse();

      expect(streamList, equals(List<int>.generate(1000, (index) => index)));

      await onComplete;

      expect(updated, equals(4002));
      expect(streamList, equals(onUpdateValue));
      expect(listened, equals(6000));
      expect(lastListenedValue, equals(999));

      expect(events, equals(2002));
      expect(listenedEvents, equals(4001));
      expect(lastValueAdded, equals(999));
      expect(lastValueRemoved, equals(null));
      expect(lastValueUpdated, equals(0));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        if (i % 2 == 0) {
          streamList.remove(i);
        } else {
          streamList.removeAt(i);
        }

        expect(updated, equals((1000 - i) + 4002));
        expect(events, equals((1000 - i) + 2002));

        await onComplete;

        expect(listened, equals((1000 - i) + 6000));
        expect(lastListenedValue, equals(streamList.last));

        expect(listenedEvents, equals((1000 - i) + 4001));
        expect(lastValueAdded, equals(999));
        expect(lastValueRemoved, equals(i));
        expect(lastValueUpdated, equals(0));

        expect(streamList, equals(onUpdateValue));
      }

      // Test [onChange].
      expect(streamList.hasChangeEvent, equals(false));

      var changes = 0;
      int lastValueChanged;

      streamList.onChange = (change) {
        changes++;
        lastValueChanged = change.value;
      };

      expect(streamList.hasChangeEvent, equals(true));

      completer = Completer<void>();
      onComplete = completer.future;

      streamList.remove(0);

      expect(updated, equals(5002));
      expect(events, equals(3002));
      expect(changes, equals(1));
      expect(lastValueChanged, equals(0));
      expect(lastListenedValue, equals(0));

      await onComplete;

      expect(listenedEvents, equals(5001));
      expect(lastListenedValue, equals(null));

      // Test change listeners.
      expect(streamList.hasChangeListener, equals(false));

      var listenedChanges = 0;

      int lastChangeValueAdded;
      int lastChangeValueRemoved;
      int lastChangeValueUpdated;

      streamList.addChangeListener((change) {
        listenedChanges++;

        switch (change.type) {
          case CollectionEventType.addition:
            lastChangeValueAdded = change.value;
            break;
          case CollectionEventType.removal:
            lastChangeValueRemoved = change.value;
            break;
          case CollectionEventType.update:
            lastChangeValueUpdated = change.value;
            break;
        }
      });

      expect(streamList.hasChangeListener, equals(true));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList.add(i);

        expect(updated, equals((i + 1) + 5002));
        expect(events, equals((i + 1) + 3002));
        expect(changes, equals(i + 2));
        expect(lastValueChanged, equals(i));

        await onComplete;

        expect(listened, equals(i + 7001));
        expect(lastListenedValue, equals(streamList.last));

        expect(listenedEvents, equals((i + 1) + 5001));
        expect(lastValueAdded, equals(i));
        expect(lastValueRemoved, equals(0));
        expect(lastValueUpdated, equals(0));

        expect(listenedChanges, equals(i + 1));
        expect(lastChangeValueAdded, equals(i));
        expect(lastChangeValueRemoved, equals(null));
        expect(lastChangeValueUpdated, equals(null));

        expect(streamList, equals(onUpdateValue));
      }

      expect(streamList.numberOfChangeListeners, equals(1));

      streamList.addChangeListener((event) {
        listenedChanges += 2;
      });

      expect(streamList.numberOfChangeListeners, equals(2));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList[i] = 999 - i;

        expect(updated, equals((i + 1) + 6002));
        expect(events, equals((i + 1) + 4002));
        expect(changes, equals((i + 2) + 1000));
        expect(lastValueChanged, equals(streamList[i]));

        await onComplete;

        expect(listened, equals(i + 8001));
        expect(lastListenedValue, equals(streamList.last));

        expect(listenedEvents, equals((i + 1) + 6001));
        expect(lastValueAdded, equals(999));
        expect(lastValueRemoved, equals(0));
        expect(lastValueUpdated, equals(streamList[i]));

        expect(listenedChanges, equals(((i + 1) * 3) + 1000));
        expect(lastChangeValueAdded, equals(999));
        expect(lastChangeValueRemoved, equals(null));
        expect(lastChangeValueUpdated, equals(streamList[i]));

        expect(streamList, equals(onUpdateValue));
      }

      streamList.removeChangeListener();

      expect(streamList.numberOfChangeListeners, equals(1));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        if (i % 2 == 0) {
          streamList.removeAt(0);
        } else {
          streamList.removeLast();
        }

        expect(updated, equals((1000 - i) + 7002));
        expect(events, equals((1000 - i) + 5002));
        expect(changes, equals((999 - i + 2) + 2000));

        await onComplete;

        expect(listened, equals((1000 - i) + 9000));

        expect(listenedEvents, equals((1000 - i) + 7001));
        expect(lastValueAdded, equals(999));
        expect(lastValueUpdated, equals(0));

        expect(listenedChanges, equals((1000 - i) + 4000));
        expect(lastChangeValueAdded, equals(999));
        expect(lastChangeValueUpdated, equals(0));

        if (streamList.isNotEmpty) {
          expect(lastListenedValue, equals(streamList.last));
          final removed =
              i % 2 == 0 ? streamList.first + 1 : streamList.last - 1;
          expect(lastValueRemoved, equals(removed));
          expect(lastChangeValueRemoved, equals(removed));
        }

        expect(streamList, equals(onUpdateValue));
      }

      expect(streamList.isObserved, equals(true));

      streamList.dispose();

      expect(streamList.hasUpdate, equals(false));
      expect(streamList.hasEvent, equals(false));
      expect(streamList.hasChangeEvent, equals(false));
      expect(streamList.isObserved, equals(false));
      expect(streamList.wasDisposed, equals(true));
    });

    test('Multi-Event', () async {
      final streamList = StreamList<int>();

      Completer<void> completer;
      Future<void> onComplete;

      expect(streamList.isObserved, equals(false));
      expect(streamList.hasEvent, equals(false));
      expect(streamList.isEmpty, equals(true));

      final testValues = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
      Iterable<int> mappedValues(int i) =>
          testValues.map<int>((value) => (i * 10) + value);

      // Test [onUpdate].
      var updated = 0;
      List<int> onUpdateValue;

      streamList.onUpdate = (value) {
        updated++;
        onUpdateValue = List<int>.from(value);
      };

      expect(streamList.isObserved, equals(true));

      streamList.addAll(testValues);

      expect(updated, equals(1));
      expect(streamList.isNotEmpty, equals(true));
      expect(streamList, equals(onUpdateValue));

      // Test update listeners.
      expect(streamList.hasListener, equals(false));

      var listened = 0;
      List<int> lastValuesListened;

      streamList.addListener((value) {
        listened++;
        lastValuesListened =
            value.isEmpty ? null : value.sublist(value.length - 10);
        if (!streamList.hasChangeListener) {
          completer.complete();
        }
      });

      expect(streamList.hasListener, equals(true));

      for (var i = 1; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList.addAll(mappedValues(i));

        expect(updated, equals(i + 1));

        await onComplete;

        expect(listened, equals(i));
        expect(lastValuesListened, equals(mappedValues(i)));

        expect(streamList, equals(onUpdateValue));
      }

      expect(streamList.numberOfListeners, equals(1));

      streamList.addListener((value) {
        listened += 2;
        if (streamList.numberOfListeners == 1) {
          lastValuesListened = List<int>.from(value);
          completer.complete();
        }
      });

      expect(streamList.numberOfListeners, equals(2));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList.removeRange(i * 10, (i + 1) * 10);

        expect(updated, equals(2000 - i));

        await onComplete;

        expect(listened, equals((((1000 - i) * 3) - 1) + 1000));
        expect(lastValuesListened, equals(mappedValues(i - 1)));

        expect(streamList, equals(onUpdateValue));
      }

      // Test [onEvent].
      expect(streamList.hasEvent, equals(false));

      var events = 0;
      List<int> eventValues;
      var numberOfEventValues = 0;

      streamList.onEvent = (event) {
        events++;
        eventValues = event.values;
        numberOfEventValues += eventValues.length;
      };

      expect(streamList.hasEvent, equals(true));

      completer = Completer<void>();
      onComplete = completer.future;

      streamList.removeWhere((value) => testValues.contains(value));

      expect(updated, equals(2000));
      expect(events, equals(1));
      expect(numberOfEventValues, equals(10));
      expect(eventValues, equals(testValues));

      expect(streamList.isEmpty, equals(true));

      await onComplete;

      expect(lastValuesListened, equals(null));

      streamList.removeListener();

      expect(streamList.numberOfListeners, equals(1));

      // Test event listeners.
      expect(streamList.hasEventListener, equals(false));

      var listenedEvents = 0;

      List<int> lastValuesAdded;
      List<int> lastValuesRemoved;
      List<int> lastValuesUpdated;

      streamList.addEventListener((event) {
        listenedEvents++;

        switch (event.type) {
          case CollectionEventType.addition:
            lastValuesAdded = event.values;
            break;
          case CollectionEventType.removal:
            lastValuesRemoved = event.values;
            break;
          case CollectionEventType.update:
            lastValuesUpdated = event.values;
            break;
        }
      });

      expect(streamList.hasEventListener, equals(true));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList.addAll(mappedValues(i));

        expect(updated, equals((i + 1) + 2000));
        expect(events, equals(i + 2));

        await onComplete;

        expect(listened, equals(i + 4000));
        expect(lastValuesListened, equals(mappedValues(i)));

        expect(listenedEvents, equals(i + 1));
        expect(lastValuesAdded, equals(mappedValues(i)));
        expect(lastValuesRemoved, equals(null));
        expect(lastValuesUpdated, equals(null));

        expect(streamList, equals(onUpdateValue));
      }

      expect(streamList.numberOfEventListeners, equals(1));

      streamList.addEventListener((event) {
        listenedEvents += 2;
      });

      expect(streamList.numberOfEventListeners, equals(2));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList.setRange(
            i * 10, (i + 1) * 10, mappedValues(999 - i).toList().reversed);

        expect(updated, equals((i + 1) + 3000));
        expect(events, equals((i + 2) + 1000));

        await onComplete;

        expect(listened, equals(i + 5000));
        if (i == 999) {
          expect(lastValuesListened, equals(testValues.reversed));
        } else {
          expect(lastValuesListened, equals(mappedValues(999)));
        }

        expect(listenedEvents, equals(((i + 1) * 3) + 1000));
        expect(lastValuesAdded, equals(mappedValues(999)));
        expect(lastValuesRemoved, equals(null));
        expect(
            lastValuesUpdated, equals(mappedValues(999 - i).toList().reversed));

        expect(streamList, equals(onUpdateValue));
      }

      streamList.removeEventListener();

      expect(streamList.numberOfEventListeners, equals(1));

      completer = Completer<void>();
      onComplete = completer.future;

      streamList.reverse();

      final fullList = List<int>.generate(10000, (index) => index);

      expect(streamList, equals(fullList));

      await onComplete;

      expect(updated, equals(4002));
      expect(streamList, equals(onUpdateValue));
      expect(listened, equals(6000));
      expect(lastValuesListened, equals(mappedValues(999)));

      expect(events, equals(2002));
      expect(listenedEvents, equals(4001));
      expect(lastValuesAdded, equals(mappedValues(999)));
      expect(lastValuesRemoved, equals(null));
      expect(lastValuesUpdated, equals(fullList));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList.removeRange(i * 10, (i + 1) * 10);

        expect(updated, equals((1000 - i) + 4002));
        expect(events, equals((1000 - i) + 2002));

        await onComplete;

        expect(listened, equals((1000 - i) + 6000));
        expect(lastValuesListened, equals(mappedValues(i - 1)));

        expect(listenedEvents, equals((1000 - i) + 4001));
        expect(lastValuesAdded, equals(mappedValues(999)));
        expect(lastValuesRemoved, equals(mappedValues(i)));
        expect(lastValuesUpdated, equals(fullList));

        expect(streamList, equals(onUpdateValue));
      }

      // Test [onChange].
      expect(streamList.hasChangeEvent, equals(false));

      var changes = 0;
      int lastValueChanged;

      streamList.onChange = (change) {
        changes++;
        lastValueChanged = change.value;
      };

      expect(streamList.hasChangeEvent, equals(true));

      completer = Completer<void>();
      onComplete = completer.future;

      streamList.clear();

      expect(updated, equals(5002));
      expect(events, equals(3002));
      expect(changes, equals(10));
      expect(lastValueChanged, equals(9));
      expect(lastValuesListened, equals(testValues));

      await onComplete;

      expect(listenedEvents, equals(5001));
      expect(lastValuesListened, equals(null));

      // Test change listeners.
      expect(streamList.hasChangeListener, equals(false));

      var listenedChanges = 0;

      int lastChangeValueAdded;
      int lastChangeValueRemoved;
      int lastChangeValueUpdated;

      streamList.addChangeListener((change) {
        listenedChanges++;

        switch (change.type) {
          case CollectionEventType.addition:
            lastChangeValueAdded = change.value;
            break;
          case CollectionEventType.removal:
            lastChangeValueRemoved = change.value;
            break;
          case CollectionEventType.update:
            lastChangeValueUpdated = change.value;
            break;
        }

        if (change.value % 10 == 9) {
          completer.complete();
        }
      });

      expect(streamList.hasChangeListener, equals(true));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList.addAll(mappedValues(i));

        expect(updated, equals((i + 1) + 5002));
        expect(events, equals((i + 1) + 3002));
        expect(changes, equals(((i + 2) * 10)));
        expect(lastValueChanged, equals((i * 10) + 9));

        await onComplete;

        expect(listened, equals(i + 7002));
        expect(lastValuesListened, equals(mappedValues(i)));

        expect(listenedEvents, equals(i + 5002));
        expect(lastValuesAdded, equals(mappedValues(i)));
        expect(lastValuesRemoved, equals(testValues));
        expect(lastValuesUpdated, equals(fullList));

        expect(listenedChanges, equals((i + 1) * 10));
        expect(lastChangeValueAdded, equals(((i + 1) * 10) - 1));
        expect(lastChangeValueRemoved, equals(null));
        expect(lastChangeValueUpdated, equals(null));

        expect(streamList, equals(onUpdateValue));
      }

      expect(streamList.numberOfChangeListeners, equals(1));

      streamList.addChangeListener((event) {
        listenedChanges += 2;
      });

      expect(streamList.numberOfChangeListeners, equals(2));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList.setRange(
            i * 10, (i + 1) * 10, mappedValues(999 - i).toList().reversed);

        expect(updated, equals((i + 1) + 6002));
        expect(events, equals((i + 1) + 4002));
        expect(changes, equals(((i + 2) * 10) + 10000));
        expect(lastValueChanged, equals((999 - i) * 10));

        await onComplete;

        expect(listened, equals(i + 8002));
        if (i == 999) {
          expect(lastValuesListened, equals(testValues.reversed));
        } else {
          expect(lastValuesListened, equals(mappedValues(999)));
        }

        expect(listenedEvents, equals(i + 6002));
        expect(lastValuesAdded, equals(mappedValues(999)));
        expect(lastValuesRemoved, equals(testValues));
        expect(
            lastValuesUpdated, equals(mappedValues(999 - i).toList().reversed));

        expect(listenedChanges, equals((i * 30) + 10003));
        expect(lastChangeValueAdded, equals(9999));
        expect(lastChangeValueRemoved, equals(null));
        expect(lastChangeValueUpdated, equals(((999 - i) * 10) + 9));

        expect(streamList, equals(onUpdateValue));
      }

      streamList.removeChangeListener();

      expect(streamList.numberOfChangeListeners, equals(1));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamList.removeRange(i * 10, (i + 1) * 10);

        expect(updated, equals((1000 - i) + 7002));
        expect(events, equals((1000 - i) + 5002));
        expect(changes, equals(((999 - i + 2) * 10) + 20000));

        await onComplete;

        expect(listened, equals((1000 - i + 1) + 9000));

        expect(listenedEvents, equals((1000 - i + 1) + 7000));
        expect(lastValuesAdded, equals(mappedValues(999)));
        expect(lastValuesUpdated, equals(testValues.reversed));

        expect(listenedChanges, equals(((999 - i) * 10) + 39983));
        expect(lastChangeValueAdded, equals(9999));
        expect(lastChangeValueUpdated, equals(0));

        if (streamList.isNotEmpty) {
          expect(lastValuesListened,
              equals(mappedValues(1000 - i).toList().reversed));
          expect(lastValuesRemoved,
              equals(mappedValues(999 - i).toList().reversed));
          expect(lastChangeValueRemoved, equals(((999 - i) * 10) + 9));
        }

        expect(streamList, equals(onUpdateValue));
      }

      expect(streamList.isObserved, equals(true));

      streamList.dispose();

      expect(streamList.hasUpdate, equals(false));
      expect(streamList.hasEvent, equals(false));
      expect(streamList.hasChangeEvent, equals(false));
      expect(streamList.isObserved, equals(false));
      expect(streamList.wasDisposed, equals(true));
    });
  });

  group('StreamSet', () {
    test('Single-Event', () async {
      final streamSet = StreamSet<int>();

      Completer<void> completer;
      Future<void> onComplete;

      expect(streamSet.isObserved, equals(false));
      expect(streamSet.hasEvent, equals(false));
      expect(streamSet.isEmpty, equals(true));

      // Test [onUpdate].
      var updated = 0;
      List<int> onUpdateValue;

      streamSet.onUpdate = (value) {
        updated++;
        onUpdateValue = List<int>.from(value);
      };

      expect(streamSet.isObserved, equals(true));

      streamSet.add(0);

      expect(updated, equals(1));
      expect(streamSet.isNotEmpty, equals(true));
      expect(streamSet, equals(onUpdateValue));

      // Test update listeners.
      expect(streamSet.hasListener, equals(false));

      var listened = 0;
      var lastListenedValue = 0;

      streamSet.addListener((value) {
        listened++;
        lastListenedValue = value.isNotEmpty ? value.last : null;
        completer.complete();
      });

      expect(streamSet.hasListener, equals(true));

      for (var i = 1; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamSet.add(i);

        expect(updated, equals(i + 1));

        await onComplete;

        expect(listened, equals(i));
        expect(lastListenedValue, equals(i));

        expect(streamSet, equals(onUpdateValue));
      }

      expect(streamSet.numberOfListeners, equals(1));

      streamSet.addListener((value) {
        listened += 2;
        if (streamSet.numberOfListeners == 1) {
          lastListenedValue = value.last;
          completer.complete();
        }
      });

      expect(streamSet.numberOfListeners, equals(2));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamSet.remove(i);

        expect(updated, equals(2000 - i));

        await onComplete;

        expect(listened, equals((((1000 - i) * 3) - 1) + 1000));
        expect(lastListenedValue, equals(i - 1));

        expect(streamSet, equals(onUpdateValue));
      }

      // Test [onEvent].
      expect(streamSet.hasEvent, equals(false));

      var events = 0;
      int eventValue;

      streamSet.onEvent = (event) {
        events++;
        eventValue = event.values.first;
      };

      expect(streamSet.hasEvent, equals(true));

      completer = Completer<void>();
      onComplete = completer.future;

      streamSet.remove(0);

      expect(updated, equals(2000));
      expect(events, equals(1));
      expect(eventValue, equals(0));

      expect(streamSet.isEmpty, equals(true));

      await onComplete;

      expect(lastListenedValue, equals(null));

      streamSet.removeListener();

      expect(streamSet.numberOfListeners, equals(1));

      // Test event listeners.
      expect(streamSet.hasEventListener, equals(false));

      var listenedEvents = 0;

      int lastValueAdded;
      int lastValueRemoved;

      streamSet.addEventListener((event) {
        listenedEvents++;

        final value = event.values.first;

        switch (event.type) {
          case CollectionEventType.addition:
            lastValueAdded = value;
            break;
          case CollectionEventType.removal:
            lastValueRemoved = value;
            break;
          default:
            break;
        }
      });

      expect(streamSet.hasEventListener, equals(true));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamSet.add(i);

        expect(updated, equals((i + 1) + 2000));
        expect(events, equals(i + 2));

        await onComplete;

        expect(listened, equals(i + 4000));
        expect(lastListenedValue, equals(i));

        expect(listenedEvents, equals(i + 1));
        expect(lastValueAdded, equals(i));
        expect(lastValueRemoved, equals(null));

        expect(streamSet, equals(onUpdateValue));
      }

      expect(streamSet.numberOfEventListeners, equals(1));

      streamSet.addEventListener((event) {
        listenedEvents += 2;
      });

      expect(streamSet.numberOfEventListeners, equals(2));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamSet.remove(i);

        expect(updated, equals((1000 - i) + 3000));
        expect(events, equals((1000 - i + 1) + 1000));

        await onComplete;

        expect(listened, equals((999 - i) + 5000));
        expect(lastListenedValue, equals(streamSet.last));

        expect(listenedEvents, equals(((1000 - i) * 3) + 1000));
        expect(lastValueAdded, equals(999));
        expect(lastValueRemoved, equals(i));

        expect(streamSet, equals(onUpdateValue));
      }

      // Test [onChange].
      expect(streamSet.hasChangeEvent, equals(false));

      var changes = 0;
      int lastValueChanged;

      streamSet.onChange = (change) {
        changes++;
        lastValueChanged = change.value;
      };

      expect(streamSet.hasChangeEvent, equals(true));

      completer = Completer<void>();
      onComplete = completer.future;

      streamSet.remove(0);

      expect(updated, equals(4000));
      expect(events, equals(2001));
      expect(changes, equals(1));
      expect(lastValueChanged, equals(0));
      expect(lastListenedValue, equals(0));

      await onComplete;

      expect(listenedEvents, equals(4000));
      expect(lastListenedValue, equals(null));

      streamSet.removeEventListener();

      expect(streamSet.numberOfEventListeners, equals(1));

      // Test change listeners.
      expect(streamSet.hasChangeListener, equals(false));

      var listenedChanges = 0;

      int lastChangeValueAdded;
      int lastChangeValueRemoved;

      streamSet.addChangeListener((change) {
        listenedChanges++;

        switch (change.type) {
          case CollectionEventType.addition:
            lastChangeValueAdded = change.value;
            break;
          case CollectionEventType.removal:
            lastChangeValueRemoved = change.value;
            break;
          default:
            break;
        }
      });

      expect(streamSet.hasChangeListener, equals(true));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamSet.add(i);

        expect(updated, equals((i + 1) + 4000));
        expect(events, equals((i + 1) + 2001));
        expect(changes, equals(i + 2));
        expect(lastValueChanged, equals(i));

        await onComplete;

        expect(listened, equals(i + 6000));
        expect(lastListenedValue, equals(streamSet.last));

        expect(listenedEvents, equals(i + 4001));
        expect(lastValueAdded, equals(i));
        expect(lastValueRemoved, equals(0));

        expect(listenedChanges, equals(i + 1));
        expect(lastChangeValueAdded, equals(i));
        expect(lastChangeValueRemoved, equals(null));

        expect(streamSet, equals(onUpdateValue));
      }

      expect(streamSet.numberOfChangeListeners, equals(1));

      streamSet.addChangeListener((event) {
        listenedChanges += 2;
      });

      expect(streamSet.numberOfChangeListeners, equals(2));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamSet.remove(i);

        expect(updated, equals((1000 - i) + 5000));
        expect(events, equals((1000 - i) + 3001));
        expect(changes, equals((1000 - i + 1) + 1000));

        await onComplete;

        expect(listened, equals((999 - i) + 7000));

        expect(listenedEvents, equals((1000 - i) + 5000));
        expect(lastValueAdded, equals(999));

        expect(listenedChanges, equals(((1000 - i) * 3) + 1000));
        expect(lastChangeValueAdded, equals(999));

        if (streamSet.isNotEmpty) {
          expect(lastListenedValue, equals(streamSet.last));
          expect(lastValueRemoved, equals(streamSet.last + 1));
          expect(lastChangeValueRemoved, equals(streamSet.last + 1));
        }

        expect(streamSet, equals(onUpdateValue));
      }

      expect(streamSet.isObserved, equals(true));

      streamSet.dispose();

      expect(streamSet.hasUpdate, equals(false));
      expect(streamSet.hasEvent, equals(false));
      expect(streamSet.hasChangeEvent, equals(false));
      expect(streamSet.isObserved, equals(false));
      expect(streamSet.wasDisposed, equals(true));
    });

    test('Multi-Event', () async {
      final streamSet = StreamSet<int>();

      Completer<void> completer;
      Future<void> onComplete;

      expect(streamSet.isObserved, equals(false));
      expect(streamSet.hasEvent, equals(false));
      expect(streamSet.isEmpty, equals(true));

      final testValues = <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
      Iterable<int> mappedValues(int i) =>
          testValues.map<int>((value) => (i * 10) + value);

      // Test [onUpdate].
      var updated = 0;
      List<int> onUpdateValue;

      streamSet.onUpdate = (value) {
        updated++;
        onUpdateValue = List<int>.from(value);
      };

      expect(streamSet.isObserved, equals(true));

      streamSet.addAll(testValues);

      expect(updated, equals(1));
      expect(streamSet.isNotEmpty, equals(true));
      expect(streamSet, equals(onUpdateValue));

      // Test update listeners.
      expect(streamSet.hasListener, equals(false));

      var listened = 0;
      List<int> lastValuesListened;

      streamSet.addListener((value) {
        listened++;
        lastValuesListened =
            value.isEmpty ? null : value.toList().sublist(value.length - 10);
        if (!streamSet.hasChangeListener) {
          completer.complete();
        }
      });

      expect(streamSet.hasListener, equals(true));

      for (var i = 1; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamSet.addAll(mappedValues(i));

        expect(updated, equals(i + 1));

        await onComplete;

        expect(listened, equals(i));
        expect(lastValuesListened, equals(mappedValues(i)));

        expect(streamSet, equals(onUpdateValue));
      }

      expect(streamSet.numberOfListeners, equals(1));

      streamSet.addListener((value) {
        listened += 2;
        if (streamSet.numberOfListeners == 1) {
          lastValuesListened = List<int>.from(value);
          completer.complete();
        }
      });

      expect(streamSet.numberOfListeners, equals(2));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamSet.removeAll(List<int>.generate(10, (index) => i * 10 + index));

        expect(updated, equals(2000 - i));

        await onComplete;

        expect(listened, equals((((1000 - i) * 3) - 1) + 1000));
        expect(lastValuesListened, equals(mappedValues(i - 1)));

        expect(streamSet, equals(onUpdateValue));
      }

      // Test [onEvent].
      expect(streamSet.hasEvent, equals(false));

      var events = 0;
      List<int> eventValues;
      var numberOfEventValues = 0;

      streamSet.onEvent = (event) {
        events++;
        eventValues = event.values;
        numberOfEventValues += eventValues.length;
      };

      expect(streamSet.hasEvent, equals(true));

      completer = Completer<void>();
      onComplete = completer.future;

      streamSet.removeAll(testValues);

      expect(updated, equals(2000));
      expect(events, equals(1));
      expect(numberOfEventValues, equals(10));
      expect(eventValues, equals(testValues));

      expect(streamSet.isEmpty, equals(true));

      await onComplete;

      expect(lastValuesListened, equals(null));

      streamSet.removeListener();

      expect(streamSet.numberOfListeners, equals(1));

      // Test event listeners.
      expect(streamSet.hasEventListener, equals(false));

      var listenedEvents = 0;

      List<int> lastValuesAdded;
      List<int> lastValuesRemoved;

      streamSet.addEventListener((event) {
        listenedEvents++;

        switch (event.type) {
          case CollectionEventType.addition:
            lastValuesAdded = event.values;
            break;
          case CollectionEventType.removal:
            lastValuesRemoved = event.values;
            break;
          default:
            break;
        }
      });

      expect(streamSet.hasEventListener, equals(true));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamSet.addAll(mappedValues(i));

        expect(updated, equals((i + 1) + 2000));
        expect(events, equals(i + 2));

        await onComplete;

        expect(listened, equals(i + 4000));
        expect(lastValuesListened, equals(mappedValues(i)));

        expect(listenedEvents, equals(i + 1));
        expect(lastValuesAdded, equals(mappedValues(i)));
        expect(lastValuesRemoved, equals(null));

        expect(streamSet, equals(onUpdateValue));
      }

      expect(streamSet.numberOfEventListeners, equals(1));

      streamSet.addEventListener((event) {
        listenedEvents += 2;
      });

      expect(streamSet.numberOfEventListeners, equals(2));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamSet.removeAll(List<int>.generate(10, (index) => i * 10 + index));

        expect(updated, equals((1000 - i) + 3000));
        expect(events, equals((1000 - i + 1) + 1000));

        await onComplete;

        expect(listened, equals((999 - i) + 5000));
        if (streamSet.isNotEmpty) {
          expect(lastValuesListened, equals(mappedValues(i - 1)));
        } else {
          expect(lastValuesListened, equals(null));
        }

        expect(listenedEvents, equals(((1000 - i) * 3) + 1000));
        expect(lastValuesAdded, equals(mappedValues(999)));
        expect(lastValuesRemoved, equals(mappedValues(i)));

        expect(streamSet, equals(onUpdateValue));
      }

      streamSet.removeEventListener();

      expect(streamSet.numberOfEventListeners, equals(1));

      // Test [onChange].
      expect(streamSet.hasChangeEvent, equals(false));

      var changes = 0;
      int lastValueChanged;

      streamSet.onChange = (change) {
        changes++;
        lastValueChanged = change.value;
      };

      expect(streamSet.hasChangeEvent, equals(true));

      completer = Completer<void>();
      onComplete = completer.future;

      streamSet.clear();

      expect(updated, equals(4000));
      expect(events, equals(2001));
      expect(changes, equals(10));
      expect(lastValueChanged, equals(9));
      expect(lastValuesListened, equals(testValues));

      await onComplete;

      expect(listenedEvents, equals(3998));
      expect(lastValuesListened, equals(null));

      // Test change listeners.
      expect(streamSet.hasChangeListener, equals(false));

      var listenedChanges = 0;

      int lastChangeValueAdded;
      int lastChangeValueRemoved;

      streamSet.addChangeListener((change) {
        listenedChanges++;

        switch (change.type) {
          case CollectionEventType.addition:
            lastChangeValueAdded = change.value;
            break;
          case CollectionEventType.removal:
            lastChangeValueRemoved = change.value;
            break;
          default:
            break;
        }

        if (change.value % 10 == 9) {
          completer.complete();
        }
      });

      expect(streamSet.hasChangeListener, equals(true));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamSet.addAll(mappedValues(i));

        expect(updated, equals((i + 1) + 4000));
        expect(events, equals((i + 1) + 2001));
        expect(changes, equals(((i + 2) * 10)));
        expect(lastValueChanged, equals((i * 10) + 9));

        await onComplete;

        expect(listened, equals(i + 6000));
        expect(lastValuesListened, equals(mappedValues(i)));

        expect(listenedEvents, equals((i + 1) + 3998));
        expect(lastValuesAdded, equals(mappedValues(i)));
        expect(lastValuesRemoved, equals(testValues));

        expect(listenedChanges, equals((i + 1) * 10));
        expect(lastChangeValueAdded, equals(((i + 1) * 10) - 1));
        expect(lastChangeValueRemoved, equals(null));

        expect(streamSet, equals(onUpdateValue));
      }

      expect(streamSet.numberOfChangeListeners, equals(1));

      streamSet.addChangeListener((event) {
        listenedChanges += 2;
      });

      expect(streamSet.numberOfChangeListeners, equals(2));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamSet.removeAll(List<int>.generate(10, (index) => i * 10 + index));

        expect(updated, equals((1000 - i) + 5000));
        expect(events, equals((1000 - i + 1) + 3000));
        expect(changes, equals(((999 - i + 2) * 10) + 10000));

        await onComplete;

        expect(listened, equals((999 - i) + 7000));

        expect(listenedEvents, equals((999 - i) + 4999));
        expect(lastValuesAdded, equals(mappedValues(999)));

        expect(listenedChanges, equals(((1000 - i) * 30) + 10000));
        expect(lastChangeValueAdded, equals(9999));

        if (streamSet.isNotEmpty) {
          expect(lastValuesListened, equals(mappedValues(i - 1).toList()));
          expect(lastValuesRemoved, equals(mappedValues(i).toList()));
          expect(lastChangeValueRemoved, equals((i * 10) + 9));
        }

        expect(streamSet, equals(onUpdateValue));
      }

      expect(streamSet.isObserved, equals(true));

      streamSet.dispose();

      expect(streamSet.hasUpdate, equals(false));
      expect(streamSet.hasEvent, equals(false));
      expect(streamSet.hasChangeEvent, equals(false));
      expect(streamSet.isObserved, equals(false));
      expect(streamSet.wasDisposed, equals(true));
    });
  });

  group('StreamMap', () {
    test('Single-Event', () async {
      final streamMap = StreamMap<int, int>();

      Completer<void> completer;
      Future<void> onComplete;

      expect(streamMap.isObserved, equals(false));
      expect(streamMap.hasEvent, equals(false));
      expect(streamMap.isEmpty, equals(true));

      // Test [onUpdate].
      var updated = 0;
      Map<int, int> onUpdateValue;

      streamMap.onUpdate = (value) {
        updated++;
        onUpdateValue = Map<int, int>.from(value);
      };

      expect(streamMap.isObserved, equals(true));

      streamMap.addAll({0: 0});

      expect(updated, equals(1));
      expect(streamMap.isNotEmpty, equals(true));
      expect(streamMap, equals(onUpdateValue));

      // Test update listeners.
      expect(streamMap.hasListener, equals(false));

      var listened = 0;
      var lastListenedValue = 0;

      streamMap.addListener((value) {
        listened++;
        lastListenedValue = value.isNotEmpty ? value.values.last : null;
        completer.complete();
      });

      expect(streamMap.hasListener, equals(true));

      for (var i = 1; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap.addAll({i: i});

        expect(updated, equals(i + 1));

        await onComplete;

        expect(listened, equals(i));
        expect(lastListenedValue, equals(i));

        expect(streamMap, equals(onUpdateValue));
      }

      expect(streamMap.numberOfListeners, equals(1));

      streamMap.addListener((value) {
        listened += 2;
        if (streamMap.numberOfListeners == 1) {
          lastListenedValue = value.values.last;
          completer.complete();
        }
      });

      expect(streamMap.numberOfListeners, equals(2));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap.remove(i);

        expect(updated, equals(2000 - i));

        await onComplete;

        expect(listened, equals((((1000 - i) * 3) - 1) + 1000));
        expect(lastListenedValue, equals(i - 1));

        expect(streamMap, equals(onUpdateValue));
      }

      // Test [onEvent].
      expect(streamMap.hasEvent, equals(false));

      var events = 0;
      int eventValue;

      streamMap.onEvent = (event) {
        events++;
        eventValue = event.values.first;
      };

      expect(streamMap.hasEvent, equals(true));

      completer = Completer<void>();
      onComplete = completer.future;

      streamMap.remove(0);

      expect(updated, equals(2000));
      expect(events, equals(1));
      expect(eventValue, equals(0));

      expect(streamMap.isEmpty, equals(true));

      await onComplete;

      expect(lastListenedValue, equals(null));

      streamMap.removeListener();

      expect(streamMap.numberOfListeners, equals(1));

      // Test event listeners.
      expect(streamMap.hasEventListener, equals(false));

      var listenedEvents = 0;

      int lastValueAdded;
      int lastValueRemoved;
      int lastValueUpdated;

      streamMap.addEventListener((event) {
        listenedEvents++;

        final value = event.values.first;

        switch (event.type) {
          case CollectionEventType.addition:
            lastValueAdded = value;
            break;
          case CollectionEventType.removal:
            lastValueRemoved = value;
            break;
          case CollectionEventType.update:
            lastValueUpdated = value;
            break;
        }
      });

      expect(streamMap.hasEventListener, equals(true));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap.addAll({i: i});

        expect(updated, equals((i + 1) + 2000));
        expect(events, equals(i + 2));

        await onComplete;

        expect(listened, equals(i + 4000));
        expect(lastListenedValue, equals(i));

        expect(listenedEvents, equals(i + 1));
        expect(lastValueAdded, equals(i));
        expect(lastValueRemoved, equals(null));
        expect(lastValueUpdated, equals(null));

        expect(streamMap, equals(onUpdateValue));
      }

      expect(streamMap.numberOfEventListeners, equals(1));

      streamMap.addEventListener((event) {
        listenedEvents += 2;
      });

      expect(streamMap.numberOfEventListeners, equals(2));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap[i] = 999 - i;

        expect(updated, equals((i + 1) + 3000));
        expect(events, equals((i + 2) + 1000));

        await onComplete;

        expect(listened, equals(i + 5000));
        expect(lastListenedValue, equals(streamMap.values.last));

        expect(listenedEvents, equals(((i + 1) * 3) + 1000));
        expect(lastValueAdded, equals(999));
        expect(lastValueRemoved, equals(null));
        expect(lastValueUpdated, equals(999 - i));

        expect(streamMap, equals(onUpdateValue));
      }

      streamMap.removeEventListener();

      expect(streamMap.numberOfEventListeners, equals(1));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap.remove(i);

        expect(updated, equals((1000 - i) + 4000));
        expect(events, equals((1000 - i + 1) + 2000));

        await onComplete;

        expect(listened, equals((999 - i) + 6000));
        expect(lastListenedValue, equals(streamMap.values.last));

        expect(listenedEvents, equals((1000 - i) + 4000));
        expect(lastValueAdded, equals(999));
        expect(lastValueRemoved, equals(999 - i));
        expect(lastValueUpdated, equals(0));

        expect(streamMap, equals(onUpdateValue));
      }

      // Test [onChange].
      expect(streamMap.hasChangeEvent, equals(false));

      var changes = 0;
      int lastValueChanged;

      streamMap.onChange = (change) {
        changes++;
        lastValueChanged = change.value;
      };

      expect(streamMap.hasChangeEvent, equals(true));

      completer = Completer<void>();
      onComplete = completer.future;

      streamMap.remove(0);

      expect(updated, equals(5000));
      expect(events, equals(3001));
      expect(changes, equals(1));
      expect(lastValueChanged, equals(999));
      expect(lastListenedValue, equals(999));

      await onComplete;

      expect(listenedEvents, equals(5000));
      expect(lastListenedValue, equals(null));

      // Test change listeners.
      expect(streamMap.hasChangeListener, equals(false));

      var listenedChanges = 0;

      int lastChangeValueAdded;
      int lastChangeValueRemoved;
      int lastChangeValueUpdated;

      streamMap.addChangeListener((change) {
        listenedChanges++;

        switch (change.type) {
          case CollectionEventType.addition:
            lastChangeValueAdded = change.value;
            break;
          case CollectionEventType.removal:
            lastChangeValueRemoved = change.value;
            break;
          case CollectionEventType.update:
            lastChangeValueUpdated = change.value;
            break;
        }
      });

      expect(streamMap.hasChangeListener, equals(true));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap.addAll({i: i});

        expect(updated, equals((i + 1) + 5000));
        expect(events, equals((i + 1) + 3001));
        expect(changes, equals(i + 2));
        expect(lastValueChanged, equals(i));

        await onComplete;

        expect(listened, equals(i + 7000));
        expect(lastListenedValue, equals(streamMap.values.last));

        expect(listenedEvents, equals((i + 1) + 5000));
        expect(lastValueAdded, equals(i));
        expect(lastValueRemoved, equals(999));
        expect(lastValueUpdated, equals(0));

        expect(listenedChanges, equals(i + 1));
        expect(lastChangeValueAdded, equals(i));
        expect(lastChangeValueRemoved, equals(null));
        expect(lastChangeValueUpdated, equals(null));

        expect(streamMap, equals(onUpdateValue));
      }

      expect(streamMap.numberOfChangeListeners, equals(1));

      streamMap.addChangeListener((event) {
        listenedChanges += 2;
      });

      expect(streamMap.numberOfChangeListeners, equals(2));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap[i] = 999 - i;

        expect(updated, equals((i + 1) + 6000));
        expect(events, equals((i + 1) + 4001));
        expect(changes, equals((i + 2) + 1000));
        expect(lastValueChanged, equals(streamMap[i]));

        await onComplete;

        expect(listened, equals(i + 8000));
        expect(lastListenedValue, equals(streamMap.values.last));

        expect(listenedEvents, equals((i + 1) + 6000));
        expect(lastValueAdded, equals(999));
        expect(lastValueRemoved, equals(999));
        expect(lastValueUpdated, equals(streamMap[i]));

        expect(listenedChanges, equals(((i + 1) * 3) + 1000));
        expect(lastChangeValueAdded, equals(999));
        expect(lastChangeValueRemoved, equals(null));
        expect(lastChangeValueUpdated, equals(streamMap[i]));

        expect(streamMap, equals(onUpdateValue));
      }

      streamMap.removeChangeListener();

      expect(streamMap.numberOfChangeListeners, equals(1));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap.remove(i);

        expect(updated, equals((1000 - i) + 7000));
        expect(events, equals((1000 - i) + 5001));
        expect(changes, equals((1000 - i + 1) + 2000));

        await onComplete;

        expect(listened, equals((999 - i) + 9000));

        expect(listenedEvents, equals((1000 - i) + 7000));
        expect(lastValueAdded, equals(999));
        expect(lastValueUpdated, equals(0));

        expect(listenedChanges, equals((1000 - i) + 4000));
        expect(lastChangeValueAdded, equals(999));
        expect(lastChangeValueUpdated, equals(0));

        if (streamMap.isNotEmpty) {
          final last = streamMap.values.last;
          expect(lastListenedValue, equals(last));
          expect(lastValueRemoved, equals(last - 1));
          expect(lastChangeValueRemoved, equals(last - 1));
        }

        expect(streamMap, equals(onUpdateValue));
      }

      expect(streamMap.isObserved, equals(true));

      streamMap.dispose();

      expect(streamMap.hasUpdate, equals(false));
      expect(streamMap.hasEvent, equals(false));
      expect(streamMap.hasChangeEvent, equals(false));
      expect(streamMap.isObserved, equals(false));
      expect(streamMap.wasDisposed, equals(true));
    });

    test('Multi-Event', () async {
      final streamMap = StreamMap<int, int>();

      Completer<void> completer;
      Future<void> onComplete;

      expect(streamMap.isObserved, equals(false));
      expect(streamMap.hasEvent, equals(false));
      expect(streamMap.isEmpty, equals(true));

      final testValues = <int, int>{
        0: 0,
        1: 1,
        2: 2,
        3: 3,
        4: 4,
        5: 5,
        6: 6,
        7: 7,
        8: 8,
        9: 9
      };

      Map<int, int> mappedMap(int i) => testValues.map<int, int>(
          (key, value) => MapEntry((i * 10) + key, (i * 10) + value));

      Iterable<int> mappedValues(int i) =>
          testValues.values.map<int>((value) => (i * 10) + value);

      // Test [onUpdate].
      var updated = 0;
      Map<int, int> onUpdateValue;

      streamMap.onUpdate = (value) {
        updated++;
        onUpdateValue = Map<int, int>.from(value);
      };

      expect(streamMap.isObserved, equals(true));

      streamMap.addAll(testValues);

      expect(updated, equals(1));
      expect(streamMap.isNotEmpty, equals(true));
      expect(streamMap, equals(onUpdateValue));

      // Test update listeners.
      expect(streamMap.hasListener, equals(false));

      var listened = 0;
      List<int> lastValuesListened;

      streamMap.addListener((value) {
        listened++;
        lastValuesListened = value.isEmpty
            ? null
            : value.values.toList().sublist(value.length - 10);
        if (!streamMap.hasChangeListener) {
          completer.complete();
        }
      });

      expect(streamMap.hasListener, equals(true));

      for (var i = 1; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap.addAll(mappedMap(i));

        expect(updated, equals(i + 1));

        await onComplete;

        expect(listened, equals(i));
        expect(lastValuesListened, equals(mappedValues(i)));

        expect(streamMap, equals(onUpdateValue));
      }

      expect(streamMap.numberOfListeners, equals(1));

      streamMap.addListener((value) {
        listened += 2;
        if (streamMap.numberOfListeners == 1) {
          lastValuesListened = List<int>.from(value.values);
          completer.complete();
        }
      });

      expect(streamMap.numberOfListeners, equals(2));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        final valuesToRemove = mappedValues(i);
        streamMap.removeWhere((key, value) => valuesToRemove.contains(value));

        expect(updated, equals(2000 - i));

        await onComplete;

        expect(listened, equals((((1000 - i) * 3) - 1) + 1000));
        expect(lastValuesListened, equals(mappedValues(i - 1)));

        expect(streamMap, equals(onUpdateValue));
      }

      // Test [onEvent].
      expect(streamMap.hasEvent, equals(false));

      var events = 0;
      List<int> eventValues;
      var numberOfEventValues = 0;

      streamMap.onEvent = (event) {
        events++;
        eventValues = event.values;
        numberOfEventValues += eventValues.length;
      };

      expect(streamMap.hasEvent, equals(true));

      completer = Completer<void>();
      onComplete = completer.future;

      streamMap.removeWhere((key, value) => testValues.values.contains(value));

      expect(updated, equals(2000));
      expect(events, equals(1));
      expect(numberOfEventValues, equals(10));
      expect(eventValues, equals(testValues.values));

      expect(streamMap.isEmpty, equals(true));

      await onComplete;

      expect(lastValuesListened, equals(null));

      streamMap.removeListener();

      expect(streamMap.numberOfListeners, equals(1));

      // Test event listeners.
      expect(streamMap.hasEventListener, equals(false));

      var listenedEvents = 0;

      List<int> lastValuesAdded;
      List<int> lastValuesRemoved;
      List<int> lastValuesUpdated;

      streamMap.addEventListener((event) {
        listenedEvents++;

        switch (event.type) {
          case CollectionEventType.addition:
            lastValuesAdded = event.values;
            break;
          case CollectionEventType.removal:
            lastValuesRemoved = event.values;
            break;
          case CollectionEventType.update:
            lastValuesUpdated = event.values;
            break;
        }
      });

      expect(streamMap.hasEventListener, equals(true));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap.addAll(mappedMap(i));

        expect(updated, equals((i + 1) + 2000));
        expect(events, equals(i + 2));

        await onComplete;

        expect(listened, equals(i + 4000));
        expect(lastValuesListened, equals(mappedValues(i)));

        expect(listenedEvents, equals(i + 1));
        expect(lastValuesAdded, equals(mappedValues(i)));
        expect(lastValuesRemoved, equals(null));
        expect(lastValuesUpdated, equals(null));

        expect(streamMap, equals(onUpdateValue));
      }

      expect(streamMap.numberOfEventListeners, equals(1));

      streamMap.addEventListener((event) {
        listenedEvents += 2;
      });

      expect(streamMap.numberOfEventListeners, equals(2));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap.updateAll((key, value) => key >= i * 10 && key < (i + 1) * 10
            ? ((999 - i) * 10) + (value % 10)
            : value);

        expect(updated, equals((i + 1) + 3000));
        expect(events, equals((i + 2) + 1000));

        await onComplete;

        expect(listened, equals(i + 5000));
        if (i == 999) {
          expect(lastValuesListened, equals(testValues.values));
        } else {
          expect(lastValuesListened, equals(mappedValues(999)));
        }

        expect(listenedEvents, equals(((i + 1) * 3) + 1000));
        expect(lastValuesAdded, equals(mappedValues(999)));
        expect(lastValuesRemoved, equals(null));
        expect(lastValuesUpdated, equals(mappedValues(999 - i)));

        expect(streamMap, equals(onUpdateValue));
      }

      streamMap.removeEventListener();

      expect(streamMap.numberOfEventListeners, equals(1));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap
            .removeWhere((key, value) => key >= i * 10 && key <= (i + 1) * 10);

        expect(updated, equals((1000 - i) + 4000));
        expect(events, equals((1000 - i) + 2001));

        await onComplete;

        expect(listened, equals((999 - i) + 6000));
        expect(lastValuesListened, equals(mappedValues(1000 - i)));

        expect(listenedEvents, equals((1000 - i) + 4000));
        expect(lastValuesAdded, equals(mappedValues(999)));
        expect(lastValuesRemoved, equals(mappedValues(999 - i)));
        expect(lastValuesUpdated, equals(testValues.values));

        expect(streamMap, equals(onUpdateValue));
      }

      // Test [onChange].
      expect(streamMap.hasChangeEvent, equals(false));

      var changes = 0;
      int lastValueChanged;

      streamMap.onChange = (change) {
        changes++;
        lastValueChanged = change.value;
      };

      expect(streamMap.hasChangeEvent, equals(true));

      completer = Completer<void>();
      onComplete = completer.future;

      streamMap.clear();

      expect(updated, equals(5000));
      expect(events, equals(3001));
      expect(changes, equals(10));
      expect(lastValueChanged, equals(9999));
      expect(lastValuesListened, equals(mappedValues(999)));

      await onComplete;

      expect(listenedEvents, equals(5000));
      expect(lastValuesListened, equals(null));

      // Test change listeners.
      expect(streamMap.hasChangeListener, equals(false));

      var listenedChanges = 0;

      int lastChangeValueAdded;
      int lastChangeValueRemoved;
      int lastChangeValueUpdated;

      streamMap.addChangeListener((change) {
        listenedChanges++;

        switch (change.type) {
          case CollectionEventType.addition:
            lastChangeValueAdded = change.value;
            break;
          case CollectionEventType.removal:
            lastChangeValueRemoved = change.value;
            break;
          case CollectionEventType.update:
            lastChangeValueUpdated = change.value;
            break;
        }

        if (change.value % 10 == 9) {
          completer.complete();
        }
      });

      expect(streamMap.hasChangeListener, equals(true));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap.addAll(mappedMap(i));

        expect(updated, equals((i + 1) + 5000));
        expect(events, equals((i + 1) + 3001));
        expect(changes, equals(((i + 2) * 10)));
        expect(lastValueChanged, equals((i * 10) + 9));

        await onComplete;

        expect(listened, equals(i + 7000));
        expect(lastValuesListened, equals(mappedValues(i)));

        expect(listenedEvents, equals((i + 1) + 5000));
        expect(lastValuesAdded, equals(mappedValues(i)));
        expect(lastValuesRemoved, equals(mappedValues(999)));
        expect(lastValuesUpdated, equals(testValues.values));

        expect(listenedChanges, equals((i + 1) * 10));
        expect(lastChangeValueAdded, equals(((i + 1) * 10) - 1));
        expect(lastChangeValueRemoved, equals(null));
        expect(lastChangeValueUpdated, equals(null));

        expect(streamMap, equals(onUpdateValue));
      }

      expect(streamMap.numberOfChangeListeners, equals(1));

      streamMap.addChangeListener((event) {
        listenedChanges += 2;
      });

      expect(streamMap.numberOfChangeListeners, equals(2));

      for (var i = 0; i < 1000; i++) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap.updateAll((key, value) => key >= i * 10 && key < (i + 1) * 10
            ? ((999 - i) * 10) + (value % 10)
            : value);

        expect(updated, equals((i + 1) + 6000));
        expect(events, equals((i + 1) + 4001));
        expect(changes, equals(((i + 2) * 10) + 10000));
        expect(lastValueChanged, equals(((999 - i) * 10) + 9));

        await onComplete;

        expect(listened, equals(i + 8000));
        if (i == 999) {
          expect(lastValuesListened, equals(testValues.values));
        } else {
          expect(lastValuesListened, equals(mappedValues(999)));
        }

        expect(listenedEvents, equals((i + 1) + 6000));
        expect(lastValuesAdded, equals(mappedValues(999)));
        expect(lastValuesRemoved, equals(mappedValues(999)));
        expect(lastValuesUpdated, equals(mappedValues(999 - i)));

        expect(listenedChanges, equals(((i + 1) * 30) + 10000));
        expect(lastChangeValueAdded, equals(9999));
        expect(lastChangeValueRemoved, equals(null));
        expect(lastChangeValueUpdated, equals(((999 - i) * 10) + 9));

        expect(streamMap, equals(onUpdateValue));
      }

      streamMap.removeChangeListener();

      expect(streamMap.numberOfChangeListeners, equals(1));

      for (var i = 999; i > 0; i--) {
        completer = Completer<void>();
        onComplete = completer.future;

        streamMap
            .removeWhere((key, value) => key >= i * 10 && key <= (i + 1) * 10);

        expect(updated, equals((1000 - i) + 7000));
        expect(events, equals((1000 - i + 1) + 5000));
        expect(changes, equals(((999 - i + 2) * 10) + 20000));

        await onComplete;

        expect(listened, equals((999 - i) + 9000));
        expect(lastValuesListened, equals(mappedValues(1000 - i)));

        expect(listenedEvents, equals((1000 - i) + 7000));
        expect(lastValuesAdded, equals(mappedValues(999)));
        expect(lastValuesUpdated, equals(testValues.values));
        expect(lastValuesRemoved, equals(mappedValues(999 - i)));

        expect(listenedChanges, equals(((1000 - i) * 10) + 40000));
        expect(lastChangeValueAdded, equals(9999));
        expect(lastChangeValueUpdated, equals(9));
        expect(lastChangeValueRemoved, equals(((999 - i) * 10) + 9));

        expect(streamMap, equals(onUpdateValue));
      }

      expect(streamMap.isObserved, equals(true));

      streamMap.dispose();

      expect(streamMap.hasUpdate, equals(false));
      expect(streamMap.hasEvent, equals(false));
      expect(streamMap.hasChangeEvent, equals(false));
      expect(streamMap.isObserved, equals(false));
      expect(streamMap.wasDisposed, equals(true));
    });
  });
}
