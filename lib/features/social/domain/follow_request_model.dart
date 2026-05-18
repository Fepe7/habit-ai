import 'package:cloud_firestore/cloud_firestore.dart';

enum FollowRequestStatus { pending, accepted, declined }

extension FollowRequestStatusX on FollowRequestStatus {
  static FollowRequestStatus fromString(String? v) {
    switch (v) {
      case 'accepted':
        return FollowRequestStatus.accepted;
      case 'declined':
        return FollowRequestStatus.declined;
      default:
        return FollowRequestStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case FollowRequestStatus.pending:
        return 'pending';
      case FollowRequestStatus.accepted:
        return 'accepted';
      case FollowRequestStatus.declined:
        return 'declined';
    }
  }
}

/// Solicitud de seguimiento en /follow_requests/{requestId}.
/// Datos de ambos usuarios denormalizados para evitar lecturas extra en la UI.
class FollowRequestModel {
  final String id;
  final String fromUid;
  final String toUid;
  final FollowRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  final String fromUsername;
  final String fromDisplayName;
  final String? fromPhotoUrl;

  final String toUsername;
  final String toDisplayName;
  final String? toPhotoUrl;

  const FollowRequestModel({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.fromUsername,
    required this.fromDisplayName,
    this.fromPhotoUrl,
    required this.toUsername,
    required this.toDisplayName,
    this.toPhotoUrl,
  });

  factory FollowRequestModel.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return FollowRequestModel(
      id: id,
      fromUid: data['fromUid'] as String? ?? '',
      toUid: data['toUid'] as String? ?? '',
      status: FollowRequestStatusX.fromString(data['status'] as String?),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
      fromUsername: data['fromUsername'] as String? ?? '',
      fromDisplayName: data['fromDisplayName'] as String? ?? '',
      fromPhotoUrl: data['fromPhotoUrl'] as String?,
      toUsername: data['toUsername'] as String? ?? '',
      toDisplayName: data['toDisplayName'] as String? ?? '',
      toPhotoUrl: data['toPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'fromUid': fromUid,
        'toUid': toUid,
        'status': status.value,
        'createdAt': Timestamp.fromDate(createdAt),
        'respondedAt':
            respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
        'fromUsername': fromUsername,
        'fromDisplayName': fromDisplayName,
        'fromPhotoUrl': fromPhotoUrl,
        'toUsername': toUsername,
        'toDisplayName': toDisplayName,
        'toPhotoUrl': toPhotoUrl,
      };
}
