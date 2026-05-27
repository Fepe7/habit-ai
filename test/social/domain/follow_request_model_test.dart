import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitai/features/social/domain/follow_request_model.dart';

void main() {
  final createdAt = DateTime(2026, 5, 20);
  final respondedAt = DateTime(2026, 5, 21);

  Map<String, dynamic> _fullData() => {
        'fromUid': 'u1',
        'toUid': 'u2',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(createdAt),
        'respondedAt': Timestamp.fromDate(respondedAt),
        'fromUsername': 'alice',
        'fromDisplayName': 'Alice W',
        'fromPhotoUrl': 'https://example.com/alice.jpg',
        'toUsername': 'bob',
        'toDisplayName': 'Bob M',
        'toPhotoUrl': 'https://example.com/bob.jpg',
      };

  group('FollowRequestStatus', () {
    test('fromString mapea valores', () {
      expect(FollowRequestStatusX.fromString('pending'), FollowRequestStatus.pending);
      expect(FollowRequestStatusX.fromString('accepted'), FollowRequestStatus.accepted);
      expect(FollowRequestStatusX.fromString('declined'), FollowRequestStatus.declined);
    });

    test('fromString default para desconocido', () {
      expect(FollowRequestStatusX.fromString(null), FollowRequestStatus.pending);
      expect(FollowRequestStatusX.fromString('xyz'), FollowRequestStatus.pending);
    });

    test('value devuelve string correcto', () {
      expect(FollowRequestStatus.pending.value, 'pending');
      expect(FollowRequestStatus.accepted.value, 'accepted');
      expect(FollowRequestStatus.declined.value, 'declined');
    });
  });

  group('FollowRequestModel.fromFirestore', () {
    test('parsea todos los campos', () {
      final r = FollowRequestModel.fromFirestore(_fullData(), 'req1');

      expect(r.id, 'req1');
      expect(r.fromUid, 'u1');
      expect(r.toUid, 'u2');
      expect(r.status, FollowRequestStatus.pending);
      expect(r.createdAt, createdAt);
      expect(r.respondedAt, respondedAt);
      expect(r.fromUsername, 'alice');
      expect(r.fromDisplayName, 'Alice W');
      expect(r.fromPhotoUrl, 'https://example.com/alice.jpg');
      expect(r.toUsername, 'bob');
      expect(r.toDisplayName, 'Bob M');
      expect(r.toPhotoUrl, 'https://example.com/bob.jpg');
    });

    test('defaults', () {
      final r = FollowRequestModel.fromFirestore({}, 'req2');

      expect(r.fromUid, '');
      expect(r.toUid, '');
      expect(r.status, FollowRequestStatus.pending);
      expect(r.respondedAt, isNull);
      expect(r.fromUsername, '');
      expect(r.fromDisplayName, '');
      expect(r.fromPhotoUrl, isNull);
      expect(r.toUsername, '');
      expect(r.toDisplayName, '');
      expect(r.toPhotoUrl, isNull);
    });
  });

  group('toJson roundtrip', () {
    test('preserva datos', () {
      final original = FollowRequestModel.fromFirestore(_fullData(), 'req1');
      final json = original.toJson();
      final restored = FollowRequestModel.fromFirestore(json, 'req1');

      expect(restored.fromUid, original.fromUid);
      expect(restored.toUid, original.toUid);
      expect(restored.status, original.status);
      expect(restored.createdAt, original.createdAt);
      expect(restored.respondedAt, original.respondedAt);
      expect(restored.fromUsername, original.fromUsername);
      expect(restored.toUsername, original.toUsername);
    });

    test('status se serializa como string', () {
      final r = FollowRequestModel(
        id: 'x', fromUid: 'u1', toUid: 'u2',
        status: FollowRequestStatus.accepted,
        createdAt: createdAt,
        fromUsername: '', fromDisplayName: '',
        toUsername: '', toDisplayName: '',
      );
      expect(r.toJson()['status'], 'accepted');
    });
  });
}
