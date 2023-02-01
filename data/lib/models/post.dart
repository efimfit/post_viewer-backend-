import 'package:conduit/conduit.dart';

import 'package:data/models/author.dart';

class Post extends ManagedObject<_Post> implements _Post {}

class _Post {
  @primaryKey
  int? id;
  String? name;
  String? preContent;
  @Column(omitByDefault: true)
  String? content;
  @Relate(#postList, isRequired: true, onDelete: DeleteRule.cascade)
  Author? author;
}
