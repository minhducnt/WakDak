class ApiMessageAndCodeException implements Exception {
  final String errorMessage;
  String? errorStatusCode;

  ApiMessageAndCodeException({required this.errorMessage, this.errorStatusCode});

  //@override
  Map toError() => {"message": errorMessage, "code": errorStatusCode};

  @override
  String toString() => errorMessage;
}
