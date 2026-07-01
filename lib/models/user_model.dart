import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? coupleId;
  final String? partnerId;
  final Map<String, List<String>> likes;
  final Map<String, List<String>> dislikes;
  final DateTime createdAt;
  final String? currentMood;
  final DateTime? moodUpdatedAt;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.coupleId,
    this.partnerId,
    this.likes = const {},
    this.dislikes = const {},
    required this.createdAt,
    this.currentMood,
    this.moodUpdatedAt,
  });

  static Map<String, List<String>> _parseCategorizedList(dynamic data) {
    if (data == null) return {};
    if (data is List) {
      // Legacy format fallback
      return {'گشتی': List<String>.from(data)};
    }
    if (data is Map) {
      return data.map((key, value) =>
          MapEntry(key.toString(), List<String>.from(value as List)));
    }
    return {};
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      coupleId: data['coupleId'],
      partnerId: data['partnerId'],
      likes: _parseCategorizedList(data['likes']),
      dislikes: _parseCategorizedList(data['dislikes']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentMood: data['currentMood'],
      moodUpdatedAt: (data['moodUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'coupleId': coupleId,
        'partnerId': partnerId,
        'likes': likes,
        'dislikes': dislikes,
        'createdAt': Timestamp.fromDate(createdAt),
        if (currentMood != null) 'currentMood': currentMood,
        if (moodUpdatedAt != null) 'moodUpdatedAt': Timestamp.fromDate(moodUpdatedAt!),
      };

  UserModel copyWith({
    String? displayName,
    String? coupleId,
    String? partnerId,
    Map<String, List<String>>? likes,
    Map<String, List<String>>? dislikes,
    String? currentMood,
    DateTime? moodUpdatedAt,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      coupleId: coupleId ?? this.coupleId,
      partnerId: partnerId ?? this.partnerId,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      createdAt: createdAt,
      currentMood: currentMood ?? this.currentMood,
      moodUpdatedAt: moodUpdatedAt ?? this.moodUpdatedAt,
    );
  }
}
