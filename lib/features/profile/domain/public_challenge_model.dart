/// Subconjunto público de un reto para el espejo en public_profiles/{uid}/challenges.
class PublicChallengeModel {
  final String challengeId;
  final String habitTitle;
  final String habitCategory;
  final int durationDays;
  final String status; // nombre del enum ChallengeStatus
  final String partnerUid;
  final String? partnerDisplayName;
  final String? partnerPhotoUrl;
  final int completedCount;
  final int currentStreak;
  final Map<int, String> days; // día -> DayStatus.name

  const PublicChallengeModel({
    required this.challengeId,
    required this.habitTitle,
    required this.habitCategory,
    required this.durationDays,
    required this.status,
    required this.partnerUid,
    this.partnerDisplayName,
    this.partnerPhotoUrl,
    required this.completedCount,
    required this.currentStreak,
    required this.days,
  });

  factory PublicChallengeModel.fromFirestore(
      Map<String, dynamic> data, String docId) {
    final rawDays = data['days'] as Map<String, dynamic>? ?? {};
    return PublicChallengeModel(
      challengeId: docId,
      habitTitle: data['habitTitle'] as String? ?? '',
      habitCategory: data['habitCategory'] as String? ?? 'productividad',
      durationDays: data['durationDays'] as int? ?? 21,
      status: data['status'] as String? ?? 'active',
      partnerUid: data['partnerUid'] as String? ?? '',
      partnerDisplayName: data['partnerDisplayName'] as String?,
      partnerPhotoUrl: data['partnerPhotoUrl'] as String?,
      completedCount: data['completedCount'] as int? ?? 0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      days: rawDays.map((k, v) => MapEntry(int.tryParse(k) ?? 0, v as String)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'habitTitle': habitTitle,
      'habitCategory': habitCategory,
      'durationDays': durationDays,
      'status': status,
      'partnerUid': partnerUid,
      'partnerDisplayName': partnerDisplayName,
      'partnerPhotoUrl': partnerPhotoUrl,
      'completedCount': completedCount,
      'currentStreak': currentStreak,
      'days': days.map((k, v) => MapEntry(k.toString(), v)),
    };
  }
}
