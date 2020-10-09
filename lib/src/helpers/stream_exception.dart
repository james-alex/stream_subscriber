class StreamException implements Exception {
  StreamException() : message = 'The stream has already been disposed of.';

  final String message;

  @override
  String toString() => 'Exception: $message';
}
