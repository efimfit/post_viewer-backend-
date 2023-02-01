import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

import 'package:auth/utils/app_env.dart';

abstract class AppUtils {
  static int getIdFromToken(String token) {
    try {
      final jwtClaim = verifyJwtHS256Signature(token, AppEnv.secretKey);
      return int.parse(jwtClaim['id'].toString());
    } catch (_) {
      rethrow;
    }
  }

  static int getIdFromHeader(String header) {
    try {
      final token = AuthorizationBearerParser().parse(header);
      return getIdFromToken(token ?? '');
    } catch (_) {
      rethrow;
    }
  }
}
