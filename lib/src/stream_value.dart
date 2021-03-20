import 'helpers/stream_exception.dart';
import 'helpers/typedefs.dart';
import 'stream_subscriber.dart';

/// A observable object that notifies its subscribers when
/// its value has been modified.
class StreamValue<T> with StreamSubscriber<T> {
  /// A observable object that notifies its subscribers when
  /// its value has been modified.
  ///
  /// [value] is the initial value.
  ///
  /// [onUpdate] is a synchronous event called each time the value is modified.
  ///
  /// __Warning:__ Updating the [value] directly from within [onUpdate]
  /// will cause [onUpdate] to be called endlessly, triggering a stack
  /// overflow, instead the [setValue] method must be used to update the
  /// [value] without notifying the listeners or triggering [onUpdate].
  StreamValue(T value, {this.onUpdate}) : _value = value;

  /// The value being observed.
  T get value => _value;

  /// Update the value and notify the listeners.
  set value(T value) {
    _value = value;
    notifyListeners(value);
  }

  /// The internal reference to the value being observed.
  T _value;

  /// Called after [value] is updated, before the listeners are notified.
  OnUpdate<T>? onUpdate;

  /// Returns `true` if there are any active listeners or
  /// if [onUpdate] is not `null`.
  bool get isObserved => wasDisposed ? false : hasListener || onUpdate != null;

  /// Set to `true` when [dispose] is called.
  ///
  /// If `true`, [onUpdate] will not be called when [value] is updated.
  bool wasDisposed = false;

  /// Sets the observable value to [value] without notifying
  /// the event listeners.
  void setValue(T value) => _value = value;

  /// Notifies all subscribed listeners of an [event].
  @override
  void notifyListeners(T event) {
    if (wasDisposed) throw StreamException();
    if (onUpdate != null) onUpdate!(event);
    super.notifyListeners(event);
  }

  @override
  void dispose() {
    wasDisposed = true;
    super.dispose();
  }

  @override
  String toString() => _value.toString();
}
