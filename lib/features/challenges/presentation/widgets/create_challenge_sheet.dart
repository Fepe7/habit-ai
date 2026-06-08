import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../levels/presentation/category_l10n.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../social/data/follow_repository.dart';
import '../../../social/data/user_directory_repository.dart';
import '../../../social/domain/privacy_level.dart';
import '../../../social/domain/user_directory_entry.dart';
import '../../../habits/data/habit_repository.dart';
import '../../../habits/domain/habit_model.dart';
import '../../data/challenge_repository.dart';
import '../../domain/challenge_participant_model.dart';

// Bottom sheet para crear un reto compartido
class CreateChallengeSheet extends StatefulWidget {
  const CreateChallengeSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showAppBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      builder: (_) => const CreateChallengeSheet(),
    );
  }

  @override
  State<CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<CreateChallengeSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  String _category = 'productividad';
  int _durationDays = 21;
  Timer? _debounce;

  // búsqueda de usuario (ahora usa UserDirectoryEntry para incluir privacidad)
  List<UserDirectoryEntry> _searchResults = [];
  UserDirectoryEntry? _selectedUser;
  bool _searching = false;
  bool _saving = false;
  Set<String> _myFollowerUids = {};

  late final UserDirectoryRepository _dirRepo;
  late final FollowRepository _followRepo;
  late final ChallengeRepository _challengeRepo;
  late final HabitRepository _habitRepo;
  late final String _myUid;

  static const _durations = [7, 14, 21, 30];

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser!.uid;
    _dirRepo = UserDirectoryRepository(uid: _myUid);
    _followRepo = FollowRepository(uid: _myUid);
    _challengeRepo = ChallengeRepository(uid: _myUid);
    _habitRepo = HabitRepository(uid: _myUid);
    _usernameCtrl.addListener(_onUsernameChanged);
    _loadFollowerUids();
  }

  Future<void> _loadFollowerUids() async {
    final uids = await _followRepo.getFollowerUids();
    if (mounted) setState(() => _myFollowerUids = uids.toSet());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    _debounce?.cancel();
    final query = _usernameCtrl.text.trim().toLowerCase();
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final all = await _dirRepo.searchByUsername(query);
      if (!mounted) return;
      // filtrar por privacidad: excluir los que no permiten retos del usuario actual
      final filtered = all.where((e) {
        if (e.uid == _myUid) return false;
        final cp = e.challengePrivacy.value;
        if (cp == 'nobody') return false;
        if (cp == 'followers') return _myFollowerUids.contains(e.uid);
        return true; // "everyone"
      }).take(5).toList();
      setState(() {
        _searchResults = filtered;
        _searching = false;
      });
    });
  }

  Future<void> _send() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _selectedUser == null) return;

    setState(() => _saving = true);

    try {
      final me = FirebaseAuth.instance.currentUser!;
      final myEntry = await _dirRepo.getEntry(_myUid);
      final desc = _descCtrl.text.trim();

      // crear el hábito del creador vinculado al reto
      // challengeId se actualizará justo después de crear el reto
      final tempHabitId = await _habitRepo.createHabit(
        HabitModel(
          id: '',
          title: title,
          description: desc,
          category: _category,
          frequency: 'daily',
          targetDays: [1, 2, 3, 4, 5, 6, 7],
          createdAt: DateTime.now(),
        ),
      );

      final creator = ChallengeParticipantModel(
        uid: _myUid,
        username: myEntry?.username ?? me.displayName ?? '',
        displayName: me.displayName ?? '',
        photoUrl: me.photoURL,
        habitId: tempHabitId,
        joinedAt: DateTime.now(),
      );

      final challengeId = await _challengeRepo.createChallenge(
        habitTitle: title,
        habitDescription: desc,
        habitCategory: _category,
        durationDays: _durationDays,
        invitedUid: _selectedUser!.uid,
        creatorParticipant: creator,
      );

      // vincular el hábito creado al reto
      await _habitRepo.updateHabit(tempHabitId, {'challengeId': challengeId});

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).createChallengeError('$e'))),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = S.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // barra indicadora
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              s.createChallengeTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 20),

            // título
            TextField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: s.createChallengeHabitName,
                hintText: s.createChallengeHabitHint,
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // descripción
            TextField(
              controller: _descCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: s.groupDetailPublishDescLabel,
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // categoría
            Text(s.habitFieldCategory,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppTheme.categories.map((cat) {
                final selected = cat == _category;
                return FilterChip(
                  label: Text(CategoryL10n.labelOf(cat, context)),
                  avatar: Icon(AppTheme.categoryIcon(cat), size: 16),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = cat),
                  backgroundColor: AppTheme.categoryBg(cat, scheme.brightness),
                  selectedColor: AppTheme.categoryBg(cat, scheme.brightness),
                  labelStyle: TextStyle(
                    color: AppTheme.categoryFg(cat, scheme.brightness),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: selected
                      ? BorderSide(color: AppTheme.categoryFg(cat, scheme.brightness), width: 1.5)
                      : BorderSide.none,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // duración
            Text(s.createChallengeDuration,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _durations.map((d) {
                final selected = d == _durationDays;
                return ChoiceChip(
                  label: Text(s.daysLabel(d)),
                  selected: selected,
                  onSelected: (_) => setState(() => _durationDays = d),
                  selectedColor: scheme.primaryContainer,
                  labelStyle: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? scheme.onPrimaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // buscar compañero
            Text(s.createChallengePartnerLabel,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),

            if (_selectedUser != null)
              _SelectedUserTile(
                entry: _selectedUser!,
                isFriend: _myFollowerUids.contains(_selectedUser!.uid),
                onRemove: () => setState(() => _selectedUser = null),
              )
            else ...[
              TextField(
                controller: _usernameCtrl,
                decoration: InputDecoration(
                  labelText: s.createChallengeSearchUsername,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor:
                      scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (_, i) {
                      final entry = _searchResults[i];
                      final isFriend = _myFollowerUids.contains(entry.uid);
                      return ListTile(
                        leading: AvatarCircle(
                          initials: entry.avatarInitials,
                          photoUrl: entry.photoUrl,
                          size: 36,
                        ),
                        title: Text(entry.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('@${entry.username}'),
                        trailing: isFriend
                            ? Chip(
                                label: Text(s.createChallengeFollowerChip),
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  color: scheme.primary,
                                ),
                                side: BorderSide.none,
                                backgroundColor: scheme.primaryContainer
                                    .withValues(alpha: 0.4),
                              )
                            : null,
                        dense: true,
                        onTap: () {
                          setState(() {
                            _selectedUser = entry;
                            _searchResults = [];
                            _usernameCtrl.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
            ],
            const SizedBox(height: 24),

            // botón enviar
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                onPressed: (_titleCtrl.text.trim().isNotEmpty &&
                        _selectedUser != null &&
                        !_saving)
                    ? _send
                    : null,
                label: s.createChallengeSend,
                loading: _saving,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SelectedUserTile extends StatelessWidget {
  final UserDirectoryEntry entry;
  final bool isFriend;
  final VoidCallback onRemove;

  const _SelectedUserTile({
    required this.entry,
    required this.isFriend,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          AvatarCircle(
            initials: entry.avatarInitials,
            photoUrl: entry.photoUrl,
            size: 36,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (isFriend) ...[
                      const SizedBox(width: 6),
                      Chip(
                        label: Text(S.of(context).createChallengeFollowerChip),
                        labelStyle: TextStyle(
                          fontSize: 10,
                          color: scheme.primary,
                        ),
                        side: BorderSide.none,
                        backgroundColor:
                            scheme.primaryContainer.withValues(alpha: 0.5),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
                Text('@${entry.username}',
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
