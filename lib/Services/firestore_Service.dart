import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  Future<void> addUser({
    required String userName,
    required String email,
    required String uId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').add({
        'userName': userName,
        'email': email,
        'uId': uId,
      });
    } catch (e) {
      print("Error occurred while adding user: $e");
    }
  }

  Future<void> addPost({
    required String content,
    required String authorName,
    required String uid,
  }) async {
    await FirebaseFirestore.instance.collection('posts').add({
      'content': content,
      'authorName': authorName,
      'uid': uid,
      "likes": [],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getPostsStream() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Future<void> deletePost({required String postId}) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
  }

  Future<void> updateLikes({
    required List<dynamic> newLikesList,
    required String postId,
  }) async {
    log(newLikesList.toString(), name: 'New Likes List');
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'likes': newLikesList,
    });
  }
}