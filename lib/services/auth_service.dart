import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // null on web — web uses signInWithPopup instead
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(displayName);

    final userModel = UserModel(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(credential.user!.uid)
          .set(userModel.toFirestore())
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Firestore unavailable — user created in Auth, doc will sync later
    }

    return userModel;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserModel?> signInWithGoogle() async {
    UserCredential userCredential;

    if (kIsWeb) {
      // Web: از Firebase signInWithPopup استفاده کن — People API ناخوات
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      userCredential = await _auth.signInWithPopup(provider);
    } else {
      // Mobile: از google_sign_in پاکێج استفاده کن
      final googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCredential = await _auth.signInWithCredential(credential);
    }

    final firebaseUser = userCredential.user!;

    final existingDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(firebaseUser.uid)
        .get();

    if (!existingDoc.exists) {
      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'User',
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(userModel.toFirestore());
      return userModel;
    } else {
      return UserModel.fromFirestore(existingDoc);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn?.signOut();
  }

  Future<UserModel?> getUserModel(String uid) async {
    try {
      // Try server first, fall back to cache if offline
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (_) {
      // Offline — try local cache only
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      } catch (_) {
        return null;
      }
    }
  }

  Stream<UserModel?> streamUserModel(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromFirestore(doc) : null);
  }
}
