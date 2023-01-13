
abstract class _BaseError implements Error {
  String get message;

  @override
  String toString() => message;
}

class EntrypointMissingError implements _BaseError {
  @override
  final String message;

  @override
  late final StackTrace stackTrace;

  EntrypointMissingError(this.message, [StackTrace? stackTrace]) {
    this.stackTrace = stackTrace ?? StackTrace.current;
  }

}

class AppClientMissingError implements _BaseError {
  @override
  final String message;

  @override
  late final StackTrace stackTrace;

  AppClientMissingError(this.message, [StackTrace? stackTrace]) {
    this.stackTrace = stackTrace ?? StackTrace.current;
  }

}