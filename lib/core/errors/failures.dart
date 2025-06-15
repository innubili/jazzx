import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

// Result type for better error handling
abstract class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);
}

// Extension methods for easier usage
extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;

  T? get data => isSuccess ? (this as Success<T>).data : null;
  Failure? get failure => isError ? (this as Error<T>).failure : null;

  R fold<R>(R Function(Failure) onError, R Function(T) onSuccess) {
    if (isError) {
      return onError((this as Error<T>).failure);
    } else {
      return onSuccess((this as Success<T>).data);
    }
  }

  // Additional convenience methods
  void when({
    required void Function(T data) onSuccess,
    required void Function(Failure failure) onError,
  }) {
    if (isSuccess) {
      onSuccess((this as Success<T>).data);
    } else {
      onError((this as Error<T>).failure);
    }
  }
}
