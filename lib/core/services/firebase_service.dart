import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Auth Streams
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Authentication Methods
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print("Firebase Auth Error: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        // Initialize user document in Firestore
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
      return credential;
    } catch (e) {
      print("Firebase Auth Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Firestore Methods for Ayobami Data
  
  // Chat History
  Future<void> saveChatMessage(String userId, Map<String, dynamic> messageData) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_history')
        .add({
          ...messageData,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Stream<QuerySnapshot> getChatHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('chat_history')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Portfolio
  Future<void> updatePortfolio(String userId, List<Map<String, dynamic>> portfolioItems) async {
    await _firestore.collection('users').doc(userId).update({
      'portfolio': portfolioItems,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Settings Sync
  Future<void> syncSettings(String userId, Map<String, dynamic> settings) async {
    await _firestore.collection('users').doc(userId).update({
      'settings': settings,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Push Notifications
  Future<void> setupNotifications(String userId) async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
        });
      }
    }
  }
}
