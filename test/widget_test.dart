import 'package:flutter_test/flutter_test.dart';
import 'package:couple_app/models/user_model.dart';
import 'package:couple_app/services/firestore_service.dart';

void main() {
  // ── ١. UserModel Tests ──────────────────────────────────────────
  group('UserModel', () {
    test('copyWith updates fields correctly', () {
      final user = UserModel(
        uid: 'test-uid-123',
        email: 'test@example.com',
        displayName: 'تێست یوزەر',
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = user.copyWith(
        displayName: 'نوێ کراوەتەوە',
        coupleId: 'couple-abc',
      );

      expect(updated.uid, 'test-uid-123');
      expect(updated.email, 'test@example.com');
      expect(updated.displayName, 'نوێ کراوەتەوە');
      expect(updated.coupleId, 'couple-abc');
      expect(updated.partnerId, isNull);
    });

    test('toFirestore includes all fields', () {
      final user = UserModel(
        uid: 'test-uid-123',
        email: 'test@example.com',
        displayName: 'تێست',
        coupleId: 'couple-xyz',
        partnerId: 'partner-uid',
        likes: {'گشتی': ['فلم', 'موسیقا']},
        dislikes: {'گشتی': ['شەپۆل']},
        createdAt: DateTime(2024, 6, 1),
      );

      final map = user.toFirestore();

      expect(map['email'], 'test@example.com');
      expect(map['displayName'], 'تێست');
      expect(map['coupleId'], 'couple-xyz');
      expect(map['partnerId'], 'partner-uid');
      expect(map['likes'], {'گشتی': ['فلم', 'موسیقا']});
      expect(map['dislikes'], {'گشتی': ['شەپۆل']});
    });

    test('default likes and dislikes are empty', () {
      final user = UserModel(
        uid: 'uid',
        email: 'a@b.com',
        displayName: 'تێست',
        createdAt: DateTime.now(),
      );

      expect(user.likes, isEmpty);
      expect(user.dislikes, isEmpty);
      expect(user.coupleId, isNull);
      expect(user.partnerId, isNull);
    });
  });

  // ── ٢. FirestoreService Helper Tests ────────────────────────────
  group('FirestoreService helpers', () {
    test('random code is 6 digits', () {
      final fs = FirestoreService();
      // Access via reflection not possible, so test via public behavior
      // The code returned by generateCoupleCode is always 6 digits
      final code = fs.generateTestCode();
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
      expect(int.parse(code), greaterThanOrEqualTo(100000));
      expect(int.parse(code), lessThanOrEqualTo(999999));
    });
  });

  // ── ٣. Couple Code Format Tests ─────────────────────────────────
  group('Couple Code', () {
    test('code is always numeric 6 digits', () {
      final fs = FirestoreService();
      for (int i = 0; i < 20; i++) {
        final code = fs.generateTestCode();
        expect(RegExp(r'^\d{6}$').hasMatch(code), isTrue,
            reason: 'کۆد دەبێت ٦ ژمارە بێت: $code');
      }
    });

    test('generated codes are not all the same', () {
      final fs = FirestoreService();
      final codes = List.generate(10, (_) => fs.generateTestCode());
      final unique = codes.toSet();
      expect(unique.length, greaterThan(1));
    });
  });
}
