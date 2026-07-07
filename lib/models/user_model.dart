import 'package:cloud_firestore/cloud_firestore.dart';

/// A single location check-in stored inside the user document.
/// We keep at most 5 of these (no extra collection needed).
class LocationEntry {
  final double lat;
  final double lng;
  final String status;
  final DateTime createdAt;

  const LocationEntry({
    required this.lat,
    required this.lng,
    required this.status,
    required this.createdAt,
  });

  factory LocationEntry.fromMap(Map<String, dynamic> m) => LocationEntry(
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        status: m['status'] ?? '',
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? coupleId;
  final String? partnerId;
  final String? partnerNickname;
  final Map<String, List<String>> likes;
  final Map<String, List<String>> dislikes;
  final DateTime createdAt;
  final String? currentMood;
  final DateTime? moodUpdatedAt;
  final double? lastLocationLat;
  final double? lastLocationLng;
  final String? locationStatus;
  final DateTime? locationUpdatedAt;
  // Last 5 location entries stored inside the user document (no extra collection)
  final List<LocationEntry> locationHistory;
  final String? fcmToken;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.coupleId,
    this.partnerId,
    this.partnerNickname,
    this.likes = const {},
    this.dislikes = const {},
    required this.createdAt,
    this.currentMood,
    this.moodUpdatedAt,
    this.lastLocationLat,
    this.lastLocationLng,
    this.locationStatus,
    this.locationUpdatedAt,
    this.locationHistory = const [],
    this.fcmToken,
  });

  static Map<String, List<String>> _parseCategorizedList(dynamic data) {
    if (data == null) return {};
    if (data is List) {
      return {'گشتی': List<String>.from(data)};
    }
    if (data is Map) {
      return data.map((key, value) =>
          MapEntry(key.toString(), List<String>.from(value as List)));
    }
    return {};
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final histRaw = data['locationHistory'];
    final history = histRaw is List
        ? histRaw
            .whereType<Map>()
            .map((e) => LocationEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList()
        : <LocationEntry>[];

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      coupleId: data['coupleId'],
      partnerId: data['partnerId'],
      partnerNickname: data['partnerNickname'],
      likes: _parseCategorizedList(data['likes']),
      dislikes: _parseCategorizedList(data['dislikes']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentMood: data['currentMood'],
      moodUpdatedAt: (data['moodUpdatedAt'] as Timestamp?)?.toDate(),
      lastLocationLat: (data['lastLocationLat'] as num?)?.toDouble(),
      lastLocationLng: (data['lastLocationLng'] as num?)?.toDouble(),
      locationStatus: data['locationStatus'],
      locationUpdatedAt: (data['locationUpdatedAt'] as Timestamp?)?.toDate(),
      locationHistory: history,
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'coupleId': coupleId,
        'partnerId': partnerId,
        if (partnerNickname != null) 'partnerNickname': partnerNickname,
        'likes': likes,
        'dislikes': dislikes,
        'createdAt': Timestamp.fromDate(createdAt),
        if (currentMood != null) 'currentMood': currentMood,
        if (moodUpdatedAt != null) 'moodUpdatedAt': Timestamp.fromDate(moodUpdatedAt!),
        if (lastLocationLat != null) 'lastLocationLat': lastLocationLat,
        if (lastLocationLng != null) 'lastLocationLng': lastLocationLng,
        if (locationStatus != null) 'locationStatus': locationStatus,
        if (locationUpdatedAt != null) 'locationUpdatedAt': Timestamp.fromDate(locationUpdatedAt!),
        'locationHistory': locationHistory.map((e) => e.toMap()).toList(),
        if (fcmToken != null) 'fcmToken': fcmToken,
      };

  UserModel copyWith({
    String? displayName,
    String? coupleId,
    String? partnerId,
    String? partnerNickname,
    Map<String, List<String>>? likes,
    Map<String, List<String>>? dislikes,
    String? currentMood,
    DateTime? moodUpdatedAt,
    List<LocationEntry>? locationHistory,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      coupleId: coupleId ?? this.coupleId,
      partnerId: partnerId ?? this.partnerId,
      partnerNickname: partnerNickname ?? this.partnerNickname,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      createdAt: createdAt,
      currentMood: currentMood ?? this.currentMood,
      moodUpdatedAt: moodUpdatedAt ?? this.moodUpdatedAt,
      locationHistory: locationHistory ?? this.locationHistory,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}

