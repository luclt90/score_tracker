import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:score_tracker/l10n/app_localizations.dart';
import 'package:score_tracker/models/game.dart';
import 'package:score_tracker/models/game_state_model.dart';
import 'package:score_tracker/models/player.dart';
import 'package:score_tracker/models/player_state_model.dart';
import 'package:score_tracker/navigation.dart';
import 'package:score_tracker/screens/add_player.dart';
import 'package:score_tracker/screens/game_board.dart';
import 'package:score_tracker/services/iap_service.dart';
import 'package:score_tracker/widgets/add_players_widget.dart';

import '../ad_manager.dart';
import '../styles.dart';

class SelectPlayer extends StatefulWidget {
  const SelectPlayer({super.key});

  @override
  State<SelectPlayer> createState() => _SelectPlayerState();
}

class _SelectPlayerState extends State<SelectPlayer> {
  final List<Player> _selectedPlayers = [];
  BannerAd? _bannerAd;
  bool _isLoading = true;
  bool _isStarting = false;
  bool _hasPlayers = false;
  bool _bannerRequested = false;
  late final IAPService _iapService;

  @override
  void initState() {
    super.initState();
    _iapService = context.read<IAPService>()..addListener(_onIAPChanged);
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    await context.read<PlayerStateModel>().loadPlayers();
    if (!mounted) return;
    final hasPlayers = context.read<PlayerStateModel>().countPlayer() > 0;
    _hasPlayers = hasPlayers;
    if (hasPlayers &&
        _iapService.isEntitlementResolved &&
        !_iapService.isPurchased) {
      _loadBanner();
    }
    setState(() => _isLoading = false);
  }

