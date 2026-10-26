// Class: custom application exception with user-friendly error message.
class AppException implements Exception {
  // Field: user-friendly message.
  final String message;

  // Constructor: requires user-friendly message.
  const AppException(this.message);

  // Override: string representation.
  @override
  String toString() => message;
}

// Class: exception thrown when required permissions are denied.
class PermissionException extends AppException {
  // Field: true if the permission was permanently denied.
  final bool permanent;

  // Constructor: builds permission exception.
  const PermissionException({
    String message = 'Permission denied to access videos.',
    this.permanent = false,
  }) : super(message);
}
