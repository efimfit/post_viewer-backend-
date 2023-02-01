import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

import 'package:data/models/custom_response_model.dart';

class AppResponse extends Response {
  AppResponse.ok({dynamic body, String? message})
      : super.ok(CustomResponseModel(data: body, message: message));

  AppResponse.serverError(dynamic error, {String? message})
      : super.serverError(body: _getResponseModel(error, message));

  AppResponse.badRequest({String? message})
      : super.badRequest(body: CustomResponseModel(message: message));

  AppResponse.undataorized({String? message})
      : super.unauthorized(body: CustomResponseModel(message: message));

  static CustomResponseModel _getResponseModel(error, String? message) {
    if (error is QueryException || error is JwtException) {
      return CustomResponseModel(
        message: '$message: ${error.message}',
        error: error.toString(),
      );
    }
    return CustomResponseModel(
      message: message,
      error: error.toString(),
    );
  }
}
