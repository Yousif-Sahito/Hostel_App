class ApiResult<T> {
  final bool success;
  final String message;
  final T? data;

  const ApiResult({required this.success, required this.message, this.data});

  factory ApiResult.success({String message = 'Success', T? data}) {
    return ApiResult<T>(success: true, message: message, data: data);
  }

  factory ApiResult.failure({
    String message = 'Something went wrong',
    T? data,
  }) {
    return ApiResult<T>(success: false, message: message, data: data);
  }
}