  void _loadBanner() {
    if (_bannerRequested ||
        !_hasPlayers ||
        !_iapService.isEntitlementResolved ||
        _iapService.isPurchased) {
      return;
    }
    _bannerRequested = true;
    BannerAd(
      adUnitId: kReleaseMode
          ? AdManager.bannerAdUnitSelectPlayerId
          : AdManager.bannerAdUnitIdTest,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || _iapService.isPurchased) {
            ad.dispose();
            return;
          }
          setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          log('Failed to load select-player banner: ${error.message}');
          ad.dispose();
        },
      ),
    ).load();
  }

  void _onIAPChanged() {
    if (_iapService.isPurchased) {
      _bannerAd?.dispose();
      _bannerAd = null;
      if (mounted) setState(() {});
    } else if (_iapService.isEntitlementResolved && _hasPlayers) {
      _loadBanner();
    }
  }

  void _togglePlayer(Player player) {
    setState(() {
      if (_selectedPlayers.contains(player)) {
        _selectedPlayers.remove(player);
      } else if (_selectedPlayers.length < 6) {
        _selectedPlayers.add(player);
      }
    });
  }

  Future<bool> _confirmDelete(Player player) async {
    final t = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: backgroundHeaderColor,
            title: Text(
              t.delete,
              style: const TextStyle(
                color: foregroundButtonColor,
                fontFamily: fontFamilySFProText,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Text(
              t.delete_confirm,
              style: const TextStyle(
                color: foregroundColor,
                fontFamily: fontFamilySFProText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(t.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: Text(t.delete),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _startGame() async {
    if (_selectedPlayers.length < 2 || _isStarting) return;
    setState(() => _isStarting = true);
    try {
      final now = DateFormat('yyyy-MM-dd H:m').format(DateTime.now());
      final model = context.read<GameStateModel>();
      final ids = _selectedPlayers.map((player) => player.id!).toList();
      final gameId = await model.addGame(
        Game(numberOfPlayers: _selectedPlayers.length, createAt: now),
        ids,
      );
      final game = await model.getGameWithId(gameId);
      if (!mounted || game == null) return;
      Navigator.pushReplacement(
        context,
        smoothPageRoute(GameBoard(game: game, playerIds: ids)),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  void dispose() {
    _iapService.removeListener(_onIAPChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final players = context.watch<PlayerStateModel>().players;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          t.select_player_title,
          style: const TextStyle(
            color: foregroundButtonColor,
            fontFamily: fontFamilySFProText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: t.add_player,
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: foregroundButtonColor,
            ),
            onPressed: () =>
                Navigator.push(context, smoothPageRoute(AddPlayer())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: backgroundButtonColorBlue,
              ),
            )
          : players.isEmpty
          ? const AddPlayersWidget()
          : RefreshIndicator(
              color: backgroundButtonColorBlue,
              onRefresh: _loadPlayers,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _SelectionHeader(
                      selectedPlayers: _selectedPlayers,
                      hint: t.select_2to6player,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 160),
                    sliver: SliverList.separated(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        final selected = _selectedPlayers.contains(player);
                        final unavailable =
                            !selected && _selectedPlayers.length == 6;
                        return Dismissible(
                          key: ValueKey(player.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDelete(player),
                          onDismissed: (_) {
                            _selectedPlayers.remove(player);
                            context.read<PlayerStateModel>().deletePlayer(
                              player.id!,
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: foregroundButtonColor,
                            ),
                          ),
                          child: _PlayerTile(
                            player: player,
                            selected: selected,
                            unavailable: unavailable,
                            onTap: () => _togglePlayer(player),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: players.isEmpty || _isLoading
          ? null
          : _StartPanel(
              isReady: _selectedPlayers.length >= 2,
              isStarting: _isStarting,
              label: t.let_start,
              onStart: _startGame,
              bannerAd: _bannerAd,
            ),
    );
  }
}

class _SelectionHeader extends StatelessWidget {
  const _SelectionHeader({required this.selectedPlayers, required this.hint});
  final List<Player> selectedPlayers;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final names = selectedPlayers.map((player) => player.name).join(' • ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundHeaderColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundButtonColorBlue.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: backgroundButtonColorBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                names.isEmpty ? hint : names,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: foregroundButtonColor,
                  fontFamily: fontFamilySFProText,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${selectedPlayers.length}/6',
              style: const TextStyle(
                color: backgroundButtonColorBlue,
                fontFamily: fontFamilySFProText,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.player,
    required this.selected,
    required this.unavailable,
    required this.onTap,
  });
  final Player player;
  final bool selected;
  final bool unavailable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = player.name.trim().isEmpty
        ? '?'
        : player.name.trim()[0].toUpperCase();
    return Material(
      color: selected
          ? backgroundButtonColorBlue.withValues(alpha: .18)
          : backgroundHeaderColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: unavailable ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: unavailable ? .45 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: selected
                      ? backgroundButtonColorBlue
                      : foregroundHintColor,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: foregroundButtonColor,
                      fontFamily: fontFamilySFProText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    player.name,
                    style: const TextStyle(
                      color: foregroundButtonColor,
                      fontFamily: fontFamilySFProText,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected
                        ? backgroundButtonColorBlue
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? backgroundButtonColorBlue
                          : foregroundHintColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: foregroundButtonColor,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartPanel extends StatelessWidget {
  const _StartPanel({
    required this.isReady,
    required this.isStarting,
    required this.label,
    required this.onStart,
    required this.bannerAd,
  });
  final bool isReady;
  final bool isStarting;
  final String label;
  final VoidCallback onStart;
  final BannerAd? bannerAd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: isReady && !isStarting ? onStart : null,
                style: FilledButton.styleFrom(
                  backgroundColor: backgroundButtonColorBlue,
                  disabledBackgroundColor: backgroundHeaderColor,
                  foregroundColor: foregroundButtonColor,
                  disabledForegroundColor: foregroundHintColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: isStarting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foregroundButtonColor,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: fontFamilySFProText,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            if (bannerAd != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: AdSize.banner.height.toDouble(),
                child: Center(
                  child: SizedBox(
                    width: bannerAd!.size.width.toDouble(),
                    height: bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: bannerAd!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
