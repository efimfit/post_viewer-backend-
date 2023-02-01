import 'dart:async';
import 'dart:io';
import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

import 'package:auth/utils/app_response.dart';
import 'package:auth/utils/app_env.dart';

class AppTokenController extends Controller {
  @override
  FutureOr<RequestOrResponse?> handle(Request request) {
    try {
      final header = request.raw.headers.value(HttpHeaders.authorizationHeader);
      final token = AuthorizationBearerParser().parse(header);
      final jwtClaim = verifyJwtHS256Signature(token ?? '', AppEnv.secretKey);
      jwtClaim.validate();
      return request;
    } catch (e) {
      return AppResponse.unauthorized(e, message: 'Token validation failed');
    }
  }
}
