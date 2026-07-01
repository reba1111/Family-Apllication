import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────────
  // COUPLE CODE
  // ─────────────────────────────────────────────────────────────────

  /// Generate a random 6-digit code, store in couples/{coupleId},
  /// and write coupleId back to the user's profile.
  Future<String> generateCoupleCode(String userId) async {
    final code = _randomSixDigits();
    final coupleRef = _db.collection(AppConstants.couplesCollection).doc();

    await coupleRef.set({
      'code': code,
      'user1Id': userId,
      'user2Id': null,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final userRef = _db.collection(AppConstants.usersCollection).doc(userId);
    await userRef.set({
      'uid': userId,
      'coupleId': coupleRef.id,
    }, SetOptions(merge: true));

    return code;
  }

  /// Look up the code, link user2, update both users' profiles.
  Future<void> enterCoupleCode({
    required String code,
    required String user2Id,
  }) async {
    final query = await _db
        .collection(AppConstants.couplesCollection)
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('کۆدەکە هەڵەیە.');
    }

    final coupleDoc = query.docs.first;
    if (coupleDoc.data().containsKey('user2Id') && coupleDoc['user2Id'] != null) {
      throw Exception('ئەم کۆدە پێشتر بەکارهاتووە.');
    }

    final coupleId = coupleDoc.id;
    final user1Id = coupleDoc['user1Id'] as String;

    if (user1Id == user2Id) {
      throw Exception('ناتوانیت کۆدی خۆت داخڵ بکەیت!');
    }

    // Batch write for atomicity
    final batch = _db.batch();

    batch.update(coupleDoc.reference, {'user2Id': user2Id});

    batch.set(
      _db.collection(AppConstants.usersCollection).doc(user1Id),
      {'coupleId': coupleId, 'partnerId': user2Id},
      SetOptions(merge: true),
    );

    batch.set(
      _db.collection(AppConstants.usersCollection).doc(user2Id),
      {'coupleId': coupleId, 'partnerId': user1Id},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────────
  // USER
  // ─────────────────────────────────────────────────────────────────

  Future<UserModel?> getUser(String uid) async {
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();
    return doc.exists ? UserModel.fromFirestore(doc) : null;
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((d) => d.exists ? UserModel.fromFirestore(d) : null);
  }

  Future<void> updateLikesDislikes({
    required String uid,
    required Map<String, List<String>> likes,
    required Map<String, List<String>> dislikes,
  }) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update({
      'likes': likes,
      'dislikes': dislikes,
    });
  }

  Future<void> updateMood(String uid, String? mood) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update({
      'currentMood': mood,
      'moodUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLocation(String uid, double lat, double lng, String status) async {
    final now = Timestamp.now();
    final newEntry = {
      'lat': lat,
      'lng': lng,
      'status': status,
      'createdAt': now,
    };

    final userRef = _db.collection(AppConstants.usersCollection).doc(uid);

    // Read current history from user doc, prepend new entry, keep max 5
    final docSnap = await userRef.get();
    final data = docSnap.data() as Map<String, dynamic>? ?? {};
    final histRaw = data['locationHistory'];
    final List<Map<String, dynamic>> history = histRaw is List
        ? histRaw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];

    history.insert(0, newEntry);
    final trimmed = history.take(5).toList(); // keep only last 5

    await userRef.update({
      'lastLocationLat': lat,
      'lastLocationLng': lng,
      'locationStatus': status,
      'locationUpdatedAt': now,
      'locationHistory': trimmed,
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // LESSONS
  // ─────────────────────────────────────────────────────────────────

  CollectionReference _lessonsRef(String coupleId) => _db
      .collection(AppConstants.couplesCollection)
      .doc(coupleId)
      .collection(AppConstants.lessonsCollection);

  Stream<List<LessonModel>> streamLessons(String coupleId) {
    return _lessonsRef(coupleId)
        .orderBy('dateTime')
        .snapshots()
        .map((s) => s.docs.map((d) => LessonModel.fromFirestore(d)).toList());
  }

  Future<String> addLesson(String coupleId, LessonModel lesson) async {
    final ref = await _lessonsRef(coupleId).add(lesson.toFirestore());
    return ref.id;
  }

  Future<void> updateLesson(String coupleId, String lessonId, Map<String, dynamic> data) async {
    await _lessonsRef(coupleId).doc(lessonId).update(data);
  }

  Future<void> deleteLesson(String coupleId, String lessonId) async {
    await _lessonsRef(coupleId).doc(lessonId).delete();
  }

  // ─────────────────────────────────────────────────────────────────
  // TASKS
  // ─────────────────────────────────────────────────────────────────

  CollectionReference _tasksRef(String coupleId) => _db
      .collection(AppConstants.couplesCollection)
      .doc(coupleId)
      .collection(AppConstants.tasksCollection);

  Stream<List<TaskModel>> streamTasks(String coupleId) {
    return _tasksRef(coupleId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => TaskModel.fromFirestore(d)).toList());
  }

  Future<String> addTask(String coupleId, TaskModel task) async {
    final ref = await _tasksRef(coupleId).add(task.toFirestore());
    return ref.id;
  }

  Future<void> updateTask(String coupleId, String taskId, Map<String, dynamic> data) async {
    await _tasksRef(coupleId).doc(taskId).update(data);
  }

  Future<void> toggleTask(String coupleId, String taskId, bool isDone) async {
    await _tasksRef(coupleId).doc(taskId).update({'isDone': isDone});
  }

  Future<void> deleteTask(String coupleId, String taskId) async {
    await _tasksRef(coupleId).doc(taskId).delete();
  }

  // ─────────────────────────────────────────────────────────────────
  // QUIZ
  // ─────────────────────────────────────────────────────────────────

  CollectionReference _quizRef(String coupleId) => _db
      .collection(AppConstants.couplesCollection)
      .doc(coupleId)
      .collection(AppConstants.quizCollection);

  Stream<List<QuizModel>> streamQuiz(String coupleId) {
    return _quizRef(coupleId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => QuizModel.fromFirestore(d)).toList());
  }

  Future<void> addQuiz(String coupleId, QuizModel quiz) async {
    await _quizRef(coupleId).add(quiz.toFirestore());
  }

  Future<void> updateQuiz(String coupleId, String quizId, Map<String, dynamic> data) async {
    await _quizRef(coupleId).doc(quizId).update(data);
  }

  Future<void> answerQuiz({
    required String coupleId,
    required String quizId,
    required String answeredBy,
    required String userAnswer,
    required String correctAnswer,
  }) async {
    final isCorrect =
        userAnswer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
    await _quizRef(coupleId).doc(quizId).update({
      'answeredBy': answeredBy,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
    });
  }

  Future<void> deleteQuiz(String coupleId, String quizId) async {
    await _quizRef(coupleId).doc(quizId).delete();
  }

  // ─────────────────────────────────────────────────────────────────
  // FAMILY
  // ─────────────────────────────────────────────────────────────────

  CollectionReference _familyRef(String coupleId) => _db
      .collection(AppConstants.couplesCollection)
      .doc(coupleId)
      .collection(AppConstants.familyCollection);

  Stream<List<FamilyMember>> streamFamily(String coupleId) {
    return _familyRef(coupleId)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map((d) => FamilyMember.fromFirestore(d)).toList());
  }

  Future<void> addFamilyMember(String coupleId, FamilyMember member) async {
    await _familyRef(coupleId).add(member.toFirestore());
  }

  Future<void> updateFamilyMember(String coupleId, String memberId, Map<String, dynamic> data) async {
    await _familyRef(coupleId).doc(memberId).update(data);
  }

  Future<void> deleteFamilyMember(
      String coupleId, String memberId) async {
    await _familyRef(coupleId).doc(memberId).delete();
  }

  // ─────────────────────────────────────────────────────────────────
  // MEMORIES
  // ─────────────────────────────────────────────────────────────────

  CollectionReference _memoriesRef(String coupleId) => _db
      .collection(AppConstants.couplesCollection)
      .doc(coupleId)
      .collection('memories');

  Stream<List<MemoryModel>> streamMemories(String coupleId) {
    return _memoriesRef(coupleId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => MemoryModel.fromFirestore(d)).toList());
  }

  Future<void> addMemory(String coupleId, MemoryModel memory) async {
    await _memoriesRef(coupleId).add(memory.toFirestore());
  }

  Future<void> updateMemory(String coupleId, String memoryId, MemoryModel memory) async {
    await _memoriesRef(coupleId).doc(memoryId).update(memory.toFirestore());
  }

  Future<void> deleteMemory(String coupleId, String memoryId) async {
    await _memoriesRef(coupleId).doc(memoryId).delete();
  }

  // ─────────────────────────────────────────────────────────────────
  // NOTES (Secret Love Notes)
  // ─────────────────────────────────────────────────────────────────

  CollectionReference _notesRef(String coupleId) => _db
      .collection(AppConstants.couplesCollection)
      .doc(coupleId)
      .collection('notes');

  Stream<List<NoteModel>> streamNotes(String coupleId) {
    return _notesRef(coupleId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => NoteModel.fromFirestore(d)).toList());
  }

  Future<void> addNote(String coupleId, NoteModel note) async {
    await _notesRef(coupleId).add(note.toFirestore());
  }

  Future<void> updateNote(String coupleId, String noteId, NoteModel note) async {
    await _notesRef(coupleId).doc(noteId).update(note.toFirestore());
  }

  Future<void> deleteNote(String coupleId, String noteId) async {
    await _notesRef(coupleId).doc(noteId).delete();
  }

  Future<void> markNoteAsRead(String coupleId, String noteId) async {
    await _notesRef(coupleId).doc(noteId).update({'isRead': true});
  }

  // ─────────────────────────────────────────────────────────────────
  // GOALS (Shared Goals & Savings)
  // ─────────────────────────────────────────────────────────────────

  CollectionReference _goalsRef(String coupleId) => _db
      .collection(AppConstants.couplesCollection)
      .doc(coupleId)
      .collection('goals');

  Stream<List<GoalModel>> streamGoals(String coupleId) {
    return _goalsRef(coupleId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => GoalModel.fromFirestore(d)).toList());
  }

  Future<void> addGoal(String coupleId, GoalModel goal) async {
    await _goalsRef(coupleId).add(goal.toFirestore());
  }

  Future<void> updateGoal(String coupleId, String goalId, GoalModel goal) async {
    await _goalsRef(coupleId).doc(goalId).update(goal.toFirestore());
  }

  Future<void> deleteGoal(String coupleId, String goalId) async {
    await _goalsRef(coupleId).doc(goalId).delete();
  }

  Future<void> addFundsToGoal(String coupleId, String goalId, double amountToAdd, String userId) async {
    final batch = _db.batch();
    
    final goalRef = _goalsRef(coupleId).doc(goalId);
    batch.update(goalRef, {
      'currentAmount': FieldValue.increment(amountToAdd),
    });

    final txRef = goalRef.collection('transactions').doc();
    final transaction = GoalTransactionModel(
      id: txRef.id,
      amount: amountToAdd,
      userId: userId,
      createdAt: DateTime.now(),
    );
    batch.set(txRef, transaction.toFirestore());

    await batch.commit();
  }

  Stream<List<GoalTransactionModel>> streamGoalTransactions(String coupleId, String goalId) {
    return _goalsRef(coupleId)
        .doc(goalId)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => GoalTransactionModel.fromFirestore(d)).toList());
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────

  String _randomSixDigits() {
    final rng = Random.secure();
    return (rng.nextInt(900000) + 100000).toString();
  }

  String generateTestCode() => _randomSixDigits();
}
