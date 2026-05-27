import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/ux/empty_state_view.dart';
import '../../../core/widgets/ux/gradient_fab.dart';
import '../../../core/widgets/ux/skeletons.dart';
import '../../../l10n/app_localizations.dart';
import '../data/challenge_repository.dart';
import '../domain/challenge_model.dart';
import '../domain/challenge_participant_model.dart';
import 'widgets/challenge_card.dart';
import 'widgets/create_challenge_sheet.dart';

// Pantalla con todos mis retos
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  late final ChallengeRepository _repo;
  late final String _uid;

  // cache de participantes partner
  final Map<String, ChallengeParticipantModel?> _partnerCache = {};

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
    _repo = ChallengeRepository(uid: _uid);
  }

  Future<ChallengeParticipantModel?> _getPartner(
      ChallengeModel challenge) async {
    final partnerUid = challenge.partnerUid(_uid);
    if (_partnerCache.containsKey(partnerUid)) {
      return _partnerCache[partnerUid];
    }
    final partner = await _repo.getParticipant(challenge.id, partnerUid);
    _partnerCache[partnerUid] = partner;
    return partner;
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.challengesTitle),
        centerTitle: true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: GradientFab(
          tooltip: s.challengesNew,
          onTap: () async {
            final created = await CreateChallengeSheet.show(context);
            if (created == true && mounted) setState(() {});
          },
        ),
      ),
      body: StreamBuilder<List<ChallengeModel>>(
        stream: _repo.watchMyChallenges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeleton();
          }

          final challenges = snapshot.data ?? [];
          if (challenges.isEmpty) {
            return EmptyStateView(
              icon: Icons.handshake_rounded,
              title: s.challengesEmptyTitle,
              subtitle: s.challengesEmptySubtitle,
            );
          }

          // separar por status
          final active =
              challenges.where((c) => c.status == ChallengeStatus.active).toList();
          final pending =
              challenges.where((c) => c.status == ChallengeStatus.pending).toList();
          final finished = challenges
              .where((c) =>
                  c.status == ChallengeStatus.completed ||
                  c.status == ChallengeStatus.declined ||
                  c.status == ChallengeStatus.abandoned)
              .toList();

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionHeader(title: s.challengesSectionPending, count: pending.length),
                ...pending.map((c) => _buildCard(c)),
              ],
              if (active.isNotEmpty) ...[
                _SectionHeader(title: s.challengesSectionActive, count: active.length),
                ...active.map((c) => _buildCard(c)),
              ],
              if (finished.isNotEmpty) ...[
                _SectionHeader(title: s.challengesSectionFinished, count: finished.length),
                ...finished.map((c) => _buildCard(c)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(ChallengeModel challenge) {
    return FutureBuilder<ChallengeParticipantModel?>(
      future: _getPartner(challenge),
      builder: (context, snap) {
        return ChallengeCard(
          challenge: challenge,
          partner: snap.data,
          myUid: _uid,
          onTap: () => context.push('/challenges/${challenge.id}'),
        );
      },
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: const HabitCardSkeleton(),
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
