import 'dart:io';
import 'package:conduit/conduit.dart';

import 'package:auth/models/user_model.dart';
import 'package:auth/utils/app_const.dart';
import 'package:auth/utils/app_response.dart';
import 'package:auth/utils/app_utils.dart';

class AppUserController extends ResourceController {
  final ManagedContext managedContext;

  AppUserController(this.managedContext);

  @Operation.get()
  Future<Response> getProfile(
      @Bind.header(HttpHeaders.authorizationHeader) String header) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<UserModel>(id);
      user?.removePropertiesFromBackingMap(
          [AppConst.accessToken, AppConst.refreshToken]);
      return AppResponse.ok(
          message: 'User profile received', body: user?.backing.contents);
    } catch (e) {
      return AppResponse.serverError(e,
          message: 'User profile retrieval error');
    }
  }

  @Operation.post()
  Future<Response> updateProfile(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() UserModel user,
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final fetchedUser = await managedContext.fetchObjectWithID<UserModel>(id);
      final queryUpdateUser = Query<UserModel>(managedContext)
        ..where((user) => user.id).equalTo(id)
        ..values.username = user.username ?? fetchedUser?.username
        ..values.email = user.email ?? fetchedUser?.email;
      await queryUpdateUser.updateOne();
      final updatedUser = await managedContext.fetchObjectWithID<UserModel>(id);
      updatedUser?.removePropertiesFromBackingMap(
          [AppConst.accessToken, AppConst.refreshToken]);
      return AppResponse.ok(
          body: updatedUser?.backing.contents, message: 'User profile updated');
    } catch (e) {
      return AppResponse.serverError(e, message: 'User profile update error');
    }
  }

  @Operation.put()
  Future<Response> updatePassword(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.query('oldPassword') String oldPassword,
    @Bind.query('newPassword') String newPassword,
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final queryFindUser = Query<UserModel>(managedContext)
        ..where((table) => table.id).equalTo(id)
        ..returningProperties((table) => [table.salt, table.hashPassword]);
      final fetchedUser = await queryFindUser.fetchOne() as UserModel;
      final oldPasswordHash =
          generatePasswordHash(oldPassword, fetchedUser.salt ?? '');
      if (oldPasswordHash != fetchedUser.hashPassword) {
        return AppResponse.badRequest(message: 'Password is not correct');
      }
      final newPasswordHash =
          generatePasswordHash(newPassword, fetchedUser.salt ?? '');

      final queryUpdatePassword = Query<UserModel>(managedContext)
        ..where((user) => user.id).equalTo(id)
        ..values.hashPassword = newPasswordHash;
      await queryUpdatePassword.updateOne();

      return AppResponse.ok(message: 'Password updated successfully');
    } catch (e) {
      return AppResponse.serverError(e, message: 'Password update error');
    }
  }
}
