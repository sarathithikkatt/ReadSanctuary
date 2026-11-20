/// Core failure types for ReadSanctuary domain and data layers.
abstract class Failure {
  final String message;
  final dynamic cause;

  const Failure(this.message, [this.cause]);

  @override
  String toString() => '$runtimeType: $message';
}

/// Returned when a remote API or server responds with an error.
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, [this.statusCode, super.cause]);
}

/// Returned when device cannot connect to network (timeout, socket exception).
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.cause]);
}

/// Returned when remote API responds with HTTP 429 Too Many Requests.
class RateLimitFailure extends Failure {
  final Duration? retryAfter;

  const RateLimitFailure(super.message, [this.retryAfter, super.cause]);
}

/// Returned when a requested entity or ISBN is not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, [super.cause]);
}

/// Returned when local database query, insert, or migration fails.
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.cause]);
}

/// Returned when backup export, decompression, or restore merge fails.
class BackupFailure extends Failure {
  const BackupFailure(super.message, [super.cause]);
}

/// Simple functional Result type for operations that can fail without throwing.
class Result<T> {
  final T? data;
  final Failure? failure;
  final bool isSuccess;

  const Result.success(this.data)
      : failure = null,
        isSuccess = true;

  const Result.failure(this.failure)
      : data = null,
        isSuccess = false;

  R fold<R>({
    required R Function(Failure failure) onFailure,
    required R Function(T data) onSuccess,
  }) {
    if (isSuccess) {
      return onSuccess(data as T);
    } else {
      return onFailure(failure!);
    }
  }
}
