import 'dart:io';
import 'package:conduit/conduit.dart';

import 'package:data/models/post.dart';
import 'package:data/models/author.dart';
import 'package:data/utils/app_utils.dart';
import 'package:data/utils/app_response.dart';

class AppPostController extends ResourceController {
  final ManagedContext managedContext;

  AppPostController(this.managedContext);

  @Operation.post()
  Future<Response> createPost(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.body() Post post) async {
    try {
      if (post.content == null ||
          post.content?.isEmpty == true ||
          post.name == null ||
          post.name?.isEmpty == true) {
        return AppResponse.badRequest(
            message: '"Name" and "content" fields are mandatory');
      }
      final id = AppUtils.getIdFromHeader(header);
      final author = await managedContext.fetchObjectWithID<Author>(id);
      if (author == null) {
        final queryCreateAuthor = Query<Author>(managedContext)..values.id = id;
        await queryCreateAuthor.insert();
      }
      final contentSize = post.content?.length ?? 0;
      final preContentSize = contentSize <= 20 ? contentSize : 20;
      final queryCreatePost = Query<Post>(managedContext)
        ..values.author?.id = id
        ..values.name = post.name
        ..values.preContent = post.content?.substring(0, preContentSize)
        ..values.content = post.content;
      await queryCreatePost.insert();
      return AppResponse.ok(message: 'Post created');
    } catch (e) {
      return AppResponse.serverError(e, message: 'Post create error');
    }
  }

  @Operation.get('id')
  Future<Response> getPost(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path('id') int id) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final queryGetPost = Query<Post>(managedContext)
        ..where((x) => x.id).equalTo(id)
        ..where((x) => x.author?.id).equalTo(currentUserId)
        ..returningProperties((x) => [x.content, x.id, x.name]);
      final post = await queryGetPost.fetchOne();
      if (post == null) {
        return AppResponse.ok(message: 'Post is not found');
      }
      return AppResponse.ok(
          body: post.backing.contents, message: 'Post received');
    } catch (e) {
      return AppResponse.serverError(e, message: 'Post receiving error');
    }
  }

  @Operation.get()
  Future<Response> getPosts(
      @Bind.header(HttpHeaders.authorizationHeader) String header) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final queryGetPosts = Query<Post>(managedContext)
        ..where((post) => post.author?.id).equalTo(currentUserId);
      final List<Post> posts = await queryGetPosts.fetch();
      if (posts.isEmpty) {
        return AppResponse.ok(message: 'Posts not found');
      }
      final backedPosts = posts.map((e) {
        e.backing.removeProperty('author');
        return e.backing.contents;
      }).toList();
      return AppResponse.ok(body: backedPosts, message: 'Posts received');
    } catch (e) {
      return AppResponse.serverError(e, message: 'Post create error');
    }
  }

  @Operation.delete('id')
  Future<Response> deletePost(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.path('id') int id) async {
    try {
      final currentUserId = AppUtils.getIdFromHeader(header);
      final post = await managedContext.fetchObjectWithID<Post>(id);
      if (post == null) {
        return AppResponse.ok(message: 'Post is not found');
      }
      if (post.author?.id != currentUserId) {
        return AppResponse.ok(message: 'Access to post is restricted for you');
      }
      final queryDeletePost = Query<Post>(managedContext)
        ..where((post) => post.id).equalTo(id);
      await queryDeletePost.delete();
      return AppResponse.ok(message: 'Post removed');
    } catch (e) {
      return AppResponse.serverError(e, message: 'Post remove error');
    }
  }
}
