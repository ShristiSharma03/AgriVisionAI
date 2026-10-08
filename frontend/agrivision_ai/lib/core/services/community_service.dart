import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityPost {
  final String id;
  final String uid;
  final String authorName;
  final String cropTag;
  final String text;
  final int likes;
  final int replyCount;
  final DateTime createdAt;
  final List<String> likedBy;

  CommunityPost({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.cropTag,
    required this.text,
    required this.likes,
    required this.replyCount,
    required this.createdAt,
    required this.likedBy,
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CommunityPost(
      id: doc.id,
      uid: data['uid'] ?? '',
      authorName: data['authorName'] ?? 'Farmer',
      cropTag: data['cropTag'] ?? 'General',
      text: data['text'] ?? '',
      likes: data['likes'] ?? 0,
      replyCount: data['replyCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likedBy: List<String>.from(data['likedBy'] ?? const []),
    );
  }

  bool isLikedBy(String? uid) => uid != null && likedBy.contains(uid);

  /// Human-friendly relative time, e.g. "2h ago", "3d ago".
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class CommunityComment {
  final String id;
  final String uid;
  final String authorName;
  final String text;
  final DateTime createdAt;

  CommunityComment({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory CommunityComment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CommunityComment(
      id: doc.id,
      uid: data['uid'] ?? '',
      authorName: data['authorName'] ?? 'Farmer',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('community_posts');

  CollectionReference<Map<String, dynamic>> _commentsCollection(String postId) =>
      _postsCollection.doc(postId).collection('comments');

  // ============================================================
  // POSTS
  // ============================================================

  /// Live stream of posts, optionally filtered by crop tag.
  /// Pass null or 'All Crops' to get everything.
  Stream<List<CommunityPost>> streamPosts({String? cropFilter}) {
    Query<Map<String, dynamic>> query =
        _postsCollection.orderBy('createdAt', descending: true);

    if (cropFilter != null && cropFilter != 'All Crops') {
      query = query.where('cropTag', isEqualTo: cropFilter);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs.map(CommunityPost.fromFirestore).toList(),
        );
  }

  Future<void> createPost({required String text, required String cropTag}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be signed in to post.');
    if (text.trim().isEmpty) throw Exception('Post text cannot be empty.');

    await _postsCollection.add({
      'uid': user.uid,
      'authorName': (user.displayName?.isNotEmpty ?? false) ? user.displayName : 'Farmer',
      'cropTag': cropTag,
      'text': text.trim(),
      'likes': 0,
      'likedBy': <String>[],
      'replyCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggles the current user's like on a post: likes it if not yet liked,
  /// un-likes it if already liked. Runs in a transaction, and only touches
  /// 'likes' + 'likedBy' — matching the security rule that permits update
  /// only when exactly those two fields change together, in lockstep with
  /// the caller's own uid entering/leaving likedBy.
  Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be signed in to like a post.');
    final postRef = _postsCollection.doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};
      final likedBy = List<String>.from(data['likedBy'] ?? const []);
      final currentLikes = (data['likes'] ?? 0) as int;
      final alreadyLiked = likedBy.contains(user.uid);

      if (alreadyLiked) {
        transaction.update(postRef, {
          'likedBy': FieldValue.arrayRemove([user.uid]),
          'likes': currentLikes - 1,
        });
      } else {
        transaction.update(postRef, {
          'likedBy': FieldValue.arrayUnion([user.uid]),
          'likes': currentLikes + 1,
        });
      }
    });
  }

  /// Deletes a post. Only the post's author can do this (also enforced by
  /// Firestore security rules).
  ///
  /// NOTE: this does NOT cascade-delete the post's comments. Firestore
  /// rules only allow a comment to be deleted by that comment's own
  /// author — a batch that tries to delete other users' comments as the
  /// post owner will be rejected outright (batches are all-or-nothing).
  /// Orphaned comments under a deleted post are harmless (they're just
  /// unreachable once the post is gone from any query), but if you want
  /// true cleanup, do one of:
  ///   1) Add a rule allowing comment delete when the requester's uid
  ///      matches the *parent post's* uid (needs a get() lookup in rules), or
  ///   2) Run a Cloud Function (onDelete trigger on community_posts) that
  ///      deletes the comments subcollection with admin privileges.
  Future<void> deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be signed in to delete a post.');

    final postRef = _postsCollection.doc(postId);
    final postSnap = await postRef.get();
    if (!postSnap.exists) return;
    final data = postSnap.data() ?? {};
    if (data['uid'] != user.uid) {
      throw Exception('You can only delete your own posts.');
    }

    await postRef.delete();
  }

  // ============================================================
  // COMMENTS
  // ============================================================

  /// Live stream of comments on a post, oldest first.
  Stream<List<CommunityComment>> streamComments(String postId) {
    return _commentsCollection(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(CommunityComment.fromFirestore).toList());
  }

  Future<void> addComment(String postId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be signed in to comment.');
    if (text.trim().isEmpty) return;

    final postRef = _postsCollection.doc(postId);
    final commentRef = _commentsCollection(postId).doc();

    // Two separate writes (not one cross-collection transaction requirement
    // from the rules' point of view, but we still use a transaction so the
    // replyCount bump is read-then-incremented atomically against races).
    await _firestore.runTransaction((transaction) async {
      final postSnap = await transaction.get(postRef);
      if (!postSnap.exists) throw Exception('This post no longer exists.');
      final currentReplyCount = (postSnap.data()?['replyCount'] ?? 0) as int;

      transaction.set(commentRef, {
        'uid': user.uid,
        'authorName': (user.displayName?.isNotEmpty ?? false) ? user.displayName : 'Farmer',
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(postRef, {'replyCount': currentReplyCount + 1});
    });
  }

  /// Deletes a single comment (only the comment's own author can) and
  /// decrements the parent post's replyCount by exactly 1, matching the
  /// security rule that only allows 'replyCount' to change by ±1.
  Future<void> deleteComment(String postId, String commentId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User must be signed in to delete a comment.');

    final commentRef = _commentsCollection(postId).doc(commentId);
    final postRef = _postsCollection.doc(postId);

    await _firestore.runTransaction((transaction) async {
      final commentSnap = await transaction.get(commentRef);
      if (!commentSnap.exists) return;
      final data = commentSnap.data() ?? {};
      if (data['uid'] != user.uid) {
        throw Exception('You can only delete your own comments.');
      }

      final postSnap = await transaction.get(postRef);
      final currentReplyCount = (postSnap.data()?['replyCount'] ?? 0) as int;

      transaction.delete(commentRef);
      if (postSnap.exists) {
        transaction.update(postRef, {'replyCount': currentReplyCount > 0 ? currentReplyCount - 1 : 0});
      }
    });
  }
}