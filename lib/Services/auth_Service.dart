import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:socialmediaapp/Screens/auth_Screen.dart';
import 'package:socialmediaapp/Screens/posts_Screen.dart';
import 'package:socialmediaapp/Services/firestore_Service.dart';

class AuthService {
  Future<bool?> userSignUp({
    required String userName,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        userCredential.user!.updateDisplayName(userName);
      }

      FirebaseAuth.instance.currentUser!.sendEmailVerification();

      await FirestoreService().addUser(
        userName: userName,
        email: email,
        uId: userCredential.user!.uid,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User registered successfully'),
          backgroundColor: Colors.green,
        ),
      );

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(' $e'), backgroundColor: Colors.red),
      );

      print("Error occurred while signing up: $e");
    }
  }

  Future<void> userLogin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login successfully'),
          backgroundColor: Colors.green,
        ),
      );

      if (context.mounted) {
        Navigator.pushAndRemoveUntil<void>(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const PostsScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: Colors.red),
      );
      print("Error occurred while logging in: $e");
    }
  }

  Future<void> userLogout({required BuildContext context}) async {
    try {
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout successfully'),
          backgroundColor: Colors.green,
        ),
      );

      if (context.mounted) {
        Navigator.pushAndRemoveUntil<void>(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const AuthScreen(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print("Error occurred while logging out: $e");
    }
  }
}