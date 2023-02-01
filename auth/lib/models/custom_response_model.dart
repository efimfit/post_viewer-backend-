class CustomResponseModel {
  final dynamic data;
  final dynamic message;
  final dynamic error;

  CustomResponseModel({
    this.data,
    this.message,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data ?? '',
      'message': message ?? '',
      'error': error ?? '',
    };
  }
}
