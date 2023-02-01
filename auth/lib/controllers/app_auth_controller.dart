import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

import 'package:auth/models/user_model.dart';
import 'package:auth/utils/app_utils.dart';
import 'package:auth/utils/app_response.dart';
import 'package:auth/utils/app_env.dart';

class AppAuthController extends ResourceController {
  final ManagedContext managedContext;

  AppAuthController(this.managedContext);

  @Operation.post()
  Future<Response> signIn(@Bind.body() UserModel user) async {
    if (user.username == null || user.password == null) {
      return AppResponse.badRequest(
          message: 'Username and password fields are mandatory');
    }
    try {
      final qFindUser = Query<UserModel>(managedContext)
        ..where((table) => table.username).equalTo(user.username)
        ..returningProperties(
            (table) => [table.id, table.salt, table.hashPassword]);
      final findUser = await qFindUser.fetchOne();
      if (findUser == null) {
        throw QueryException.input("User is not found", []);
      }
      final hashPassword = generatePasswordHash(user.password!, findUser.salt!);
      if (hashPassword == findUser.hashPassword) {
        await _updateTokens(findUser.id!, managedContext);
        final updatedUser =
            await managedContext.fetchObjectWithID<UserModel>(findUser.id);
        return AppResponse.ok(
            body: updatedUser!.backing.contents,
            message: 'Signin is successfull');
      } else {
        throw QueryException.input("Password is not correct", []);
      }
    } catch (e) {
      return AppResponse.serverError(e, message: 'Signin failed');
    }
  }

  @Operation.put()
  Future<Response> signUp(@Bind.body() UserModel user) async {
    if (user.username == null || user.password == null || user.email == null) {
      return AppResponse.badRequest(
          message: 'Username, password and email fields are mandatory');
    }
    final salt = generateRandomSalt();
    final hashPassword = generatePasswordHash(user.password!, salt);

    try {
      late final int id;
      await managedContext.transaction((transaction) async {
        final qCreateUser = Query<UserModel>(transaction)
          ..values.username = user.username
          ..values.email = user.email
          ..values.salt = salt
          ..values.hashPassword = hashPassword;
        final createdUser = await qCreateUser.insert();
        id = createdUser.id!;
        await _updateTokens(id, transaction);
      });
      final userData = await managedContext.fetchObjectWithID<UserModel>(id);
      return AppResponse.ok(
          body: userData!.backing.contents, message: 'Signup is successfull');
    } catch (e) {
      return AppResponse.serverError(e, message: 'Signup failed');
    }
  }

  @Operation.post('refresh')
  Future<Response> refreshToken(
      @Bind.path('refresh') String refreshToken) async {
    try {
      final id = AppUtils.getIdFromToken(refreshToken);
      final user = await managedContext.fetchObjectWithID<UserModel>(id);
      if (user?.refreshToken != refreshToken) {
        return AppResponse.unauthorized(
            JwtException('Invalid or expired token'),
            message: 'Token updating failed');
      } else {
        await _updateTokens(id, managedContext);
        final user = await managedContext.fetchObjectWithID<UserModel>(id);
        return AppResponse.ok(
          body: user!.backing.contents,
          message: 'Tokens are updated',
        );
      }
    } catch (e) {
      return AppResponse.serverError(e, message: 'Token updating failed');
    }
  }

  Map<String, dynamic> _getTokens(int id) {
    final key = AppEnv.secretKey;
    final accessClaimSet = JwtClaim(
        maxAge: Duration(minutes: AppEnv.tokenLifetime),
        otherClaims: {'id': id});
    final refreshClaimSet = JwtClaim(otherClaims: {'id': id});
    final tokens = <String, dynamic>{};
    tokens['access'] = issueJwtHS256(accessClaimSet, key);
    tokens['refresh'] = issueJwtHS256(refreshClaimSet, key);
    return tokens;
  }

  Future<void> _updateTokens(int id, ManagedContext transaction) async {
    final Map<String, dynamic> tokens = _getTokens(id);
    final qUpdateTokens = Query<UserModel>(transaction)
      ..where((user) => user.id).equalTo(id)
      ..values.accessToken = tokens['access']
      ..values.refreshToken = tokens['refresh'];
    await qUpdateTokens.updateOne();
  }
}
