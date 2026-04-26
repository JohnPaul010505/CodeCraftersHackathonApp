import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Central Firebase service.
/// All Firestore collection names live here — change once, applies everywhere.
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Collection references ────────────────────────────────────────────────
  CollectionReference get teachers => _db.collection('teachers');
  CollectionReference get rooms => _db.collection('rooms');
  CollectionReference get subjects => _db.collection('subjects');
  CollectionReference get schedules => _db.collection('schedules');
  CollectionReference get conflicts => _db.collection('conflicts');
  CollectionReference get chatMessages => _db.collection('chat_messages');

  // ── Auth ─────────────────────────────────────────────────────────────────

  /// Sign in with email + password (used for teacher accounts).
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _authError(e);
    }
  }

  /// Sign out the current user.
  Future<void> signOut() => _auth.signOut();

  User? get currentUser => _auth.currentUser;

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  // ── Generic Firestore helpers ─────────────────────────────────────────────

  /// Add a document and return its generated ID.
  Future<String> addDoc(CollectionReference col, Map<String, dynamic> data) async {
    final ref = await col.add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Set a document with a known ID (upsert).
  Future<void> setDoc(
    CollectionReference col,
    String id,
    Map<String, dynamic> data,
  ) async {
    await col.doc(id).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Update specific fields in a document.
  Future<void> updateDoc(
    CollectionReference col,
    String id,
    Map<String, dynamic> data,
  ) async {
    await col.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a document.
  Future<void> deleteDoc(CollectionReference col, String id) =>
      col.doc(id).delete();

  /// Fetch all documents in a collection once.
  Future<List<Map<String, dynamic>>> getAll(CollectionReference col) async {
    final snapshot = await col.get();
    return snapshot.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  /// Real-time stream of a collection.
  Stream<List<Map<String, dynamic>>> stream(CollectionReference col) {
    return col.snapshots().map((snapshot) => snapshot.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList());
  }

  // ── Room helpers ──────────────────────────────────────────────────────────

  Future<void> updateRoomStatus(
    String roomId,
    String status, {
    String? eventNote,
  }) =>
      updateDoc(rooms, roomId, {
        'status': status,
        if (eventNote != null) 'eventNote': eventNote,
      });

  // ── Schedule helpers ──────────────────────────────────────────────────────

  /// Fetch all schedules for a specific teacher.
  Future<List<Map<String, dynamic>>> getTeacherSchedule(
      String teacherId) async {
    final snapshot = await schedules
        .where('teacherId', isEqualTo: teacherId)
        .get();
    return snapshot.docs
        .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
        .toList();
  }

  // ── Chat helpers ──────────────────────────────────────────────────────────

  /// Stream pending (unresolved) chat messages.
  Stream<List<Map<String, dynamic>>> pendingMessages() {
    return chatMessages
        .where('isResolved', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
            .toList());
  }

  Future<void> resolveMessage(String messageId, String adminResponse) =>
      updateDoc(chatMessages, messageId, {
        'isResolved': true,
        'adminResponse': adminResponse,
      });
}
