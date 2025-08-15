import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:socialmediaapp/Services/auth_Service.dart';
import 'package:socialmediaapp/Services/firestore_Service.dart';
import 'package:socialmediaapp/Services/globals.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        backgroundColor: Colors.indigo,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FirebaseAuth.instance.currentUser?.displayName ?? 'No Name',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? 'No Email',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await AuthService().userLogout(context: context);
              },
            ),
          ],
        ),
      ),
      body: SizedBox(
        width: double.infinity,
        child: FirebaseAuth.instance.currentUser!.emailVerified == true
            ? verifiedUserView(context)
            : notVerifiedUserView(context),
      ),
    );
  }

  Column notVerifiedUserView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Your email ${FirebaseAuth.instance.currentUser!.email} is not verified, please check your email for verification.',
        ),

        ElevatedButton(
          onPressed: () async {
            await FirebaseAuth.instance.currentUser!.sendEmailVerification();
          },
          child: const Text('Resend verification email'),
        ),
         SizedBox(height: 20,),
        ElevatedButton(
          onPressed: () async {
            await AuthService().userLogout(context: context);
          },
          child: const Text('Logout'),
        ),
         SizedBox(height: 20,),
        ElevatedButton(
          onPressed: () async {
            await FirebaseAuth.instance.currentUser!.reload();
            setState(() {});
          },
          child: const Text('refresh status'),
        ),
      ],
    );
  }

  Column verifiedUserView(BuildContext context) {
    TextEditingController contentController = TextEditingController();
    // Dummy static posts data

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  FirebaseAuth.instance.currentUser?.displayName != null
                      ? FirebaseAuth.instance.currentUser!.displayName![0]
                            .toUpperCase()
                      : 'U',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  // onSubmitted: (value) {
                  //   // TODO: Add post logic
                  // },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: () async {
                  if (contentController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter some content'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await FirestoreService().addPost(
                    content: contentController.text,
                    authorName: FirebaseAuth.instance.currentUser!.displayName!,
                    uid: FirebaseAuth.instance.currentUser!.uid,
                  );
                  contentController.clear();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: FirestoreService().getPostsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No posts available'));
              } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                var posts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _postView(post, context);
                  },
                );
              } else {
                return SizedBox();
              }
            },
          ),
        ),
      ],
    );
  }

  Card _postView(QueryDocumentSnapshot post, BuildContext context) {
    // var likes = post['likes'] as CollectionReference<Map<String, dynamic>>?;

    // int likesCount = 0;
    // if (likes != null) {
    //   final snapshot = await likes.get();
    //   likesCount = snapshot.size;
    // }

    List<dynamic> currenLikes = (post['likes'] as List);

    bool alreadyLiked = currenLikes.any(
      (like) => like['uid'] == FirebaseAuth.instance.currentUser!.uid,
    );

    var userLike = currenLikes.firstWhere(
      (like) => like['uid'] == FirebaseAuth.instance.currentUser!.uid,
      orElse: () => null,
    );

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(post['authorName']![0].toUpperCase())),
                const SizedBox(width: 10),
                Text(
                  post['authorName'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Spacer(),

                if (FirebaseAuth.instance.currentUser!.uid == post['uid']) ...[
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () async {
                      showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Post'),
                          content: const Text(
                            'Are you sure you want to delete this post?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                FirestoreService().deletePost(postId: post.id);
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.green),
                    onPressed: () async {},
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            Text(post['content'] ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: alreadyLiked
                      ? Text(
                          getLikeType(userLike['type']),
                          style: const TextStyle(fontSize: 26),
                        )
                      : const Icon(
                          Icons.thumb_up_alt_outlined,
                          color: Colors.grey,
                        ),

                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: SizedBox(
                          height: 50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: likeTypes.map((type) {
                              return GestureDetector(
                                onTap: () {
                                  if (alreadyLiked) {
                                    userLike['type'] = type;

                                    currenLikes.removeWhere(
                                      (like) =>
                                          like['uid'] ==
                                          FirebaseAuth
                                              .instance
                                              .currentUser!
                                              .uid,
                                    );

                                    currenLikes.add(userLike);

                                    log(
                                      currenLikes.toString(),
                                      name: 'Current Likes when dislike',
                                    );
                                  } else {
                                    currenLikes.add({
                                      'uid': FirebaseAuth
                                          .instance
                                          .currentUser!
                                          .uid,
                                      'type': type,
                                    });

                                    log(
                                      currenLikes.toString(),
                                      name: 'Current Likes when like',
                                    );
                                  }

                                  FirestoreService().updateLikes(
                                    newLikesList: currenLikes,
                                    postId: post.id,
                                  );

                                  Navigator.pop(context);
                                },
                                child: Text(
                                  getLikeType(type),
                                  style: TextStyle(fontSize: 30),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                  onPressed: () {
                    if (alreadyLiked) {
                      currenLikes.removeWhere(
                        (like) =>
                            like['uid'] ==
                            FirebaseAuth.instance.currentUser!.uid,
                      );

                      log(
                        currenLikes.toString(),
                        name: 'Current Likes when dislike',
                      );
                    } else {
                      currenLikes.add({
                        'uid': FirebaseAuth.instance.currentUser!.uid,
                        'type': 'like',
                      });

                      log(
                        currenLikes.toString(),
                        name: 'Current Likes when like',
                      );
                    }

                    FirestoreService().updateLikes(
                      newLikesList: currenLikes,
                      postId: post.id,
                    );
                  },
                ),
                Text(
                  (post['likes'] as List).length.toString(),
                ), // Replace with like count
                // const SizedBox(width: 16),
                // IconButton(
                //   icon: const Icon(Icons.comment_outlined),
                //   color: Colors.grey,
                //   onPressed: () {},
                // ),
                // const Text('4'), // Replace with comment count
              ],
            ),
          ],
        ),
      ),
    );
  }
}