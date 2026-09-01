import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../firebase/firebase_bootstrap.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/mock_profile_provider.dart';
import '../domain/pvp_models.dart';
import '../providers/pvp_providers.dart';

/// Live 1v1 challenge lobby. Both players must be online — no async mailbox.
class PvpLobbyScreen extends ConsumerStatefulWidget {
  const PvpLobbyScreen({super.key});

  @override
  ConsumerState<PvpLobbyScreen> createState() => _PvpLobbyScreenState();
}

class _PvpLobbyScreenState extends ConsumerState<PvpLobbyScreen> {
  final _joinCode = TextEditingController();
  PvpChallenge? _open;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _joinCode.dispose();
    super.dispose();
  }

  String? get _uid =>
      ref.read(authIdentityProvider).asData?.value?.uid ??
      (FirebaseBootstrap.isReady ? null : 'local_guest');

  Future<void> _create() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _error = 'Sign in as guest first (Firebase emulators).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await ref.read(pvpRepositoryProvider).createChallenge(
            challengerUid: uid,
            loadout: frozenLoadoutFromProfile(ref.read(profileProvider)),
          );
      if (!mounted) return;
      setState(() => _open = challenge);
      _watchChallenge(challenge.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _watchChallenge(String id) {
    ref.read(pvpRepositoryProvider).watchChallenge(id).listen((challenge) {
      if (!mounted || challenge == null) return;
      setState(() => _open = challenge);
      if (challenge.status == PvpChallengeStatus.accepted &&
          challenge.matchId != null) {
        context.push('/pvp/${challenge.matchId}');
      }
    });
  }

  Future<void> _join() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _error = 'Sign in as guest first (Firebase emulators).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final match = await ref.read(pvpRepositoryProvider).acceptChallenge(
            joinCode: _joinCode.text.trim().toUpperCase(),
            inviteeUid: uid,
            loadout: frozenLoadoutFromProfile(ref.read(profileProvider)),
          );
      if (!mounted) return;
      context.push('/pvp/${match.id}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MythDuskColors.ink,
      appBar: AppBar(
        title: const Text('Live 1v1'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'Challenge a player who is online now. Hero vs hero, same battle '
            'screen. Invites last ${pvpInviteTtl.inSeconds} seconds. '
            'No offline / correspondence matches.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (!FirebaseBootstrap.isReady)
            Text(
              'Firebase emulators are off — this device uses an in-memory '
              'match. Start emulators with FLAVOR=dev for two-device play.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MythDuskColors.amber,
                  ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _create,
            child: const Text('Create challenge'),
          ),
          if (_open != null) ...[
            const SizedBox(height: 12),
            SelectableText(
              'Code: ${_open!.joinCode}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              'Waiting for opponent · expires ${_open!.expiresAt.toLocal()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _open!.joinCode));
              },
              child: const Text('Copy code'),
            ),
          ],
          const Divider(height: 32, color: MythDuskColors.mist),
          TextField(
            controller: _joinCode,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Join code',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : _join,
            child: const Text('Join live challenge'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFE07A5F))),
          ],
        ],
      ),
    );
  }
}
